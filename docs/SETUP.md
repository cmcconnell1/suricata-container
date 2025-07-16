# Setup Guide

## Build Status: SUCCESS!

**The container has been successfully built and tested!** Suricata 8.0.0 is running perfectly with all 2025 features including JA3/JA4 fingerprinting, HTTP/2 support, and enhanced TLS analysis.

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
2. Build the image:
   ```sh
   make build
   ```
3. Test the image:
   ```sh
   make test
   ```

### Linux

1. Clone the repository
2. Build the image:
   ```sh
   make build
   # or manually:
   docker build -t suricata -f docker/Dockerfile .
   ```
3. Test the image:
   ```sh
   make test
   # or manually:
   docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW suricata --version
   ```

## CI/CD Setup

1. Fork this repository
2. Set up CircleCI project
3. Configure environment variables:
   - `DOCKERHUB_USERNAME` - Your Docker Hub username
   - `DOCKERHUB_PASSWORD` - Your Docker Hub password/token

## Custom Rules

Place custom rules in `docker/config/rules/custom.rules`

Rule updates can be triggered by:
- Setting `UPDATE_RULES=true` environment variable
- Running `/usr/local/bin/update-rules.sh` in the container
