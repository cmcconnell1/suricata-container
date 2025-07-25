# Tagging Strategy for Suricata Container

This document outlines the comprehensive tagging strategy for both Suricata 8.x and 7.x versions.

## Overview

The project uses a dual-branch, multi-tag strategy to support both major versions of Suricata while maintaining clear version identification and easy deployment options.

## Branch and Tag Structure

```
Repository Structure:
├── main branch (Suricata 8.x)
│   ├── Git Tags: v8.0.0, v8.0.1, v8.0.2...
│   └── Docker Tags: latest, 8, 8.0.0, 8.0.1...
└── suricata-7.x branch (Suricata 7.x)
    ├── Git Tags: v7.0.11, v7.0.12, v7.0.13...
    └── Docker Tags: 7-latest, 7, 7.0.11, 7.0.12...
```

## Git Tagging Convention

### Tag Format
- **Format**: `v{MAJOR}.{MINOR}.{PATCH}`
- **Examples**: `v8.0.0`, `v8.0.1`, `v7.0.11`, `v7.0.12`

### Tag Creation
```bash
# For Suricata 8.x (main branch)
git checkout main
git tag -a v8.0.1 -m "Release Suricata 8.0.1"
git push origin v8.0.1

# For Suricata 7.x (suricata-7.x branch)
git checkout suricata-7.x
git tag -a v7.0.12 -m "Release Suricata 7.0.12"
git push origin v7.0.12
```

### Automated Tag Creation
Use the update script for consistent tagging:
```bash
# Update and tag Suricata 8.x
./scripts/update-version.sh --version 8.0.1 --tag

# Update and tag Suricata 7.x
./scripts/update-version.sh --version 7.0.12 --tag
```

## Docker Hub Tagging Strategy

### Suricata 8.x Tags (from main branch)

| Tag | Description | Example | Usage |
|-----|-------------|---------|-------|
| `latest` | Latest stable 8.x | `suricata:latest` | Production (latest features) |
| `8` | Latest 8.x version | `suricata:8` | Production (8.x family) |
| `8.0.0` | Specific version | `suricata:8.0.0` | Pinned deployments |
| `{commit}` | Specific commit | `suricata:a1b2c3d` | Development/testing |

### Suricata 7.x Tags (from suricata-7.x branch)

| Tag | Description | Example | Usage |
|-----|-------------|---------|-------|
| `7-latest` | Latest stable 7.x | `suricata:7-latest` | Production (stable) |
| `7` | Latest 7.x version | `suricata:7` | Production (7.x family) |
| `7.0.11` | Specific version | `suricata:7.0.11` | Pinned deployments |
| `{commit}` | Specific commit | `suricata:b4c5d6e` | Development/testing |

## Usage Examples

### Docker Pull Commands

```bash
# Latest Suricata 8.x (recommended for new deployments)
docker pull username/suricata:latest
docker pull username/suricata:8

# Latest Suricata 7.x (recommended for stability)
docker pull username/suricata:7-latest
docker pull username/suricata:7

# Specific versions (recommended for production)
docker pull username/suricata:8.0.0
docker pull username/suricata:7.0.11

# Development/testing
docker pull username/suricata:a1b2c3d
```

### Docker Run Commands

```bash
# Run latest 8.x
docker run -d --name suricata-8x \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  username/suricata:latest

# Run latest 7.x
docker run -d --name suricata-7x \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  username/suricata:7-latest

# Run specific version
docker run -d --name suricata-pinned \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  username/suricata:8.0.0
```

## CI/CD Integration

### CircleCI Workflow Tags

The CI/CD pipeline automatically creates Docker tags based on the branch:

```yaml
# Main branch (8.x) creates:
- username/suricata:8.0.0
- username/suricata:8
- username/suricata:latest
- username/suricata:{commit-hash}

# Suricata-7.x branch creates:
- username/suricata:7.0.11
- username/suricata:7
- username/suricata:7-latest
- username/suricata:{commit-hash}
```

### Manual Tagging

For manual builds and pushes:

```bash
# Build and tag both versions
./scripts/build-versions.sh --version both --test --push

# Build and tag 8.x as latest
./scripts/build-versions.sh --version 8 --tag-latest --push

# Build and tag 7.x only
./scripts/build-versions.sh --version 7 --push
```

## Version Lifecycle Management

### Release Process

1. **Update Version**
   ```bash
   ./scripts/update-version.sh --version 8.0.1 --tag
   ```

2. **Test Build**
   ```bash
   git checkout main  # or suricata-7.x
   make build && make test
   ```

3. **Multi-Version Test**
   ```bash
   ./scripts/build-versions.sh --version both --test
   ```

4. **Push to Registry**
   ```bash
   ./scripts/build-versions.sh --version both --push
   ```

5. **Push Git Tags**
   ```bash
   git push origin v8.0.1  # or v7.0.12
   ```

### Deprecation Strategy

#### When to Deprecate Tags
- **Patch versions**: Keep last 3 patch versions
- **Minor versions**: Keep all minor versions within major
- **Major versions**: Keep 8.x and 7.x, deprecate 6.x

#### Deprecation Process
1. Update documentation to mark as deprecated
2. Keep tags available for 6 months
3. Remove deprecated tags with advance notice

## Best Practices

### For Developers

1. **Always use specific versions in production**
   ```bash
   # Good
   docker pull username/suricata:8.0.0
   
   # Avoid in production
   docker pull username/suricata:latest
   ```

2. **Use family tags for development**
   ```bash
   # Development/testing
   docker pull username/suricata:8
   docker pull username/suricata:7
   ```

3. **Test both versions when making changes**
   ```bash
   ./scripts/build-versions.sh --version both --test
   ```

### For Operations

1. **Pin to specific versions in production**
   ```yaml
   # docker-compose.yml
   services:
     suricata:
       image: username/suricata:8.0.0  # Pinned version
   ```

2. **Use latest tags for development environments**
   ```yaml
   # docker-compose.dev.yml
   services:
     suricata:
       image: username/suricata:latest  # Latest features
   ```

3. **Monitor for new releases**
   - Subscribe to repository releases
   - Check tags regularly: `git tag -l | sort -V`

## Migration Guide

### From Single Version to Multi-Version

#### Old Approach
```bash
docker pull username/suricata:latest  # Was always 8.x
```

#### New Approach
```bash
# Explicit version selection
docker pull username/suricata:latest    # Still 8.x latest
docker pull username/suricata:7-latest  # 7.x latest
docker pull username/suricata:8.0.0     # Specific 8.x
docker pull username/suricata:7.0.11    # Specific 7.x
```

### Updating Existing Deployments

1. **Identify current version**
   ```bash
   docker exec suricata suricata -V
   ```

2. **Choose appropriate tag**
   - If using 8.x → `latest`, `8`, or `8.0.0`
   - If using 7.x → `7-latest`, `7`, or `7.0.11`

3. **Update deployment**
   ```bash
   docker pull username/suricata:8.0.0
   docker stop suricata
   docker rm suricata
   docker run -d --name suricata username/suricata:8.0.0
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
# List available tags
curl -s https://registry.hub.docker.com/v2/repositories/username/suricata/tags/ | jq '.results[].name'

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

### Getting Help

1. **Check current tags**: `git tag -l | sort -V`
2. **Verify Docker tags**: Check Docker Hub repository
3. **Test build**: `make build && make test`
4. **Use scripts**: `./scripts/build-versions.sh --help`

## Summary

This tagging strategy provides:

- **Clear version identification** for both major versions
- **Flexible deployment options** (latest, family, specific)
- **Automated CI/CD integration** with proper tag creation
- **Easy migration path** from single to multi-version
- **Consistent naming conventions** across git and Docker tags

The strategy supports both current (8.x) and stable (7.x) versions while maintaining backward compatibility and providing clear upgrade paths.
