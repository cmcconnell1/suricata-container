# Suricata Multi-Version Quick Reference

## Quick Start

### Build Suricata 8.x (Latest)
```bash
git checkout main
make build && make test
```

### Build Suricata 7.x (Stable)
```bash
git checkout suricata-7.x
make build && make test
```

### Build Both Versions
```bash
./scripts/build-versions.sh --version both --test
```

## Docker Tags

| Version | Tags | Usage |
|---------|------|-------|
| **8.x** | `latest`, `8`, `8.0.0` | Latest features |
| **7.x** | `7-latest`, `7`, `7.0.11` | Stable version |

## Docker Pull/Run

```bash
# Suricata 8.x (latest features)
docker pull username/suricata:latest
docker run -d --cap-add=NET_ADMIN --cap-add=NET_RAW username/suricata:latest

# Suricata 7.x (stable)
docker pull username/suricata:7-latest
docker run -d --cap-add=NET_ADMIN --cap-add=NET_RAW username/suricata:7-latest
```

## Management Scripts

### Build Script
```bash
# Build both versions with testing
./scripts/build-versions.sh --version both --test

# Build and push to Docker Hub
./scripts/build-versions.sh --version both --test --push

# Build 8.x and tag as latest
./scripts/build-versions.sh --version 8 --tag-latest --push
```

### Version Update Script
```bash
# Update Suricata 8.x to new version
./scripts/update-version.sh --version 8.0.1 --tag

# Update Suricata 7.x to new version
./scripts/update-version.sh --version 7.0.12 --tag
```

### Sync Script
```bash
# Sync common changes from main to 7.x branch
./scripts/sync-versions.sh --from main --to suricata-7.x

# Interactive sync with file selection
./scripts/sync-versions.sh --interactive
```

## Branch Structure

```
main branch (Suricata 8.x)
├── Default: Suricata 8.0.0, Alpine 3.20, Rust 1.78.0
├── Tags: v8.0.0, v8.0.1, v8.0.2...
└── Docker: latest, 8, 8.0.0...

suricata-7.x branch (Suricata 7.x)
├── Default: Suricata 7.0.11, Alpine 3.19, Rust 1.70.0
├── Tags: v7.0.11, v7.0.12, v7.0.13...
└── Docker: 7-latest, 7, 7.0.11...
```

## Version Overrides

```bash
# Build specific versions on any branch
SURICATA_VERSION=8.0.1 make build
SURICATA_VERSION=7.0.10 make build

# Override multiple components
SURICATA_VERSION=8.0.1 ALPINE_VERSION=3.21 make build
```

## Development Workflow

1. **Make changes on main branch** (8.x)
2. **Test thoroughly**
3. **Sync to 7.x if applicable**
   ```bash
   ./scripts/sync-versions.sh --from main --to suricata-7.x
   ```
4. **Test both versions**
   ```bash
   ./scripts/build-versions.sh --version both --test
   ```

## CI/CD

- **main branch** → Builds Suricata 8.x automatically
- **suricata-7.x branch** → Builds Suricata 7.x automatically
- Both create version-specific Docker tags

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
./scripts/build-versions.sh --version both
```

### Version Verification
```bash
# Test container version
docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW \
  --entrypoint="" suricata:8.0.0 suricata -V
```

## Documentation

- **[Multi-Version Guide](docs/MULTI-VERSION.md)** - Complete multi-version documentation
- **[Tagging Strategy](docs/TAGGING-STRATEGY.md)** - Detailed tagging conventions
- **[Setup Guide](docs/SETUP.md)** - Installation and configuration
- **[Usage Guide](docs/USAGE.md)** - Running and configuring containers

## Best Practices

1. **Use specific versions in production**
   ```bash
   docker pull username/suricata:8.0.0  # Good
   docker pull username/suricata:latest # Avoid in prod
   ```

2. **Test both versions when making changes**
   ```bash
   ./scripts/build-versions.sh --version both --test
   ```

3. **Keep branches in sync for common changes**
   ```bash
   ./scripts/sync-versions.sh --from main --to suricata-7.x
   ```

4. **Use the management scripts for consistency**
   ```bash
   ./scripts/update-version.sh --help
   ./scripts/build-versions.sh --help
   ./scripts/sync-versions.sh --help
   ```

---

**Need Help?** Check the full documentation in the `docs/` directory or run any script with `--help`.
