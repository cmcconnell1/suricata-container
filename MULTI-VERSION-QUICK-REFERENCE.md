# Suricata Dual-Variant Quick Reference

## Quick Start

### Build Alpine Linux Variant (252MB)
```bash
make build && make test
```

### Build Oracle Linux Variant (490MB)
```bash
make build-oracle && make test-oracle
```

### Build Both Variants
```bash
make all
```

## Container Variants

| Variant | Size | Base OS | Usage |
|---------|------|---------|-------|
| **Alpine** | 252MB | Alpine Linux 3.20 | Modern/Cloud-Native |
| **Oracle Linux** | 490MB | Oracle Linux 9 | Enterprise/Legacy |

## Docker Pull/Run

```bash
# Alpine Linux variant (ultra-lightweight)
docker pull cmcconnell1/suricata:7.0.11
docker run -d --cap-add=NET_ADMIN --cap-add=NET_RAW cmcconnell1/suricata:7.0.11

# Oracle Linux variant (enterprise)
docker pull cmcconnell1/suricata:7.0.11-ol9-afpacket
docker run -d --cap-add=NET_ADMIN --cap-add=NET_RAW cmcconnell1/suricata:7.0.11-ol9-afpacket
```

## Published Images

Successfully built images are available at:
- **Alpine Variant**: `cmcconnell1/suricata:7.0.11` (252MB)
- **Oracle Linux Variant**: `cmcconnell1/suricata:7.0.11-ol9-afpacket` (490MB)
- **Commit-based**: `cmcconnell1/suricata:<commit-hash>`

## Container Architecture

```
Alpine Linux Variant (252MB)
├── Base: Alpine Linux 3.20, Rust 1.76.0, Python 3.12
├── Optimization: 75% smaller than industry standards
├── Use Case: Modern cloud-native deployments
└── Docker: suricata:7.0.11

Oracle Linux Variant (490MB)
├── Base: Oracle Linux 9, Rust 1.76.0, Python 3.11
├── Legacy: All 57 legacy packages included
├── Use Case: Enterprise and legacy environments
└── Docker: suricata:7.0.11-ol9-afpacket

suricata-8.x branch (Suricata 8.x - LATEST)
├── Default: Suricata 8.0.0, Alpine 3.20, Rust 1.78.0, Python 3.12
├── Tags: v8.0.0, v8.0.1, v8.0.2...
└── Docker: 8-latest, 8, 8.0.0...

suricata-7.x branch (Suricata 7.x - LEGACY)
├── Same as main branch
└── Docker: 7-latest, 7, 7.0.11...
```

## Version Overrides

```bash
# Build specific versions on any branch
SURICATA_VERSION=7.0.12 make build
SURICATA_VERSION=8.0.1 make build

# Override multiple components
SURICATA_VERSION=8.0.0 ALPINE_VERSION=3.20 make build
```

## Development Workflow

1. **Make changes on main branch** (7.x stable)
2. **Test thoroughly**
3. **Apply to suricata-8.x if applicable**
   ```bash
   git checkout suricata-8.x
   git cherry-pick <commit-hash>
   ```
4. **Test both versions**
   ```bash
   git checkout main && make build && make test
   git checkout suricata-8.x && make build && make test
   ```

## Repository Information

- **Primary Repository**: GitHub (https://github.com/cmcconnell1/suricata-container)
- **CI/CD**: CircleCI with GitHub integration
- **Docker Registry**: Automated publishing to `cmcconnell1/suricata`

## CI/CD

- **main branch** → Builds Suricata 7.x automatically (tags: `latest`, `7`, `7.0.11`)
- **suricata-8.x branch** → Builds Suricata 8.x automatically (tags: `8-latest`, `8`, `8.0.0`)
- **suricata-7.x branch** → Builds Suricata 7.x automatically (tags: `7-latest`)

## Troubleshooting

### Check Current Setup
```bash
# Current branch and version
git branch --show-current
make help

# Built images
docker images | grep suricata
```

### Clean Build
```bash
make clean
make build
```

### Version Verification
```bash
# Test container version
docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW \
  --entrypoint="" suricata:7.0.11 suricata -V
```

## Documentation

- **[Multi-Version Guide](docs/MULTI-VERSION.md)** - Complete multi-version documentation
- **[Tagging Strategy](docs/TAGGING-STRATEGY.md)** - Detailed tagging conventions
- **[Setup Guide](docs/SETUP.md)** - Installation and configuration
- **[Usage Guide](docs/USAGE.md)** - Running and configuring containers

## Best Practices

1. **Use main branch for stable deployments** (7.x)
   ```bash
   docker pull cmcconnell1/suricata:latest  # Stable 7.x
   ```

2. **Use suricata-8.x branch for latest features** (8.x)
   ```bash
   docker pull cmcconnell1/suricata:8-latest  # Latest 8.x
   ```

3. **Pin specific versions in production**
   ```bash
   docker pull cmcconnell1/suricata:7.0.11  # Good
   docker pull cmcconnell1/suricata:latest  # Avoid in prod
   ```

4. **Test both versions when making changes**
   ```bash
   git checkout main && make build && make test
   git checkout suricata-8.x && make build && make test
   ```

## Version Compatibility

| Suricata | Alpine | Rust | Python | Status | Branch |
|----------|--------|------|--------|--------|--------|
| 7.0.x | 3.19+ | 1.70.0+ | 3.11+ | Stable (Default) | main |
| 8.0.x | 3.20+ | 1.78.0+ | 3.12+ | Latest | suricata-8.x |

## Key Changes from Previous Version

- **Default changed**: Main branch now builds Suricata 7.x (was 8.x)
- **Docker `latest` tag**: Now points to 7.x for stability
- **8.x access**: Available on `suricata-8.x` branch with `8-latest` tag
- **Stability focus**: 7.x prioritized for production deployments

## Migration Commands

### From Previous Setup (8.x default)
```bash
# Old way (was 8.x)
make build

# New way - explicit version selection
git checkout main        # For 7.x (stable)
make build

git checkout suricata-8.x  # For 8.x (latest)
make build
```

### Docker Migration
```bash
# Old approach
docker pull cmcconnell1/suricata:latest  # Was 8.x

# New approach
docker pull cmcconnell1/suricata:latest    # Now 7.x (stable)
docker pull cmcconnell1/suricata:8-latest  # For 8.x (latest)
```

---

**Need Help?** Check the full documentation in the `docs/` directory or run `make help` for current configuration.
