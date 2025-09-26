# Multi-Version Support Guide

This document explains how to work with both Suricata 7.x (stable/default) and 8.x (latest) versions in this project.

## Overview

The Suricata container project supports two major versions using a branching strategy:

- **Suricata 7.x** (main branch) - Stable version, default build, compatible with Alpine 3.19+ and Rust 1.70.0+
- **Suricata 8.x** (suricata-8.x branch) - Latest features, requires Alpine 3.20+ and Rust 1.78.0+

## Branch Structure

```
Repository Structure:
├── main branch (Suricata 7.x - DEFAULT)
│   ├── Default: Suricata 7.0.11, Alpine 3.19, Rust 1.70.0, Python 3.11
│   └── Tags: v7.0.11, v7.0.12, v7.0.13...
├── suricata-8.x branch (Suricata 8.x - LATEST)
│   ├── Default: Suricata 8.0.0, Alpine 3.20, Rust 1.78.0, Python 3.12
│   └── Tags: v8.0.0, v8.0.1, v8.0.2...
└── suricata-7.x branch (Suricata 7.x - LEGACY)
    ├── Same as main branch
    └── Maintained for backward compatibility
```

## Quick Start

### Building Suricata 7.x (Default/Stable)
```bash
# Switch to main branch (default)
git checkout main

# Build with defaults (Suricata 7.0.11)
make build

# Test the build
make test

# Build specific 7.x version
SURICATA_VERSION=7.0.10 make build
```

### Building Suricata 8.x (Latest Features)
```bash
# Switch to 8.x branch
git checkout suricata-8.x

# Build with defaults (Suricata 8.0.0)
make build

# Test the build
make test

# Build specific 8.x version
SURICATA_VERSION=8.0.1 make build
```

## Docker Hub Tags

### Current Tagging Strategy

| Tag | Description | Branch | Version | Usage |
|-----|-------------|--------|---------|-------|
| `latest` | Latest stable 7.x | main | 7.0.11 | Production (stable) |
| `7`, `7.0.11` | Suricata 7.x versions | main | 7.0.11 | Production (7.x family) |
| `8-latest` | Latest 8.x | suricata-8.x | 8.0.0 | Production (latest features) |
| `8`, `8.0.0` | Suricata 8.x versions | suricata-8.x | 8.0.0 | Production (8.x family) |
| `7-latest` | Legacy 7.x tag | suricata-7.x | 7.0.11 | Legacy compatibility |

### Published Images

Successfully built images are available at:
- **Latest Stable**: `cmcconnell1/suricata:latest` (7.x)
- **Latest Features**: `cmcconnell1/suricata:8-latest` (8.x)
- **Specific Versions**: `cmcconnell1/suricata:7.0.11`, `cmcconnell1/suricata:8.0.0`
- **Commit-based**: `cmcconnell1/suricata:<commit-hash>`

## Version Compatibility Matrix

| Suricata Version | Alpine Version | Rust Version | Python Version | Status | Branch |
|------------------|----------------|--------------|----------------|--------|--------|
| 7.0.x | 3.19+ | 1.70.0+ | 3.11+ | Stable (Default) | main |
| 8.0.x | 3.20+ | 1.78.0+ | 3.12+ | Latest | suricata-8.x |
| 6.0.x | 3.16+ | 1.60.0+ | 3.10+ | Legacy | Not supported |

## Development Workflow

### Working on Both Versions

1. **Make changes to main branch first** (Suricata 7.x)
2. **Test thoroughly**
3. **Apply changes to suricata-8.x** if applicable
4. **Test both versions**

### Example Workflow
```bash
# Work on main branch (7.x)
git checkout main
# Make changes...
git add .
git commit -m "Add new feature"

# Apply to 8.x branch if compatible
git checkout suricata-8.x
git cherry-pick <commit-hash>

# Test both versions
git checkout main && make build && make test
git checkout suricata-8.x && make build && make test
```

### Branch-Specific Changes

Some changes may only apply to one version:

- **7.x only**: Stability fixes, compatibility with older dependencies
- **8.x only**: New features requiring latest Rust/Alpine
- **Both**: Bug fixes, documentation, scripts

**Note**: The Dockerfile uses dynamic version variables to ensure consistency:
- `--with-revision="${SURICATA_VERSION}-release"` automatically matches the build version
- This prevents version mismatches between branches

## CI/CD Pipeline

The CircleCI pipeline automatically builds both versions:

### Repository Configuration
- **Primary Repository**: GitHub (https://github.com/cmcconnell1/suricata-container)
- **CI/CD**: CircleCI with GitHub integration
- **Docker Registry**: Automated publishing to `cmcconnell1/suricata`

### Triggers
- **main branch** → Builds and deploys Suricata 7.x (tags: `latest`, `7`, `7.0.11`)
- **suricata-8.x branch** → Builds and deploys Suricata 8.x (tags: `8-latest`, `8`, `8.0.0`)
- **suricata-7.x branch** → Builds and deploys Suricata 7.x (tags: `7-latest`)

### Workflow Names
- `build_scan_deploy_7x` - For main branch (default)
- `build_scan_deploy_8x` - For suricata-8.x branch
- `build_scan_deploy_7x_legacy` - For suricata-7.x branch

## Version Override Examples

### Environment Variables
```bash
# Build 8.x on main branch
SURICATA_VERSION=8.0.0 ALPINE_VERSION=3.20 make build

# Build 7.x on 8.x branch
SURICATA_VERSION=7.0.11 ALPINE_VERSION=3.19 make build
```

### Docker Build Arguments
```bash
# Build 8.x with specific versions
docker build --build-arg SURICATA_VERSION=8.0.0 \
             --build-arg ALPINE_VERSION=3.20 \
             --build-arg RUST_VERSION=1.78.0 \
             --build-arg PYTHON_VERSION=3.12 \
             -f docker/Dockerfile -t suricata:8.0.0 .

# Build 7.x with specific versions
docker build --build-arg SURICATA_VERSION=7.0.11 \
             --build-arg ALPINE_VERSION=3.19 \
             --build-arg RUST_VERSION=1.70.0 \
             --build-arg PYTHON_VERSION=3.11 \
             -f docker/Dockerfile -t suricata:7.0.11 .
```

## Docker Usage Examples

### Pull and Run Commands

```bash
# Stable 7.x (default)
docker pull cmcconnell1/suricata:latest
docker run -d --name suricata-stable \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  cmcconnell1/suricata:latest

# Latest 8.x features
docker pull cmcconnell1/suricata:8-latest
docker run -d --name suricata-latest \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  cmcconnell1/suricata:8-latest

# Specific versions
docker pull cmcconnell1/suricata:7.0.11
docker pull cmcconnell1/suricata:8.0.0
```

## Maintenance Guidelines

### Version Updates

#### Updating Suricata 7.x (Main Branch)
```bash
git checkout main
# Update defaults in Makefile and Dockerfile
sed -i 's/SURICATA_VERSION ?= 7.0.11/SURICATA_VERSION ?= 7.0.12/' Makefile
sed -i 's/ARG SURICATA_VERSION=7.0.11/ARG SURICATA_VERSION=7.0.12/' docker/Dockerfile
git commit -am "Update Suricata to 7.0.12"
git tag v7.0.12
```

#### Updating Suricata 8.x
```bash
git checkout suricata-8.x
# Update defaults in Makefile and Dockerfile
sed -i 's/SURICATA_VERSION ?= 8.0.0/SURICATA_VERSION ?= 8.0.1/' Makefile
sed -i 's/ARG SURICATA_VERSION=8.0.0/ARG SURICATA_VERSION=8.0.1/' docker/Dockerfile
git commit -am "Update Suricata to 8.0.1"
git tag v8.0.1
```

## Best Practices

1. **Use main branch for stable deployments** (7.x)
2. **Use suricata-8.x branch for latest features** (8.x)
3. **Test both versions when making changes**
4. **Keep documentation updated for both versions**
5. **Tag releases properly with version-specific tags**
6. **Monitor compatibility between versions**
7. **Use environment variables for version overrides when needed**

## Migration Guide

### From Single Version to Multi-Version

If you were using the old single-version approach:

```bash
# Old way (was 8.x default)
make build

# New way - 7.x is now default
git checkout main        # For 7.x (stable)
make build

git checkout suricata-8.x  # For 8.x (latest)
make build
```

### Docker Pull Commands

```bash
# Suricata 7.x (stable/default)
docker pull cmcconnell1/suricata:latest
docker pull cmcconnell1/suricata:7
docker pull cmcconnell1/suricata:7.0.11

# Suricata 8.x (latest features)
docker pull cmcconnell1/suricata:8-latest
docker pull cmcconnell1/suricata:8
docker pull cmcconnell1/suricata:8.0.0
```

## Troubleshooting

### Common Issues

#### Build Fails on Wrong Alpine Version
```bash
# Error: Rust version incompatible
# Solution: Use correct Alpine version for each branch
git checkout main         # Uses Alpine 3.19 (7.x)
git checkout suricata-8.x # Uses Alpine 3.20 (8.x)
```

#### Wrong Version Built
```bash
# Check current branch
git branch --show-current

# Verify version defaults
make help
```

#### Docker Tag Conflicts
```bash
# Clean up old images
make clean

# Rebuild with correct defaults
make build
```

### Getting Help

1. Check current configuration: `make help`
2. Verify branch: `git branch --show-current`
3. Test build: `make build && make test`
4. Check documentation: `docs/MULTI-VERSION.md`

This multi-version approach provides stability with 7.x as the default while keeping cutting-edge 8.x features easily accessible.
