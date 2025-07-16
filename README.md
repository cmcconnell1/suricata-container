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

- **Alpine Linux 3.20** base for minimal footprint and security (~309MB final image)
- **Suricata 8.0.0** (latest stable, July 2025) built from source with full Rust 1.78.0 support
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

## CI/CD Integration Notes

### Development vs Production Environments

**Important**: This project is configured for dual CI/CD support due to integration limitations:

#### **Development Environment (Current)**
- **Repository**: GitHub (https://github.com/cmcconnell1/suricata-container)
- **CI/CD**: CircleCI with GitHub App integration
- **Reason**: CircleCI's free tier only supports GitHub, GitLab, and Bitbucket Data Center integrations

#### **Production Environment (Client)**
- **Repository**: Bitbucket (client environment)
- **CI/CD**: CircleCI with Bitbucket Data Center integration
- **Configuration**: Same `.circleci/config.yml` will work in both environments

#### **Why This Setup?**
CircleCI's free tier does not support Bitbucket Cloud integration, only:
- GitHub App
- GitLab
- Bitbucket Data Center (enterprise)

The client environment will use Bitbucket + CircleCI enterprise, but for development and testing, we use GitHub + CircleCI free tier with identical configuration.

#### **Migration to Client Environment**
When moving to the client's Bitbucket + CircleCI setup:
1. Push code to client's Bitbucket repository
2. Configure CircleCI project with Bitbucket Data Center integration
3. Set environment variables (`SSH_KEY_FINGERPRINT`, `DOCKERHUB_USERNAME`, `DOCKERHUB_PASSWORD`)
4. The existing `.circleci/config.yml` will work without changes

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
