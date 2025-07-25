# Suricata Container Project

A production-ready Docker container for running Suricata IDS/IPS with the latest 2025 features and automated CI/CD pipeline using CircleCI.

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Building and Testing](#building-and-testing)
- [CI/CD Pipeline](#cicd-pipeline)
- [Environment Variables](#environment-variables)
- [Deployment](#deployment)
- [Documentation](#documentation)
- [References](#references)

## Features

- **Alpine Linux 3.19** base for minimal footprint and security (~309MB final image)
- **Suricata 7.0.11** (stable default, July 2025) built from source with full Rust 1.70.0 support
- **Modern Security Features**: JA3/JA4 fingerprinting, HTTP/2 support, TLS analysis, enhanced detection
- **Fully Working suricata-update** - All Python dependencies resolved, rule management working perfectly
- **Automatic rule updates** via suricata-update integration with comprehensive testing
- **Health monitoring** and comprehensive logging with flexible configuration
- **CircleCI pipeline** for automated builds, testing, and deployment to Docker Hub
- **Cross-platform builds** with proper (local) macOS development support (linux/amd64 targeting)
- **Docker Hub integration** with automated publishing on successful builds
- **Comprehensive testing** including local test script for published images
- **Configurable** via environment variables and custom configurations
- **Production-ready** with proper security capabilities and optimized multi-stage builds

## Quick Start

```bash
# Show available commands and platform info
make help

# Check Docker Hub authentication (required for builds)
make check-auth

# Log in to Docker Hub if needed
make login

# Build locally (automatically detects macOS and sets correct platform)
make build

# Test the build
make test

# Run the container (Linux production)
docker run -d --name suricata \
  --net=host \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  -e INTERFACE=eth0 \
  -e UPDATE_RULES=true \
  -v ./logs:/var/log/suricata \
  suricata:latest

# Run with custom interface
docker run --cap-add=NET_ADMIN --cap-add=NET_RAW -e INTERFACE=eth1 suricata:latest

# Skip configuration test if needed
docker run --cap-add=NET_ADMIN --cap-add=NET_RAW -e SKIP_CONFIG_TEST=true suricata:latest
```

**Note**: On macOS, the build automatically targets `linux/amd64` for compatibility with production deployments.

## Build Status

**Successfully Built!** This container has been successfully built and tested with:

- **Suricata 8.0.0** - Latest stable version running perfectly
- **Alpine Linux 3.20** - Modern, secure base image
- **Rust 1.78.0** - Full Rust integration for enhanced features
- **Cross-platform** - Builds successfully on macOS for Linux deployment
- **Docker Hub Ready** - Authentication and build process working
- **All Features** - JA3/JA4, HTTP/2, TLS analysis, and latest detection capabilities

The container is production-ready and includes all 2025 Suricata enhancements.

## Project Structure


```
suricata-container/
├── .circleci/
│   └── config.yml
├── docker/
│   ├── Dockerfile
│   └── config/
│       ├── suricata.yaml
│       └── rules/
│           ├── custom.rules
│           └── reference.config
├── scripts/
│   ├── entrypoint.sh
│   ├── healthcheck.sh
│   └── update-rules.sh
├── docs/
│   ├── SETUP.md
│   ├── USAGE.md
│   └── TROUBLESHOOTING.md
├── Makefile
└── README.md
```

## Configuration

The project includes optimized configurations for:

- **Multi-stage Docker build** with Alpine Linux base
- **Suricata 8.0.0** with Lua, GeoIP, and Rust support
- **Custom rule sets** and automatic updates
- **Health monitoring** and comprehensive logging
- **Security capabilities** for network monitoring

## CI/CD Integration

### Repository and CI/CD Setup

**Current Configuration**:
- **Primary Repository**: Bitbucket (https://bitbucket.org/cmcc123/suricata-container)
- **CI/CD**: CircleCI with Bitbucket integration
- **Docker Hub**: Automated publishing to `cmcc123/suricata` on successful builds

### Environment Variables Required

For CircleCI to work properly, configure these environment variables in your CircleCI project:

1. **SSH_KEY_FINGERPRINT** - SSH key fingerprint for Bitbucket repository access
2. **DOCKERHUB_USERNAME** - Docker Hub username for image publishing
3. **DOCKERHUB_PASSWORD** - Docker Hub password/token for image publishing

### Pipeline Workflow

The CircleCI pipeline automatically:
1. **Build** - Builds the Suricata Docker image
2. **Test** - Runs comprehensive functionality tests
3. **Scan** - Performs security scanning with Trivy
4. **Push** - Publishes to Docker Hub (on main branch only)

### Published Images

Successfully built images are available at:
- **Latest**: `cmcc123/suricata:latest`
- **Tagged**: `cmcc123/suricata:<commit-hash>`

### Alternative Repository Setup

If you need to use GitHub for development, you can add it as a secondary remote:
```bash
git remote add github git@github.com:yourusername/suricata-container.git
git push github main
```

---

## Building and Testing

The build system automatically detects your platform and sets appropriate flags:

```bash
# Show help and platform information
make help

# Build the container (auto-detects macOS vs Linux)
make build

# Test the container
make test

# Build and test in one command
make all

# Clean up images
make clean
```

## Multi-Version Support

This project supports both **Suricata 7.x** (stable/default) and **Suricata 8.x** (latest) using a branching strategy:

### Branch Structure
- **`main` branch** → Suricata 7.x (stable/default: 7.0.11)
- **`suricata-8.x` branch** → Suricata 8.x (latest: 8.0.0)
- **`suricata-7.x` branch** → Suricata 7.x (legacy branch, same as main)

### Quick Start by Version

#### Suricata 7.x (Default/Stable)
```bash
git checkout main
make build
make test
```

#### Suricata 8.x (Latest Features)
```bash
git checkout suricata-8.x
make build
make test
```

### Docker Hub Tags
| Tag | Description | Branch | Usage |
|-----|-------------|--------|-------|
| `latest` | Latest Suricata 7.x | main | Production (stable) |
| `7`, `7.0.11` | Suricata 7.x versions | main | Production (7.x family) |
| `8-latest` | Latest Suricata 8.x | suricata-8.x | Production (latest features) |
| `8`, `8.0.0` | Suricata 8.x versions | suricata-8.x | Production (8.x family) |

**Detailed Documentation**: See [docs/MULTI-VERSION.md](docs/MULTI-VERSION.md) and [docs/TAGGING-STRATEGY.md](docs/TAGGING-STRATEGY.md)

## Version Control

### Controlling Component Versions

You can control the versions of Suricata and other components in several ways:

#### Method 1: Build Arguments (Recommended)
```bash
# Build with specific Suricata version
docker build --build-arg SURICATA_VERSION=7.0.6 -f docker/Dockerfile -t suricata:7.0.6 .

# Build with specific Alpine version
docker build --build-arg ALPINE_VERSION=3.19 -f docker/Dockerfile -t suricata .

# Combine multiple version overrides
docker build \
  --build-arg SURICATA_VERSION=7.0.6 \
  --build-arg ALPINE_VERSION=3.19 \
  -f docker/Dockerfile -t suricata:custom .
```

#### Method 2: Environment Variables with Makefile
```bash
# Build specific version via Makefile
SURICATA_VERSION=7.0.6 make build

# Or export for multiple commands
export SURICATA_VERSION=7.0.6
make build
make test
```

#### Method 3: Modify Configuration Files
For permanent changes, update version values in:
- **Dockerfile**: `ARG SURICATA_VERSION=7.0.11` (line 70)
- **Makefile**: `SURICATA_VERSION ?= 7.0.11` (line 16)

### Available Version Controls

| Component | Main Branch (7.x) | Suricata-8.x Branch | Control Method | Example |
|-----------|-------------------|---------------------|----------------|---------|
| **Suricata** | 7.0.11 | 8.0.0 | `SURICATA_VERSION` | `7.0.10`, `8.0.0` |
| **Alpine Linux** | 3.19 | 3.20 | `ALPINE_VERSION` | `3.19`, `3.18` |
| **Rust** | 1.70.0 | 1.78.0 | `RUST_VERSION` | `1.70.0`, `1.78.0` |
| **Image Tag** | 7.0.11 | 8.0.0 | `TAG` | `latest`, `custom` |

### Version Compatibility Notes

- **Suricata 7.x** (default): Compatible with Alpine 3.18+, uses Rust 1.70.0
- **Suricata 8.x**: Requires Alpine 3.20+ for Rust 1.78.0 support
- **Suricata 6.x**: Compatible with Alpine 3.16+ (legacy, not supported)

Always test version combinations before production deployment.

### Platform Support

- **macOS**: (_for local development_) Automatically builds with `--platform linux/amd64` for production compatibility
- **Linux**: (_default for CI/CD_) Native builds without platform flags
  - **Target CI/CD tool: CircleCI**: Uses native Linux environment, no special flags needed

## CI/CD Pipeline

The project includes a complete CircleCI pipeline that:

1. **Builds** the Docker image with layer caching
2. **Tests** the built image functionality
3. **Scans** for security vulnerabilities using Trivy
4. **Pushes** to container registry (e.g. currently Docker Hub) on successful builds (main branch only)

### Setup CI/CD

1. Connect your repository to CircleCI
2. Set environment variables:
   - `DOCKERHUB_USERNAME` - Your Docker Hub username
   - `DOCKERHUB_PASSWORD` - Your Docker Hub access token

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `INTERFACE` | `eth0` | Network interface to monitor |
| `UPDATE_RULES` | `false` | Update rules on container startup |
| `LOG_LEVEL` | `info` | Logging verbosity level |
| `SKIP_CONFIG_TEST` | `false` | Skip configuration validation on startup |

## Deployment

### Production Deployment

```bash
# Run with host networking for best performance
docker run -d --name suricata \
  --net=host \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  -e INTERFACE=eth0 \
  -e UPDATE_RULES=true \
  -v /var/log/suricata:/var/log/suricata \
  -v /etc/suricata/rules:/etc/suricata/rules \
  --restart=unless-stopped \
  suricata:latest
```

### Resource Requirements

- **Minimum**: 2 CPU cores, 4GB RAM
- **Recommended**: 4 CPU cores, 8GB RAM
- **Storage**: 10GB+ for logs (depending on traffic volume)

### Monitoring

```bash
# View logs
docker logs -f suricata

# Check health status
docker inspect --format='{{json .State.Health}}' suricata

# Update rules manually
docker exec suricata /usr/local/bin/update-rules.sh
```

## Documentation

Detailed documentation is available in the `docs/` directory:

- **[SETUP.md](docs/SETUP.md)** - Installation and setup instructions
- **[USAGE.md](docs/USAGE.md)** - Container usage and configuration
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## References

- [Suricata Documentation](https://suricata.readthedocs.io)
- [Suricata Official Website](https://suricata.io/documentation/)
- [Emerging Threats Rules](https://rules.emergingthreats.net)
- [Suricata Update Documentation](https://suricata-update.readthedocs.io)
- [CircleCI Documentation](https://circleci.com/docs/)

## License

MIT
