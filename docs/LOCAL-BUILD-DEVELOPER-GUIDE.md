# Local Build Developer Guide

This guide provides comprehensive instructions for developers working with Suricata container builds locally, including build tracking, debugging, and development workflows.

## Table of Contents

- [Quick Start](#quick-start)
- [Build Commands](#build-commands)
- [Build Tracking](#build-tracking)
- [Development Workflow](#development-workflow)
- [Debugging Builds](#debugging-builds)
- [Testing](#testing)
- [Legacy Refactoring](#legacy-refactoring)
- [Troubleshooting](#troubleshooting)

## Quick Start

### Prerequisites

```bash
# Ensure Docker is running
docker --version
docker info

# Verify you're in the project directory
pwd  # Should end with /suricata-container

# Check available make targets
make help
```

### Basic Build Commands

```bash
# Build Alpine-based Suricata (default)
make build

# Build Oracle Linux-based Suricata (legacy refactored)
make build-oracle

# Build specific variant
make build-oracle BUILD_VARIANT=napatech

# Build with custom versions
make build SURICATA_VERSION=7.0.11 ALPINE_VERSION=3.19
```

## Build Commands

### Alpine Builds (Default)

```bash
# Standard Alpine build
make build

# Build with specific versions
make build SURICATA_VERSION=7.0.11 ALPINE_VERSION=3.19

# Build for different architecture
docker build --platform linux/arm64 -f docker/Dockerfile -t suricata:arm64 .

# Build with build arguments
docker build \
  --build-arg SURICATA_VERSION=7.0.11 \
  --build-arg ALPINE_VERSION=3.19 \
  -t suricata:custom \
  -f docker/Dockerfile .
```

### Oracle Linux Builds (Legacy Refactored)

The Oracle Linux variant is a complete refactoring of the legacy albert_build_scripts build process.

```bash
# Standard Oracle Linux build (AF_PACKET)
make build-oracle

# Napatech variant build (hardware acceleration)
make build-oracle BUILD_VARIANT=napatech

# Custom Oracle Linux build with all options
docker build \
  --build-arg SURICATA_VERSION=7.0.11 \
  --build-arg ORACLE_VERSION=9 \
  --build-arg BUILD_VARIANT=afpacket \
  --build-arg HYPERSCAN_VERSION=5.4.0 \
  -t suricata:ol9-custom \
  -f docker/Dockerfile.oracle-linux .

# Napatech build with custom version
docker build \
  --build-arg BUILD_VARIANT=napatech \
  --build-arg SURICATA_VERSION=7.0.11 \
  -t suricata:ol9-napatech \
  -f docker/Dockerfile.oracle-linux .

# Build with progress output for debugging
docker build --progress=plain \
  -f docker/Dockerfile.oracle-linux \
  -t suricata:ol9-debug .
```

#### Legacy Build Process Integration

The Oracle Linux Dockerfile replicates the following legacy components:
- **build_suricata_ol9.yml**: Main Suricata build process
- **build_suricata_deps_ol9.yml**: Dependency management
- **install_napatech_libs**: Napatech driver integration
- **build_source role**: RPM package generation

## Build Tracking

### Real-time Build Monitoring

```bash
# Monitor build progress with detailed output
docker build --progress=plain --no-cache \
  -f docker/Dockerfile.oracle-linux \
  -t suricata:ol9-monitor .

# Follow build logs in real-time
docker build -f docker/Dockerfile.oracle-linux -t suricata:ol9 . 2>&1 | tee build.log

# Monitor Docker system resources during build
watch -n 2 'docker system df && echo "=== PROCESSES ===" && docker ps'
```

### Build Process Stages

#### Alpine Build Stages
1. **Base Setup** - Alpine base image and package installation
2. **Dependencies** - Build dependencies and tools
3. **Hyperscan** - Intel Hyperscan compilation
4. **Suricata** - Suricata compilation and configuration
5. **Runtime** - Minimal runtime image creation

#### Oracle Linux Build Stages
1. **Builder Stage** - Oracle Linux 9 with build tools
2. **Repository Setup** - YUM repositories and package management
3. **Dependencies** - Legacy build dependencies (57 packages)
4. **Napatech** - Napatech package download and installation (if enabled)
5. **Hyperscan** - Intel Hyperscan v5.4.0 compilation
6. **Suricata** - Suricata compilation with legacy settings
7. **RPM Generation** - FPM-based RPM package creation
8. **Runtime Stage** - Minimal production image

### Tracking Build Progress

```bash
# Check current build status
docker ps -a | grep -E "(build|suricata)"

# Monitor build resource usage
docker stats

# Check build history
docker images | grep suricata

# Inspect build layers
docker history suricata:latest

# Check build cache usage
docker system df
```

## Development Workflow

### Pre-Development Setup

```bash
# Run pre-commit validation
./scripts/pre-commit.sh

# Validate legacy requirements (Oracle Linux builds)
./scripts/validate-legacy-requirements.sh

# Set up development environment
./scripts/dev-setup.sh
```

### Iterative Development

```bash
# 1. Make changes to Dockerfile or scripts
# 2. Validate changes
./scripts/pre-commit.sh

# 3. Build with no cache for testing
docker build --no-cache -f docker/Dockerfile.oracle-linux -t suricata:dev .

# 4. Test the build
./scripts/test-local.sh

# 5. Run comprehensive tests
make test
```

### Build Variants Testing

```bash
# Test AF_PACKET variant
make build-oracle BUILD_VARIANT=afpacket
docker run --rm suricata:7.0.11-ol9-afpacket suricata --build-info

# Test Napatech variant
make build-oracle BUILD_VARIANT=napatech
docker run --rm suricata:7.0.11-ol9-napatech suricata --build-info

# Compare build outputs
docker run --rm suricata:7.0.11-ol9-afpacket suricata --build-info > afpacket-build.txt
docker run --rm suricata:7.0.11-ol9-napatech suricata --build-info > napatech-build.txt
diff afpacket-build.txt napatech-build.txt
```

## Debugging Builds

### Build Failure Debugging

```bash
# Build with detailed output and no cache
docker build --progress=plain --no-cache \
  -f docker/Dockerfile.oracle-linux \
  -t suricata:debug . 2>&1 | tee debug-build.log

# Inspect failed build layers
docker images -a | head -20

# Run intermediate container for debugging
docker run -it --rm <intermediate-image-id> /bin/bash

# Check specific build stage
docker build --target builder \
  -f docker/Dockerfile.oracle-linux \
  -t suricata:builder-debug .
```

### Interactive Debugging

```bash
# Start container with shell access
docker run -it --rm suricata:latest /bin/sh

# Debug Oracle Linux container
docker run -it --rm suricata:7.0.11-ol9-afpacket /bin/bash

# Mount local directory for debugging
docker run -it --rm \
  -v $(pwd):/workspace \
  suricata:latest /bin/sh

# Check container internals
docker run --rm suricata:latest ls -la /usr/local/bin/
docker run --rm suricata:latest suricata --build-info
docker run --rm suricata:latest cat /etc/suricata/suricata.yaml | head -20
```

### Build Performance Analysis

```bash
# Analyze build time by stage
docker build --progress=plain \
  -f docker/Dockerfile.oracle-linux \
  -t suricata:perf . 2>&1 | \
  grep -E "^\[.*\]|^Step [0-9]" | \
  tee build-timing.log

# Check Docker build cache efficiency
docker system df
docker builder prune  # Clean build cache if needed

# Monitor system resources during build
top -p $(pgrep docker)
```

## Testing

### Local Testing Scripts

```bash
# Run all local tests
./scripts/test-local.sh

# Test specific functionality
./scripts/test-latest-build.sh

# Validate build requirements
./scripts/validate-legacy-requirements.sh

# Health check testing
docker run --rm suricata:latest /scripts/healthcheck.sh
```

### Manual Testing

```bash
# Test Alpine variant
docker run --rm suricata:7.0.11 suricata --version
docker run --rm suricata:7.0.11 suricata --build-info
docker run --rm suricata:7.0.11 suricata -T  # Test configuration

# Test Oracle Linux AF_PACKET variant
docker run --rm suricata:7.0.11-ol9-afpacket /usr/local/bin/suricata --version
docker run --rm suricata:7.0.11-ol9-afpacket /usr/local/bin/suricata --build-info

# Test Oracle Linux Napatech variant (if built)
docker run --rm suricata:7.0.11-ol9-napatech /usr/local/bin/suricata --version
docker run --rm suricata:7.0.11-ol9-napatech /usr/local/bin/suricata --build-info

# Test with sample traffic
docker run --rm -v $(pwd)/test-data:/data suricata:7.0.11 \
  suricata -r /data/sample.pcap

# Test rule loading
docker run --rm suricata:7.0.11 \
  suricata -T -v -c /etc/suricata/suricata.yaml

# Test Napatech configuration (if available)
docker run --rm suricata:7.0.11-ol9-napatech \
  /usr/local/bin/suricata -T -c /etc/suricata/suricata-napatech.yaml
```

### Napatech-Specific Testing

```bash
# Verify Napatech installation
docker run --rm --entrypoint="" suricata:7.0.11-ol9-napatech \
  ls -la /opt/napatech3/

# Check Napatech libraries
docker run --rm --entrypoint="" suricata:7.0.11-ol9-napatech \
  find /opt/napatech3 -name "*.so" -type f

# Verify Napatech headers
docker run --rm --entrypoint="" suricata:7.0.11-ol9-napatech \
  ls -la /opt/napatech3/include/

# Test Napatech build configuration
docker run --rm --entrypoint="" suricata:7.0.11-ol9-napatech \
  /usr/local/bin/suricata --build-info | grep -i napatech

# Expected output: "Napatech support: yes"
```

### Performance Testing

```bash
# Test container startup time
time docker run --rm suricata:latest suricata --version

# Test memory usage
docker run --rm --memory=512m suricata:latest suricata --version

# Test with resource limits
docker run --rm --cpus=1 --memory=1g suricata:latest \
  suricata -T -c /etc/suricata/suricata.yaml
```

## Legacy Refactoring

### Oracle Linux Legacy Build

The Oracle Linux build replicates functionality from `cisappdev/albert_build_scripts`:

```bash
# Validate all legacy requirements are included
./scripts/validate-legacy-requirements.sh

# Build with legacy compatibility
make build-oracle

# Compare with legacy build output
docker run --rm suricata:7.0.11-ol9-afpacket rpm -qa | grep -E "(suricata|hyperscan)"
```

### Legacy Package Validation

```bash
# Check all 57 legacy packages are included
docker run --rm suricata:7.0.11-ol9-afpacket rpm -qa | wc -l

# Verify specific legacy dependencies
docker run --rm suricata:7.0.11-ol9-afpacket \
  rpm -qa | grep -E "(boost|cmake|gcc-toolset|hyperscan)"

# Test legacy configuration compatibility
docker run --rm suricata:7.0.11-ol9-afpacket \
  suricata --build-info | grep -E "(Hyperscan|GCC)"
```

## Troubleshooting

### Common Issues

#### Build Failures
```bash
# Clean Docker environment
docker system prune -a
docker builder prune

# Rebuild without cache
docker build --no-cache -f docker/Dockerfile.oracle-linux -t suricata:clean .
```

#### Memory Issues
```bash
# Increase Docker memory limit
# Docker Desktop: Settings > Resources > Memory

# Build with reduced parallelism
docker build --build-arg MAKE_JOBS=2 -f docker/Dockerfile.oracle-linux .
```

#### Network Issues
```bash
# Test network connectivity
docker run --rm alpine:latest ping -c 3 github.com

# Use different DNS
docker build --dns 8.8.8.8 -f docker/Dockerfile.oracle-linux .
```

### Getting Help

```bash
# Check project documentation
ls docs/

# View specific documentation
cat docs/TROUBLESHOOTING.md
cat docs/SETUP.md

# Check build logs
tail -f build.log

# Get build information
docker run --rm suricata:latest suricata --build-info
```

### Useful Commands

```bash
# Clean up development environment
docker system prune -a
docker volume prune
docker network prune

# Reset to clean state
make clean  # If available in Makefile

# Check disk usage
docker system df
du -sh .
```

## Advanced Build Techniques

### Multi-stage Build Optimization

```bash
# Build only specific stage for debugging
docker build --target builder \
  -f docker/Dockerfile.oracle-linux \
  -t suricata:builder-only .

# Extract artifacts from build stage
docker create --name temp-container suricata:builder-only
docker cp temp-container:/usr/src/suricata-install ./build-artifacts/
docker rm temp-container
```

### Build Context Optimization

```bash
# Check build context size
du -sh .

# Use .dockerignore to reduce context
echo "*.log" >> .dockerignore
echo "build-artifacts/" >> .dockerignore

# Build with minimal context
docker build -f docker/Dockerfile.oracle-linux \
  --build-context minimal=. \
  -t suricata:minimal .
```

### Parallel Builds

```bash
# Build multiple variants in parallel
make build-oracle BUILD_VARIANT=afpacket &
make build-oracle BUILD_VARIANT=napatech &
wait

# Use BuildKit for parallel builds
DOCKER_BUILDKIT=1 docker build \
  -f docker/Dockerfile.oracle-linux \
  -t suricata:buildkit .
```

## CI/CD Integration

### CircleCI Artifact Storage

The project includes dual storage (ECR + CircleCI artifacts):

```bash
# Simulate CircleCI artifact creation locally
docker save suricata:latest | gzip > suricata-local-build.tar.gz

# Create metadata file
cat > build-metadata.json << EOF
{
  "build_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "git_commit": "$(git rev-parse HEAD)",
  "git_branch": "$(git branch --show-current)",
  "suricata_version": "7.0.11",
  "build_variant": "afpacket"
}
EOF
```

### Local CI Simulation

```bash
# Simulate full CI pipeline locally
./scripts/pre-commit.sh
make build-oracle
./scripts/test-local.sh
docker save suricata:7.0.11-ol9-afpacket | gzip > artifacts/suricata.tar.gz
```

## Build Monitoring and Metrics

### Real-time Monitoring

```bash
# Monitor build progress with timestamps
docker build -f docker/Dockerfile.oracle-linux -t suricata:monitored . 2>&1 | \
  while IFS= read -r line; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $line"
  done | tee timestamped-build.log

# Monitor system resources during build
#!/bin/bash
# monitor-build.sh
while true; do
  echo "=== $(date) ==="
  docker stats --no-stream
  echo "Disk usage: $(df -h / | tail -1 | awk '{print $5}')"
  echo "Memory: $(free -h | grep Mem | awk '{print $3"/"$2}')"
  sleep 30
done
```

### Build Analytics

```bash
# Analyze build time by layer
docker history suricata:latest --format "table {{.CreatedBy}}\t{{.Size}}\t{{.CreatedSince}}"

# Check layer sizes
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

# Build cache analysis
docker system df -v | grep -A 20 "Build cache usage"
```

## Development Best Practices

### Code Quality

```bash
# Run all validation scripts
./scripts/pre-commit.sh
./scripts/validate-legacy-requirements.sh

# Check Dockerfile best practices
docker run --rm -i hadolint/hadolint < docker/Dockerfile.oracle-linux

# Security scanning
docker run --rm -v $(pwd):/workspace \
  aquasec/trivy fs /workspace/docker/
```

### Version Management

```bash
# Check current versions
grep -r "SURICATA_VERSION" docker/
grep -r "HYPERSCAN_VERSION" docker/

# Update versions consistently
./scripts/update-version.sh 7.0.12

# Validate version matrix
./scripts/version-matrix.sh
```

### Documentation

```bash
# Generate build documentation
docker run --rm suricata:latest suricata --build-info > BUILD_INFO.txt

# Create build report
cat > BUILD_REPORT.md << EOF
# Build Report - $(date)

## Image Information
$(docker inspect suricata:latest | jq '.[0].Config.Labels')

## Build Info
$(docker run --rm suricata:latest suricata --build-info)

## Package List
$(docker run --rm suricata:latest rpm -qa | sort)
EOF
```

---

For more detailed information, see:
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
- [SETUP.md](SETUP.md) - Initial setup instructions
- [USAGE.md](USAGE.md) - Container usage examples
- [MULTI-VERSION.md](MULTI-VERSION.md) - Multi-version build strategies
