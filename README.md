# Suricata Container Project

CIS Albert Suricata Docker container IDS/IPS with **Suricata 7.x as the stable default** and 8.x support for future adoption, featuring automated CI/CD pipeline using CircleCI.

## Table of Contents

- [Overview](#overview)
- [Multi-Version Support](#multi-version-support)
- [Quick Start](#quick-start)
- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Building and Testing](#building-and-testing)
- [CI/CD Pipeline](#cicd-pipeline)
- [Published Images](#published-images)
- [Documentation](#documentation)
- [Development](#development)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Overview

This project provides production-ready Suricata IDS/IPS containers with **Suricata 7.x as the stable, recommended default** and 8.x available for organizations ready to adopt cutting-edge features. Built on Alpine Linux for minimal footprint and maximum security, with comprehensive CI/CD automation.

### Key Highlights

- **Stable Default**: Suricata 7.x (7.0.11) as the production-ready default choice
- **Future Ready**: Suricata 8.x (8.0.0) available for advanced feature adoption
- **Production Optimized**: Alpine Linux base (252MB for 7.x, 314MB for 8.x)
- **Modern Security**: JA3/JA4 fingerprinting, HTTP/2 support, TLS analysis
- **Automated CI/CD**: CircleCI pipeline with artifact retention
- **Comprehensive Testing**: Both versions successfully built and validated

## Multi-Version Support

The project supports two major Suricata versions using a branching strategy:

| Version | Branch | Status | Docker Tags | Use Case |
|---------|--------|--------|-------------|----------|
| **7.x** | `main` | Stable (Default) | `latest`, `7`, `7.0.11` | Production deployments |
| **8.x** | `suricata-8.x` | Latest Features | `8-latest`, `8`, `8.0.0` | Cutting-edge features |
| **7.x** | `suricata-7.x` | Legacy | `7-latest` | Backward compatibility |

### Quick Version Selection

```bash
# Stable 7.x (recommended for production)
docker pull cis-devops/suricata:latest

# Latest 8.x features
docker pull cis-devops/suricata:8-latest

# Specific versions
docker pull cis-devops/suricata:7.0.11
docker pull cis-devops/suricata:8.0.0
```

## Quick Start

### Using Published Images

```bash
# Pull and run stable 7.x (recommended for production)
docker pull cis-devops/suricata:latest
docker run -d --name suricata-stable \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  --network host \
  -e INTERFACE=eth0 \
  -e UPDATE_RULES=true \
  -v ./logs:/var/log/suricata \
  cis-devops/suricata:latest

# Pull and run latest 8.x features
docker pull cis-devops/suricata:8-latest
docker run -d --name suricata-latest \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  --network host \
  -e INTERFACE=eth0 \
  cis-devops/suricata:8-latest

# Check logs and status
docker logs suricata-stable
docker exec -it suricata-stable suricata -V
```

### Building from Source

```bash
# Clone repository
git clone https://bitbucket.org/cis-devops/suricata-container.git
cd suricata-container

# Build Suricata 7.x (stable/default)
git checkout main
make build && make test

# Build Suricata 8.x (latest features)
git checkout suricata-8.x
make build && make test

# Show available commands
make help
```

## Features

### Suricata 7.x (Stable/Default)
- **Alpine Linux 3.19** base for proven stability
- **Suricata 7.0.11** with Rust 1.70.0 support
- **Proven Features**: JA3 fingerprinting, stable TLS analysis
- **Production Ready**: Extensively tested and validated
- **Long-term Support**: Stable API and configuration

### Suricata 8.x (Future/Advanced Features)
- **Alpine Linux 3.20** base with latest security updates
- **Suricata 8.0.0** with Rust 1.78.0 support (available for future adoption)
- **Next-Generation Features**: JA4 fingerprinting, HTTP/2 decompression
- **Advanced Detection**: Enhanced TLS analysis and protocol support
- **Modern Architecture**: Latest Rust optimizations for forward compatibility

### Common Features (Both Versions)
- **Fully Working suricata-update** - All Python dependencies resolved
- **Automatic rule updates** via suricata-update integration
- **Health monitoring** and comprehensive logging
- **Configurable** via environment variables and custom configurations
- **Cross-platform builds** with proper development support
- **Comprehensive testing** including automated validation
- **Production-ready** with proper security capabilities and optimized multi-stage builds

## Installation

### Prerequisites

- Docker 20.10+ with BuildKit support
- For building: Git, Make, and appropriate platform tools
- For production: Linux host with network interfaces

### System Requirements

- **Memory**: Minimum 512MB RAM, recommended 1GB+
- **Storage**: ~500MB for image, additional space for logs
- **Network**: Host network access or bridge with port forwarding
- **Capabilities**: `NET_ADMIN` and `NET_RAW` for packet capture
```

**Note**: On macOS, the build automatically targets `linux/amd64` for compatibility with production deployments.

## Build Status

### ✅ Latest Successful Builds (Verified July 25, 2025)

#### Suricata 7.x (Stable/Production - **RECOMMENDED**)
- **Version**: Suricata 7.0.11 (stable, production-ready)
- **Base Image**: Alpine Linux 3.19 (7.39MB base)
- **Final Image Size**: 252MB (optimized multi-stage build)
- **Rust Support**: 1.70.0 (proven stability)
- **Python**: 3.11 (stable ecosystem)
- **Build Status**: ✅ **Successfully built and tested**
- **Features**: JA3 fingerprinting, stable TLS analysis, proven reliability
- **suricata-update**: ✅ Fully working with all dependencies resolved
- **Use Case**: **Recommended for all production deployments**

#### Suricata 8.x (Future/Advanced Features)
- **Version**: Suricata 8.0.0 (available for future adoption)
- **Base Image**: Alpine Linux 3.20 (7.79MB base)
- **Final Image Size**: 314MB (includes latest features)
- **Rust Support**: 1.78.0 (latest optimizations)
- **Python**: 3.12 (modern ecosystem)
- **Build Status**: ✅ **Successfully built and tested**
- **Features**: JA4 fingerprinting, HTTP/2 decompression, enhanced TLS analysis
- **suricata-update**: ✅ Fully working with all dependencies resolved
- **Use Case**: **Available for organizations ready to adopt cutting-edge features**

### Build Verification Results
```bash
# Suricata 7.x Test Results
$ docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW --entrypoint="" suricata:7.0.11 suricata -V
This is Suricata version 7.0.11 RELEASE

# Suricata 8.x Test Results
$ docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW --entrypoint="" suricata:8.0.0 suricata -V
This is Suricata version 8.0.0 RELEASE

# Both versions have working suricata-update
$ docker run --rm suricata:7.0.11 suricata-update --help  # ✅ Working
$ docker run --rm suricata:8.0.0 suricata-update --help   # ✅ Working
```

### Build Information
- **Cross-platform**: Builds successfully on Linux with Docker
- **CI/CD Ready**: Automated builds with artifact retention
- **All Features**: Complete feature sets for both versions working perfectly
- **Docker BuildKit**: Compatible with both legacy and BuildKit builders

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
- **Suricata 7.0.11** (stable/default) with proven Lua, GeoIP, and Rust support
- **Suricata 8.0.0** (future/advanced) available for organizations ready for latest features
- **Custom rule sets** and automatic updates
- **Health monitoring** and comprehensive logging
- **Security capabilities** for network monitoring

## CI/CD Pipeline

### Repository and CI/CD Setup

**Current Configuration**:
- **Primary Repository**: Bitbucket (https://bitbucket.org/cis-devops/suricata-container)
- **CI/CD**: CircleCI with Bitbucket integration
- **Artifact Retention**: Container images retained for 30 days
- **Multi-Branch Support**: Automated builds for main, suricata-8.x, and suricata-7.x branches

### Pipeline Workflow

1. **Build** - Multi-stage Docker build with optimization
2. **Test** - Comprehensive validation and security scanning
3. **Scan** - Trivy security vulnerability scanning
4. **Artifact** - Container images stored as CircleCI artifacts
5. **Deploy** - Ready for AWS ECR deployment (TODO)

### Environment Variables Required

For CircleCI to work properly, configure these environment variables in your CircleCI project:

1. **SSH_KEY_FINGERPRINT** - SSH key fingerprint for Bitbucket repository access
2. **AWS_ACCESS_KEY_ID** - AWS access key for ECR publishing (TODO)
3. **AWS_SECRET_ACCESS_KEY** - AWS secret key for ECR publishing (TODO)
4. **AWS_DEFAULT_REGION** - AWS region for ECR repository (TODO)

### Pipeline Workflow

The CircleCI pipeline automatically:
1. **Build** - Multi-stage Docker build with optimization
2. **Test** - Comprehensive validation and security scanning
3. **Scan** - Trivy security vulnerability scanning
4. **Artifact** - Container images stored as CircleCI artifacts
5. **Deploy** - Ready for AWS ECR deployment (TODO)

### Branch-Specific Builds

- **main branch** → Builds Suricata 7.x (tags: `latest`, `7`, `7.0.11`)
- **suricata-8.x branch** → Builds Suricata 8.x (tags: `8-latest`, `8`, `8.0.0`)
- **suricata-7.x branch** → Builds Suricata 7.x (tags: `7-latest`)

## Published Images

Successfully built images are available at:
- **Latest Stable**: `cis-devops/suricata:latest` (7.x - **Recommended**)
- **Future Features**: `cis-devops/suricata:8-latest` (8.x - Advanced)
- **Specific Versions**: `cis-devops/suricata:7.0.11`, `cis-devops/suricata:8.0.0`
- **Commit-based**: `cis-devops/suricata:<commit-hash>`

### Image Information

| Tag | Version | Size | Base | Use Case |
|-----|---------|------|------|----------|
| `latest` | 7.0.11 | ~309MB | Alpine 3.19 | Production (stable) |
| `8-latest` | 8.0.0 | ~315MB | Alpine 3.20 | Production (latest) |
| `7` | 7.0.11 | ~309MB | Alpine 3.19 | 7.x family |
| `8` | 8.0.0 | ~315MB | Alpine 3.20 | 8.x family |



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
- **Dockerfile**: `ARG SURICATA_VERSION=8.0.0` (line 33)
- **Makefile**: `SURICATA_VERSION ?= 8.0.0` (line 4)

### Available Version Controls

| Component | Default | Control Method | Example |
|-----------|---------|----------------|---------|
| **Suricata** | 8.0.0 | `SURICATA_VERSION` | `7.0.6`, `6.0.14` |
| **Alpine Linux** | 3.20 | `ALPINE_VERSION` | `3.19`, `3.18` |
| **Image Tag** | 8.0.0 | `TAG` | `latest`, `custom` |

### Version Compatibility Notes

- **Suricata 8.x**: Requires Alpine 3.20+ for Rust 1.78.0 support
- **Suricata 7.x**: Compatible with Alpine 3.18+
- **Suricata 6.x**: Compatible with Alpine 3.16+

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
