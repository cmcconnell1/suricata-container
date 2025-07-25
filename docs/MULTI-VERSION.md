# Multi-Version Support Guide

This document explains how to work with both Suricata 8.x and 7.x versions in this project.

## Overview

The Suricata container project supports two major versions using a branching strategy:

- **Suricata 8.x** (main branch) - Latest features, requires Alpine 3.20+ and Rust 1.78.0+
- **Suricata 7.x** (suricata-7.x branch) - Stable version, compatible with Alpine 3.19+ and Rust 1.70.0+

## Branch Structure

```
Repository Structure:
├── main branch (Suricata 8.x)
│   ├── Default: Suricata 8.0.0, Alpine 3.20, Rust 1.78.0
│   └── Tags: v8.0.0, v8.0.1, v8.0.2...
└── suricata-7.x branch (Suricata 7.x)
    ├── Default: Suricata 7.0.11, Alpine 3.19, Rust 1.70.0
    └── Tags: v7.0.11, v7.0.12, v7.0.13...
```

## Quick Start

### Building Suricata 8.x
```bash
# Switch to main branch
git checkout main

# Build with defaults (Suricata 8.0.0)
make build

# Test the build
make test

# Build specific 8.x version
SURICATA_VERSION=8.0.0 make build
```

### Building Suricata 7.x
```bash
# Switch to 7.x branch
git checkout suricata-7.x

# Build with defaults (Suricata 7.0.11)
make build

# Test the build
make test

# Build specific 7.x version
SURICATA_VERSION=7.0.10 make build
```

## Multi-Version Build Script

The `scripts/build-versions.sh` script simplifies building both versions:

### Basic Usage
```bash
# Build both versions
./scripts/build-versions.sh --version both

# Build and test both versions
./scripts/build-versions.sh --version both --test

# Build only Suricata 7.x
./scripts/build-versions.sh --version 7 --test

# Build Suricata 8.x and tag as latest
./scripts/build-versions.sh --version 8 --tag-latest
```

### Advanced Usage
```bash
# Build, test, and push both versions
./scripts/build-versions.sh --version both --test --push

# Build 8.x, tag as latest, and push
./scripts/build-versions.sh --version 8 --tag-latest --test --push

# Set custom Docker username
DOCKER_USERNAME=myusername ./scripts/build-versions.sh --version both --push
```

## Docker Hub Tagging Strategy

### Suricata 8.x Tags (from main branch)
- `latest` - Always points to latest 8.x
- `8` - Latest 8.x version
- `8.0.0` - Specific version
- `<commit-hash>` - Specific commit

### Suricata 7.x Tags (from suricata-7.x branch)
- `7-latest` - Always points to latest 7.x
- `7` - Latest 7.x version
- `7.0.11` - Specific version
- `<commit-hash>` - Specific commit

## Version Compatibility Matrix

| Suricata Version | Alpine Version | Rust Version | Status | Branch |
|------------------|----------------|--------------|--------|--------|
| 8.0.x | 3.20+ | 1.78.0+ | Current | main |
| 7.0.x | 3.19+ | 1.70.0+ | Stable | suricata-7.x |
| 6.0.x | 3.16+ | 1.60.0+ | Legacy | Not supported |

## Development Workflow

### Working on Both Versions

1. **Make changes to main branch first** (Suricata 8.x)
2. **Test thoroughly**
3. **Cherry-pick or merge changes to suricata-7.x** if applicable
4. **Test both versions**

### Example Workflow
```bash
# Work on main branch
git checkout main
# Make changes...
git add .
git commit -m "Add new feature"

# Apply to 7.x branch if compatible
git checkout suricata-7.x
git cherry-pick <commit-hash>

# Test both versions
./scripts/build-versions.sh --version both --test
```

### Branch-Specific Changes

Some changes may only apply to one version:

- **8.x only**: New features requiring latest Rust/Alpine
- **7.x only**: Compatibility fixes for older dependencies
- **Both**: Bug fixes, documentation, scripts

**Note**: The Dockerfile uses dynamic version variables to ensure consistency:
- `--with-revision="${SURICATA_VERSION}-release"` automatically matches the build version
- This prevents version mismatches between branches

## CI/CD Pipeline

The CircleCI pipeline automatically builds both versions:

### Triggers
- **main branch** → Builds and deploys Suricata 8.x
- **suricata-7.x branch** → Builds and deploys Suricata 7.x

### Workflow Names
- `build_scan_deploy_8x` - For main branch
- `build_scan_deploy_7x` - For suricata-7.x branch

## Maintenance Guidelines

### Version Updates

#### Updating Suricata 8.x
```bash
git checkout main
# Update Makefile and Dockerfile defaults
sed -i 's/SURICATA_VERSION ?= 8.0.0/SURICATA_VERSION ?= 8.0.1/' Makefile
sed -i 's/ARG SURICATA_VERSION=8.0.0/ARG SURICATA_VERSION=8.0.1/' docker/Dockerfile
git commit -am "Update Suricata to 8.0.1"
git tag v8.0.1
```

#### Updating Suricata 7.x
```bash
git checkout suricata-7.x
# Update Makefile and Dockerfile defaults
sed -i 's/SURICATA_VERSION ?= 7.0.11/SURICATA_VERSION ?= 7.0.12/' Makefile
sed -i 's/ARG SURICATA_VERSION=7.0.11/ARG SURICATA_VERSION=7.0.12/' docker/Dockerfile
git commit -am "Update Suricata to 7.0.12"
git tag v7.0.12
```

### Syncing Common Changes

Use the provided script to sync common changes:
```bash
# This will be implemented in the next task
./scripts/sync-versions.sh
```

## Troubleshooting

### Common Issues

#### Build Fails on Wrong Alpine Version
```bash
# Error: Rust version incompatible
# Solution: Use correct Alpine version for each branch
git checkout main      # Uses Alpine 3.20
git checkout suricata-7.x  # Uses Alpine 3.19
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

# Rebuild with correct tags
./scripts/build-versions.sh --version both
```

### Getting Help

1. Check current configuration: `make help`
2. Verify branch: `git branch --show-current`
3. Test build: `make build && make test`
4. Use multi-version script: `./scripts/build-versions.sh --help`

## Best Practices

1. **Always test both versions** when making changes
2. **Use the multi-version build script** for consistency
3. **Keep documentation updated** for both versions
4. **Tag releases properly** with version-specific tags
5. **Monitor compatibility** between versions
6. **Use environment variables** for version overrides when needed

## Migration Guide

### From Single Version to Multi-Version

If you were using the old single-version approach:

```bash
# Old way
make build

# New way - specify version
git checkout main        # For 8.x
make build

git checkout suricata-7.x  # For 7.x
make build

# Or use the script
./scripts/build-versions.sh --version both
```

### Docker Pull Commands

```bash
# Suricata 8.x
docker pull username/suricata:latest
docker pull username/suricata:8
docker pull username/suricata:8.0.0

# Suricata 7.x
docker pull username/suricata:7-latest
docker pull username/suricata:7
docker pull username/suricata:7.0.11
```
