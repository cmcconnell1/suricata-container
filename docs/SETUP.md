# Setup Guide

## Build Status: SUCCESS

**Both container variants have been successfully built and tested!** Suricata 7.0.11 is running perfectly on both Alpine Linux (252MB) and Oracle Linux (490MB) variants with modern features including JA3/JA4 fingerprinting, HTTP/2 support, and enhanced TLS analysis.

## Refactored Build Process

The Oracle Linux variant represents a complete refactoring of the legacy albert_build_scripts build process into a modern containerized approach:

### Legacy Integration
- **Source**: Refactored from `cisappdev/albert_build_scripts` Ansible playbooks
- **Compatibility**: Maintains all 57 legacy package dependencies
- **Build Tools**: Uses gcc-toolset-13 for enhanced performance
- **RPM Generation**: Creates distribution-ready RPM packages

### Napatech Driver Support
- **Hardware Acceleration**: Optional Napatech 3GD driver integration (v12.4.3.1)
- **Download Source**: `https://your-package-server.example.com/napatech/`
- **Build Variants**: AF_PACKET (standard) and Napatech (hardware acceleration)
- **Fallback Mechanism**: Graceful fallback if Napatech packages unavailable

## Prerequisites

- Docker 20.10+
- Make (optional)
- CircleCI account (for CI/CD)

## Local Development

### Quick Setup (All Platforms)

Use the development setup script for guided setup:

```sh
./scripts/dev-setup.sh
```

This script will:
- Detect your platform (macOS/Linux)
- Check Docker availability
- Provide platform-specific guidance
- Optionally build the container

### Manual Setup

#### macOS (Intel/Apple Silicon)

The Makefile automatically detects macOS and sets the correct platform flags:

1. Clone the repository
2. Build Alpine variant (252MB):
   ```sh
   make build && make test
   ```
3. Build Oracle Linux variant (490MB):
   ```sh
   make build-oracle && make test-oracle
   ```
4. Build Oracle Linux with Napatech drivers:
   ```sh
   make build-oracle BUILD_VARIANT=napatech && make test-oracle
   ```
5. Build both variants:
   ```sh
   make all
   ```

### Linux

1. Clone the repository
2. Build Alpine variant (252MB):
   ```sh
   make build
   # or manually:
   docker build -t suricata:7.0.11 -f docker/Dockerfile .
   ```
3. Build Oracle Linux variant (490MB):
   ```sh
   make build-oracle
   # or manually:
   docker build -t suricata:7.0.11-ol9-afpacket -f docker/Dockerfile.oracle-linux .
   ```
4. Build Oracle Linux with Napatech drivers:
   ```sh
   make build-oracle BUILD_VARIANT=napatech
   # or manually:
   docker build --build-arg BUILD_VARIANT=napatech \
     -t suricata:7.0.11-ol9-napatech -f docker/Dockerfile.oracle-linux .
   ```
5. Test the variants:
   ```sh
   make test        # Alpine variant
   make test-oracle # Oracle Linux variant
   ```

## CI/CD Setup

1. Fork this repository
2. Set up CircleCI project
3. Configure environment variables:
   - `DOCKERHUB_USERNAME` - Your Docker Hub username
   - `DOCKERHUB_PASSWORD` - Your Docker Hub password/token

## Version Control

### Building Specific Versions

You can build the container with specific component versions:

#### Using Build Arguments
```bash
# Build with specific Suricata version
docker build --build-arg SURICATA_VERSION=7.0.6 -f docker/Dockerfile -t suricata:7.0.6 .

# Build with older Alpine base
docker build --build-arg ALPINE_VERSION=3.19 -f docker/Dockerfile -t suricata .

# Multiple version overrides
docker build \
  --build-arg SURICATA_VERSION=7.0.6 \
  --build-arg ALPINE_VERSION=3.19 \
  -f docker/Dockerfile -t suricata:custom .
```

#### Using Makefile with Environment Variables
```bash
# Set version and build
SURICATA_VERSION=7.0.6 make build

# Or export for session
export SURICATA_VERSION=7.0.6
make build
make test
```

#### Permanent Version Changes
Edit these files for permanent version changes:
- **docker/Dockerfile**: Change `ARG SURICATA_VERSION=8.0.0`
- **Makefile**: Change `SURICATA_VERSION ?= 8.0.0`

### Supported Versions

| Suricata Version | Minimum Alpine | Rust Support | Status |
|------------------|----------------|--------------|--------|
| 8.0.x | 3.20 | 1.78.0+ | Current |
| 7.0.x | 3.18 | 1.70.0+ | Supported |
| 6.0.x | 3.16 | 1.60.0+ | Legacy |

### Version Testing
Always test version combinations:
```bash
# Build and test specific version
SURICATA_VERSION=7.0.6 make build
SURICATA_VERSION=7.0.6 make test
```

## Version Control

### Building Specific Versions

You can build the container with specific component versions:

#### Using Build Arguments
```bash
# Build with specific Suricata version
docker build --build-arg SURICATA_VERSION=7.0.6 -f docker/Dockerfile -t suricata:7.0.6 .

# Build with older Alpine base
docker build --build-arg ALPINE_VERSION=3.19 -f docker/Dockerfile -t suricata .

# Multiple version overrides
docker build \
  --build-arg SURICATA_VERSION=7.0.6 \
  --build-arg ALPINE_VERSION=3.19 \
  -f docker/Dockerfile -t suricata:custom .
```

#### Using Makefile with Environment Variables
```bash
# Set version and build
SURICATA_VERSION=7.0.6 make build

# Or export for session
export SURICATA_VERSION=7.0.6
make build
make test
```

#### Permanent Version Changes
Edit these files for permanent version changes:
- **docker/Dockerfile**: Change `ARG SURICATA_VERSION=8.0.0`
- **Makefile**: Change `SURICATA_VERSION ?= 8.0.0`

### Supported Versions

| Suricata Version | Minimum Alpine | Rust Support | Status |
|------------------|----------------|--------------|--------|
| 8.0.x | 3.20 | 1.78.0+ | Current |
| 7.0.x | 3.18 | 1.70.0+ | Supported |
| 6.0.x | 3.16 | 1.60.0+ | Legacy |

### Version Testing
Always test version combinations:
```bash
# Build and test specific version
SURICATA_VERSION=7.0.6 make build
SURICATA_VERSION=7.0.6 make test
```

## Custom Rules

Place custom rules in `docker/config/rules/custom.rules`

Rule updates can be triggered by:
- Setting `UPDATE_RULES=true` environment variable
- Running `/usr/local/bin/update-rules.sh` in the container
