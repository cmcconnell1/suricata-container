# Working Examples - Container Build Validation

## Overview

This document provides working examples for validating the refactored Suricata container builds, including Oracle Linux with Napatech driver support.

## Build Examples

### 1. Alpine Linux Build (252MB)

```bash
# Build Alpine variant
make build

# Validate build
make test

# Expected output:
# Building for Linux on macOS - using --platform linux/amd64
# docker run --platform linux/amd64 --rm --cap-add=NET_ADMIN --cap-add=NET_RAW --entrypoint="" suricata:7.0.11 suricata -V
# This is Suricata version 7.0.11 RELEASE

# Check build info
docker run --rm suricata:7.0.11 suricata --build-info
```

### 2. Oracle Linux AF_PACKET Build (490MB)

```bash
# Build Oracle Linux AF_PACKET variant
make build-oracle

# Validate build
make test-oracle

# Expected output:
# docker run --platform linux/amd64 --rm --cap-add=NET_ADMIN --cap-add=NET_RAW --entrypoint="" suricata:7.0.11-ol9-afpacket /usr/local/bin/suricata -V
# This is Suricata version 7.0.11 RELEASE

# Check enhanced features
docker run --rm suricata:7.0.11-ol9-afpacket /usr/local/bin/suricata --build-info | grep -E "(SIMD|Stack|Hyperscan)"
```

### 3. Oracle Linux Napatech Build

```bash
# Build Oracle Linux Napatech variant
make build-oracle BUILD_VARIANT=napatech

# Validate Napatech build
docker run --platform linux/amd64 --rm --cap-add=NET_ADMIN --cap-add=NET_RAW \
  --entrypoint="" suricata:7.0.11-ol9-napatech /usr/local/bin/suricata -V

# Check Napatech support
docker run --rm --entrypoint="" suricata:7.0.11-ol9-napatech \
  /usr/local/bin/suricata --build-info | grep -i napatech

# Expected output: "Napatech support: yes"
```

## Runtime Validation Examples

### 1. Container Startup Validation

```bash
# Test Alpine startup
docker run -d --name test-alpine \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  -e INTERFACE=lo \
  suricata:7.0.11

# Check logs
docker logs test-alpine

# Expected: Suricata starts successfully without errors

# Test Oracle Linux startup
docker run -d --name test-oracle \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  -e INTERFACE=lo \
  suricata:7.0.11-ol9-afpacket

# Check logs
docker logs test-oracle

# Cleanup
docker rm -f test-alpine test-oracle
```

### 2. Configuration Validation

```bash
# Test Alpine configuration
docker run --rm suricata:7.0.11 suricata -T -c /etc/suricata/suricata.yaml

# Test Oracle Linux configuration
docker run --rm suricata:7.0.11-ol9-afpacket \
  /usr/local/bin/suricata -T -c /etc/suricata/suricata.yaml

# Test Napatech configuration (if built)
docker run --rm suricata:7.0.11-ol9-napatech \
  /usr/local/bin/suricata -T -c /etc/suricata/suricata-napatech.yaml

# Expected output for all: "Configuration provided was successfully loaded."
```

### 3. Health Check Validation

```bash
# Start containers with health checks
docker run -d --name health-alpine suricata:7.0.11
docker run -d --name health-oracle suricata:7.0.11-ol9-afpacket

# Wait for health check initialization
sleep 65

# Check health status
docker inspect --format='{{.State.Health.Status}}' health-alpine
docker inspect --format='{{.State.Health.Status}}' health-oracle

# Expected output: "healthy"

# Manual health check
docker exec health-alpine /usr/local/bin/healthcheck.sh
docker exec health-oracle /usr/local/bin/healthcheck.sh

# Expected output: "HEALTH CHECK PASSED: Suricata is running and healthy"

# Cleanup
docker rm -f health-alpine health-oracle
```

## Feature Validation Examples

### 1. Suricata-Update Functionality

```bash
# Test suricata-update - Alpine
docker run --rm suricata:7.0.11 suricata-update --help

# Test suricata-update - Oracle Linux
docker run --rm suricata:7.0.11-ol9-afpacket suricata-update --help

# Test rule update process
mkdir -p test-rules
docker run --rm -v $(pwd)/test-rules:/var/lib/suricata/rules \
  suricata:7.0.11 suricata-update --no-test --data-dir /var/lib/suricata

# Check downloaded rules
ls -la test-rules/
rm -rf test-rules/
```

### 2. Network Interface Detection

```bash
# Test runmode listing - Alpine
docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW \
  suricata:7.0.11 suricata --list-runmodes

# Test runmode listing - Oracle Linux
docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW \
  suricata:7.0.11-ol9-afpacket /usr/local/bin/suricata --list-runmodes

# Expected output includes: "af-packet" runmodes
```

### 3. Performance Comparison

```bash
# Container size comparison
docker images | grep suricata

# Expected output:
# suricata     7.0.11                252MB
# suricata     7.0.11-ol9-afpacket   490MB
# suricata     7.0.11-ol9-napatech   490MB (if built)

# Memory usage test
docker run --rm suricata:7.0.11 sh -c 'free -h'
docker run --rm suricata:7.0.11-ol9-afpacket sh -c 'free -h'
```

## Napatech-Specific Examples

### 1. Napatech Installation Verification

```bash
# Check Napatech directory structure
docker run --rm --entrypoint="" suricata:7.0.11-ol9-napatech \
  ls -la /opt/napatech3/

# Expected output:
# drwxr-xr-x include/
# drwxr-xr-x lib/

# Check Napatech headers
docker run --rm --entrypoint="" suricata:7.0.11-ol9-napatech \
  ls -la /opt/napatech3/include/

# Expected: napatech.h and other header files

# Check Napatech libraries
docker run --rm --entrypoint="" suricata:7.0.11-ol9-napatech \
  find /opt/napatech3/lib -name "*.so" -type f

# Expected: Napatech shared libraries
```

### 2. Napatech Configuration Testing

```bash
# Test Napatech-specific configuration file
docker run --rm --entrypoint="" suricata:7.0.11-ol9-napatech \
  cat /etc/suricata/suricata-napatech.yaml | grep -A 5 "napatech:"

# Expected output:
# napatech:
#   use-all-streams: yes
#   streams:
#     - stream-id: 0
#     - stream-id: 1

# Validate Napatech configuration syntax
docker run --rm suricata:7.0.11-ol9-napatech \
  /usr/local/bin/suricata -T -c /etc/suricata/suricata-napatech.yaml

# Expected: Configuration loads without errors
```

## Legacy Compatibility Examples

### 1. RPM Package Validation

```bash
# Check if RPM packages exist in build artifacts
docker run --rm --entrypoint="" suricata:7.0.11-ol9-afpacket \
  find /tmp -name "*.rpm" -type f 2>/dev/null || echo "RPM packages in build stage only"

# Check legacy package dependencies
docker run --rm --entrypoint="" suricata:7.0.11-ol9-afpacket \
  rpm -qa | grep -E "(libmaxminddb|libnet|libyaml|libpcap|libcap-ng|jansson|lz4|file-libs|nspr|nss|numactl-libs|pcre|zlib)"

# Expected: All legacy dependencies present
```

### 2. Legacy Build Process Verification

```bash
# Check gcc-toolset-13 usage evidence
docker run --rm --entrypoint="" suricata:7.0.11-ol9-afpacket \
  /usr/local/bin/suricata --build-info | grep -E "(GCC|compiler)"

# Check enhanced SIMD support
docker run --rm --entrypoint="" suricata:7.0.11-ol9-afpacket \
  /usr/local/bin/suricata --build-info | grep -i simd

# Expected: SSE_4_2, SSE_4_1, SSE_3, SSE_2 support
```

## Troubleshooting Examples

### 1. Build Issues

```bash
# Debug build with verbose output
docker build --progress=plain --no-cache \
  -f docker/Dockerfile.oracle-linux \
  -t suricata:debug .

# Check Napatech download
curl -I "https://your-package-server.example.com/napatech/ntanl_package_3gd-12.4.3.1-linux.tar.gz"

# Expected: HTTP 200 OK response
```

### 2. Runtime Issues

```bash
# Check container capabilities
docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW \
  suricata:7.0.11 capsh --print

# Debug startup with verbose logging
docker run --rm -e DEBUG=1 suricata:7.0.11

# Check network interface access
docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW \
  --network host suricata:7.0.11 ip link show
```

## Complete Validation Script

```bash
#!/bin/bash
# complete-validation.sh - Comprehensive container validation

echo "=== Suricata Container Validation ==="

# Build all variants
echo "Building Alpine variant..."
make build

echo "Building Oracle Linux AF_PACKET variant..."
make build-oracle

echo "Building Oracle Linux Napatech variant..."
make build-oracle BUILD_VARIANT=napatech

# Test all variants
echo "Testing Alpine variant..."
make test

echo "Testing Oracle Linux variant..."
make test-oracle

# Validate features
echo "Validating container sizes..."
docker images | grep suricata

echo "Validating build info..."
docker run --rm suricata:7.0.11 suricata --build-info | head -10
docker run --rm suricata:7.0.11-ol9-afpacket /usr/local/bin/suricata --build-info | head -10

echo "=== Validation Complete ==="
```

These working examples provide comprehensive validation of the refactored build process, including Oracle Linux with Napatech driver support and legacy compatibility features.
