# Tagging Strategy for Suricata Container

This document outlines the comprehensive tagging strategy for both Suricata 7.x (stable/default) and 8.x (latest) versions.

## Overview

The project uses a dual-branch, multi-tag strategy to support both major versions of Suricata while maintaining clear version identification and easy deployment options.

## Branch and Tag Structure

```
Repository Structure:
├── main branch (Suricata 7.x - DEFAULT)
│   ├── Git Tags: v7.0.11, v7.0.12, v7.0.13...
│   └── Docker Tags: latest, 7, 7.0.11, 7.0.12...
├── suricata-8.x branch (Suricata 8.x - LATEST)
│   ├── Git Tags: v8.0.0, v8.0.1, v8.0.2...
│   └── Docker Tags: 8-latest, 8, 8.0.0, 8.0.1...
└── suricata-7.x branch (Suricata 7.x - LEGACY)
    ├── Git Tags: v7.0.11, v7.0.12, v7.0.13...
    └── Docker Tags: 7-latest, 7, 7.0.11, 7.0.12...
```

## Git Tagging Convention

### Tag Format
- **Format**: `v{MAJOR}.{MINOR}.{PATCH}`
- **Examples**: `v7.0.11`, `v7.0.12`, `v8.0.0`, `v8.0.1`

### Tag Creation
```bash
# For Suricata 7.x (main branch - default)
git checkout main
git tag -a v7.0.12 -m "Release Suricata 7.0.12"
git push origin v7.0.12

# For Suricata 8.x (suricata-8.x branch)
git checkout suricata-8.x
git tag -a v8.0.1 -m "Release Suricata 8.0.1"
git push origin v8.0.1
```

## Docker Hub Tagging Strategy

### Repository Information
- **Docker Registry**: `cmcconnell1/suricata`
- **Source Repository**: GitHub (https://github.com/cmcconnell1/suricata-container)
- **CI/CD**: CircleCI with automated publishing

### Suricata 7.x Tags (from main branch - DEFAULT)

| Tag | Description | Example | Usage |
|-----|-------------|---------|-------|
| `latest` | Latest stable 7.x | `cmcconnell1/suricata:latest` | Production (stable default) |
| `7` | Latest 7.x version | `cmcconnell1/suricata:7` | Production (7.x family) |
| `7.0.11` | Specific version | `cmcconnell1/suricata:7.0.11` | Pinned deployments |
| `{commit}` | Specific commit | `cmcconnell1/suricata:a1b2c3d` | Development/testing |

### Suricata 8.x Tags (from suricata-8.x branch)

| Tag | Description | Example | Usage |
|-----|-------------|---------|-------|
| `8-latest` | Latest 8.x | `cmcconnell1/suricata:8-latest` | Production (latest features) |
| `8` | Latest 8.x version | `cmcconnell1/suricata:8` | Production (8.x family) |
| `8.0.0` | Specific version | `cmcconnell1/suricata:8.0.0` | Pinned deployments |
| `{commit}` | Specific commit | `cmcconnell1/suricata:b4c5d6e` | Development/testing |

### Legacy 7.x Tags (from suricata-7.x branch)

| Tag | Description | Example | Usage |
|-----|-------------|---------|-------|
| `7-latest` | Legacy 7.x tag | `suricata:7-latest` | Backward compatibility |
| `7` | Latest 7.x version | `suricata:7` | Legacy deployments |
| `7.0.11` | Specific version | `suricata:7.0.11` | Legacy pinned deployments |

## Usage Examples

### Docker Pull Commands

```bash
# Stable 7.x (recommended for production)
docker pull cmcconnell1/suricata:latest
docker pull cmcconnell1/suricata:7

# Latest 8.x features
docker pull cmcconnell1/suricata:8-latest
docker pull cmcconnell1/suricata:8

# Specific versions (recommended for production)
docker pull cmcconnell1/suricata:7.0.11
docker pull cmcconnell1/suricata:8.0.0

# Development/testing
docker pull cmcconnell1/suricata:a1b2c3d
```

### Docker Run Commands

```bash
# Run stable 7.x (default)
docker run -d --name suricata-stable \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  cmcconnell1/suricata:latest

# Run latest 8.x features
docker run -d --name suricata-latest \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  cmcconnell1/suricata:8-latest

# Run specific version
docker run -d --name suricata-pinned \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  cmcconnell1/suricata:7.0.11
```

## CI/CD Integration

### CircleCI Workflow Tags

The CI/CD pipeline automatically creates Docker tags based on the branch:

```yaml
# Main branch (7.x) creates:
- cmcconnell1/suricata:7.0.11
- cmcconnell1/suricata:7
- cmcconnell1/suricata:latest
- cmcconnell1/suricata:{commit-hash}

# Suricata-8.x branch creates:
- cmcconnell1/suricata:8.0.0
- cmcconnell1/suricata:8
- cmcconnell1/suricata:8-latest
- cmcconnell1/suricata:{commit-hash}

# Suricata-7.x branch (legacy) creates:
- cmcconnell1/suricata:7.0.11
- cmcconnell1/suricata:7
- cmcconnell1/suricata:7-latest
- cmcconnell1/suricata:{commit-hash}
```

## Published Images

Successfully built images are available at:
- **Latest Stable**: `cmcconnell1/suricata:latest` (7.x)
- **Latest Features**: `cmcconnell1/suricata:8-latest` (8.x)
- **Specific Versions**: `cmcconnell1/suricata:7.0.11`, `cmcconnell1/suricata:8.0.0`
- **Commit-based**: `cmcconnell1/suricata:<commit-hash>`

## Version Lifecycle Management

### Release Process

1. **Update Version**
   ```bash
   # For 7.x (main branch)
   git checkout main
   # Update Makefile and Dockerfile defaults
   git commit -am "Update Suricata to 7.0.12"
   git tag v7.0.12
   
   # For 8.x (suricata-8.x branch)
   git checkout suricata-8.x
   # Update Makefile and Dockerfile defaults
   git commit -am "Update Suricata to 8.0.1"
   git tag v8.0.1
   ```

2. **Test Build**
   ```bash
   git checkout main  # or suricata-8.x
   make build && make test
   ```

3. **Push to Registry**
   ```bash
   # CI/CD will automatically build and push on branch push
   git push origin main  # or suricata-8.x
   git push origin v7.0.12  # or v8.0.1
   ```

### Deprecation Strategy

#### When to Deprecate Tags
- **Patch versions**: Keep last 3 patch versions
- **Minor versions**: Keep all minor versions within major
- **Major versions**: Keep 7.x and 8.x, deprecate 6.x

#### Deprecation Process
1. Update documentation to mark as deprecated
2. Keep tags available for 6 months
3. Remove deprecated tags with advance notice

## Best Practices

### For Developers

1. **Always use specific versions in production**
   ```bash
   # Good
   docker pull username/suricata:7.0.11
   
   # Avoid in production
   docker pull username/suricata:latest
   ```

2. **Use family tags for development**
   ```bash
   # Development/testing
   docker pull username/suricata:7
   docker pull username/suricata:8
   ```

3. **Test both versions when making changes**
   ```bash
   git checkout main && make build && make test
   git checkout suricata-8.x && make build && make test
   ```

### For Operations

1. **Pin to specific versions in production**
   ```yaml
   # docker-compose.yml
   services:
     suricata:
       image: username/suricata:7.0.11  # Pinned version
   ```

2. **Use latest tags for development environments**
   ```yaml
   # docker-compose.dev.yml
   services:
     suricata:
       image: username/suricata:latest  # Stable default
   ```

3. **Monitor for new releases**
   - Subscribe to repository releases
   - Check tags regularly: `git tag -l | sort -V`

## Migration Guide

### From Previous Tagging Strategy

#### Old Approach (8.x was default)
```bash
docker pull username/suricata:latest  # Was 8.x
```

#### New Approach (7.x is default)
```bash
# Explicit version selection
docker pull username/suricata:latest    # Now 7.x (stable)
docker pull username/suricata:8-latest  # 8.x (latest features)
docker pull username/suricata:7.0.11    # Specific 7.x
docker pull username/suricata:8.0.0     # Specific 8.x
```

### Updating Existing Deployments

1. **Identify current version**
   ```bash
   docker exec suricata suricata -V
   ```

2. **Choose appropriate tag**
   - If using 7.x → `latest`, `7`, or `7.0.11`
   - If using 8.x → `8-latest`, `8`, or `8.0.0`

3. **Update deployment**
   ```bash
   docker pull username/suricata:7.0.11
   docker stop suricata
   docker rm suricata
   docker run -d --name suricata username/suricata:7.0.11
   ```

## Troubleshooting

### Common Issues

#### Wrong Version Pulled
```bash
# Check what you have
docker images | grep suricata

# Pull specific version
docker pull username/suricata:7.0.11
```

#### Tag Not Found
```bash
# List available tags (if you have access to registry)
# Or check git tags
git tag -l | sort -V
```

#### Version Confusion
```bash
# Check container version
docker run --rm username/suricata:latest suricata -V

# Check git branch/tag
git describe --tags
git branch --show-current
```

## Summary

This tagging strategy provides:

- **Clear version identification** for both major versions
- **Stable default** with 7.x as `latest`
- **Latest features** available via 8.x tags
- **Flexible deployment options** (latest, family, specific)
- **Automated CI/CD integration** with proper tag creation
- **Easy migration path** from previous strategy
- **Consistent naming conventions** across git and Docker tags

The strategy prioritizes stability by making 7.x the default while keeping cutting-edge 8.x features easily accessible.
