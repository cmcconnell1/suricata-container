# Build Quick Reference Card

Quick reference for common Suricata container build commands and workflows.

## Quick Start Commands

```bash
# Standard builds
make build                    # Alpine-based Suricata
make build-oracle            # Oracle Linux-based Suricata (legacy refactored)

# Validation
./scripts/pre-commit.sh      # Run all pre-commit checks
./scripts/test-local.sh      # Test built containers
```

## Build Commands

### Alpine Builds
```bash
make build                                    # Default Alpine build
make build SURICATA_VERSION=7.0.11          # Custom Suricata version
make build ALPINE_VERSION=3.19              # Custom Alpine version
```

### Oracle Linux Builds (Legacy Refactored)
```bash
make build-oracle                            # AF_PACKET variant
make build-oracle BUILD_VARIANT=napatech    # Napatech variant
make build-oracle SURICATA_VERSION=7.0.11   # Custom version
```

### Direct Docker Commands
```bash
# Alpine build with custom args
docker build \
  --build-arg SURICATA_VERSION=7.0.11 \
  --build-arg ALPINE_VERSION=3.19 \
  -t suricata:custom \
  -f docker/Dockerfile .

# Oracle Linux build with all options
docker build \
  --build-arg SURICATA_VERSION=7.0.11 \
  --build-arg ORACLE_VERSION=9 \
  --build-arg BUILD_VARIANT=afpacket \
  --build-arg HYPERSCAN_VERSION=5.4.0 \
  -t suricata:ol9-custom \
  -f docker/Dockerfile.oracle-linux .
```

## Build Tracking

### Monitor Build Progress
```bash
# Real-time build with detailed output
docker build --progress=plain \
  -f docker/Dockerfile.oracle-linux \
  -t suricata:monitor .

# Build with timestamped logs
docker build -f docker/Dockerfile.oracle-linux -t suricata:ol9 . 2>&1 | \
  while read line; do echo "[$(date '+%H:%M:%S')] $line"; done

# Monitor system resources
watch -n 5 'docker stats --no-stream && docker system df'
```

### Check Build Status
```bash
docker ps -a | grep build           # Active/recent builds
docker images | grep suricata       # Built images
docker system df                    # Disk usage
docker history suricata:latest      # Image layers
```

## Testing Commands

### Quick Tests
```bash
./scripts/test-local.sh                              # Run all local tests
docker run --rm suricata:latest suricata --version  # Version check
docker run --rm suricata:latest suricata --build-info  # Build info
docker run --rm suricata:latest suricata -T         # Config test
```

### Validation Scripts
```bash
./scripts/pre-commit.sh                    # Pre-commit validation
./scripts/validate-legacy-requirements.sh # Legacy requirements check
./scripts/healthcheck.sh                  # Health check test
```

### Interactive Testing
```bash
# Shell access
docker run -it --rm suricata:latest /bin/sh
docker run -it --rm suricata:7.0.11-ol9-afpacket /bin/bash

# Mount local directory
docker run -it --rm -v $(pwd):/workspace suricata:latest /bin/sh
```

## Debugging

### Build Debugging
```bash
# Build without cache
docker build --no-cache -f docker/Dockerfile.oracle-linux -t suricata:debug .

# Build specific stage only
docker build --target builder -f docker/Dockerfile.oracle-linux -t suricata:builder .

# Detailed build output
docker build --progress=plain --no-cache \
  -f docker/Dockerfile.oracle-linux -t suricata:debug . 2>&1 | tee debug.log
```

### Container Debugging
```bash
# Inspect container
docker inspect suricata:latest
docker run --rm suricata:latest ls -la /usr/local/bin/
docker run --rm suricata:latest cat /etc/suricata/suricata.yaml | head -20

# Check installed packages (Oracle Linux)
docker run --rm suricata:7.0.11-ol9-afpacket rpm -qa | sort
docker run --rm suricata:7.0.11-ol9-afpacket rpm -qa | grep -E "(suricata|hyperscan)"
```

## Development Workflow

### Pre-Development
```bash
git checkout legacy-refactor              # Switch to development branch
./scripts/pre-commit.sh                   # Validate current state
./scripts/validate-legacy-requirements.sh # Check legacy requirements
```

### Development Cycle
```bash
# 1. Make changes to Dockerfile or scripts
# 2. Validate changes
./scripts/pre-commit.sh

# 3. Build and test
make build-oracle
./scripts/test-local.sh

# 4. Debug if needed
docker build --no-cache -f docker/Dockerfile.oracle-linux -t suricata:dev .
docker run -it --rm suricata:dev /bin/bash
```

### Build Variants Testing
```bash
# Test both variants
make build-oracle BUILD_VARIANT=afpacket
make build-oracle BUILD_VARIANT=napatech

# Compare outputs
docker run --rm suricata:7.0.11-ol9-afpacket suricata --build-info > afpacket.txt
docker run --rm suricata:7.0.11-ol9-napatech suricata --build-info > napatech.txt
diff afpacket.txt napatech.txt
```

## Cleanup Commands

### Clean Docker Environment
```bash
docker system prune -a              # Remove all unused containers, images, networks
docker builder prune                # Clean build cache
docker volume prune                 # Remove unused volumes
docker network prune               # Remove unused networks
```

### Selective Cleanup
```bash
docker images | grep suricata | awk '{print $3}' | xargs docker rmi  # Remove Suricata images
docker ps -a | grep Exited | awk '{print $1}' | xargs docker rm      # Remove exited containers
```

## Performance Analysis

### Build Performance
```bash
# Time build process
time make build-oracle

# Analyze build cache
docker system df -v | grep -A 20 "Build cache"

# Check layer sizes
docker history suricata:latest --format "table {{.Size}}\t{{.CreatedBy}}"
```

### Runtime Performance
```bash
# Test startup time
time docker run --rm suricata:latest suricata --version

# Test with resource limits
docker run --rm --memory=512m --cpus=1 suricata:latest suricata -T

# Memory usage test
docker run --rm suricata:latest /scripts/healthcheck.sh
```

## Useful File Locations

```bash
# Configuration files
docker/Dockerfile                    # Alpine-based build
docker/Dockerfile.oracle-linux      # Oracle Linux build (legacy refactored)
docker/config/                      # Configuration files

# Scripts
scripts/pre-commit.sh               # Pre-commit validation
scripts/test-local.sh               # Local testing
scripts/validate-legacy-requirements.sh  # Legacy validation

# Documentation
docs/LOCAL-BUILD-DEVELOPER-GUIDE.md # Comprehensive developer guide
docs/TROUBLESHOOTING.md             # Troubleshooting guide
docs/SETUP.md                       # Setup instructions
```

## Emergency Commands

### Build Failures
```bash
# Complete Docker reset
docker system prune -a --volumes
docker builder prune --all

# Restart Docker daemon (macOS)
killall Docker && open /Applications/Docker.app

# Check Docker status
docker version
docker info
```

### Disk Space Issues
```bash
# Check disk usage
df -h
docker system df

# Free up space
docker system prune -a
docker builder prune --all
docker volume prune
```

### Network Issues
```bash
# Test connectivity
docker run --rm alpine:latest ping -c 3 github.com

# Reset Docker networks
docker network prune
docker network ls
```

---

**Tip**: Bookmark this page for quick access to common commands!

For detailed explanations, see [LOCAL-BUILD-DEVELOPER-GUIDE.md](LOCAL-BUILD-DEVELOPER-GUIDE.md)
