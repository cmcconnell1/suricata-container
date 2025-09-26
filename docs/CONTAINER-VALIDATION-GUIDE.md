# Container Validation Guide

## Overview

This guide provides comprehensive testing and validation procedures for both Suricata container variants, including the refactored Oracle Linux build with Napatech driver support.

## Container Variants Testing

### Alpine Linux Variant (252MB)
- **Base**: Alpine Linux 3.20
- **Target**: Modern cloud-native deployments
- **Build**: Standard AF_PACKET support

### Oracle Linux Variant (490MB)
- **Base**: Oracle Linux 9 (legacy refactored from albert_build_scripts)
- **Target**: Enterprise and legacy environments
- **Build Variants**: AF_PACKET (standard) and Napatech (hardware acceleration)
- **Legacy Compatibility**: All 57 legacy packages included

## Build Validation

### 1. Alpine Linux Build Validation

```bash
# Build and basic validation
make build
make test

# Detailed build validation
docker run --platform linux/amd64 --rm --cap-add=NET_ADMIN --cap-add=NET_RAW \
  --entrypoint="" suricata:7.0.11 suricata --build-info

# Expected output includes:
# - Suricata version 7.0.11 RELEASE
# - AF_PACKET support: yes
# - Rust support: yes
# - JA3/JA4 support: yes
# - HTTP/2 decompression: yes
```

### 2. Oracle Linux AF_PACKET Build Validation

```bash
# Build and basic validation
make build-oracle
make test-oracle

# Detailed build validation
docker run --platform linux/amd64 --rm --cap-add=NET_ADMIN --cap-add=NET_RAW \
  --entrypoint="" suricata:7.0.11-ol9-afpacket /usr/local/bin/suricata --build-info

# Expected output includes:
# - Suricata version 7.0.11 RELEASE
# - AF_PACKET support: yes
# - Enhanced SIMD: SSE_4_2, SSE_4_1, SSE_3, SSE_2
# - Stack protection: yes
# - Hyperscan support: yes
```

### 3. Oracle Linux Napatech Build Validation

```bash
# Build Napatech variant
make build-oracle BUILD_VARIANT=napatech

# Test Napatech variant
docker run --platform linux/amd64 --rm --cap-add=NET_ADMIN --cap-add=NET_RAW \
  --entrypoint="" suricata:7.0.11-ol9-napatech /usr/local/bin/suricata --build-info

# Expected output includes:
# - Suricata version 7.0.11 RELEASE
# - Napatech support: yes
# - Napatech includes: /opt/napatech3/include
# - Napatech libraries: /opt/napatech3/lib
```

## Runtime Validation

### 1. Container Startup Validation

```bash
# Alpine variant startup test
docker run -d --name test-alpine \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  -e INTERFACE=lo \
  suricata:7.0.11

# Check startup logs
docker logs test-alpine

# Oracle Linux AF_PACKET startup test
docker run -d --name test-oracle-afpacket \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  -e INTERFACE=lo \
  suricata:7.0.11-ol9-afpacket

# Check startup logs
docker logs test-oracle-afpacket

# Oracle Linux Napatech startup test (if built)
docker run -d --name test-oracle-napatech \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  -e INTERFACE=lo \
  suricata:7.0.11-ol9-napatech

# Check startup logs
docker logs test-oracle-napatech

# Cleanup
docker rm -f test-alpine test-oracle-afpacket test-oracle-napatech
```

### 2. Health Check Validation

```bash
# Test health checks for all variants
docker run -d --name health-test-alpine suricata:7.0.11
docker run -d --name health-test-oracle suricata:7.0.11-ol9-afpacket

# Wait for health check initialization (60 seconds)
sleep 65

# Check health status
docker inspect --format='{{.State.Health.Status}}' health-test-alpine
docker inspect --format='{{.State.Health.Status}}' health-test-oracle

# Expected output: "healthy"

# Manual health check test
docker exec health-test-alpine /usr/local/bin/healthcheck.sh
docker exec health-test-oracle /usr/local/bin/healthcheck.sh

# Cleanup
docker rm -f health-test-alpine health-test-oracle
```

### 3. Configuration Validation

```bash
# Test configuration loading - Alpine
docker run --rm suricata:7.0.11 suricata -T -c /etc/suricata/suricata.yaml

# Test configuration loading - Oracle Linux
docker run --rm suricata:7.0.11-ol9-afpacket \
  /usr/local/bin/suricata -T -c /etc/suricata/suricata.yaml

# Test Napatech configuration (if available)
docker run --rm suricata:7.0.11-ol9-napatech \
  /usr/local/bin/suricata -T -c /etc/suricata/suricata-napatech.yaml

# Expected output: "Configuration provided was successfully loaded."
```

## Feature Validation

### 1. Rule Update Functionality

```bash
# Test suricata-update - Alpine
docker run --rm suricata:7.0.11 suricata-update --help

# Test suricata-update - Oracle Linux
docker run --rm suricata:7.0.11-ol9-afpacket suricata-update --help

# Test rule update process
docker run --rm -v $(pwd)/test-rules:/var/lib/suricata/rules \
  suricata:7.0.11 suricata-update --no-test --data-dir /var/lib/suricata

# Expected: Rules downloaded and processed successfully
```

### 2. Network Interface Detection

```bash
# Test interface detection - Alpine
docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW \
  suricata:7.0.11 suricata --list-runmodes

# Test interface detection - Oracle Linux
docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW \
  suricata:7.0.11-ol9-afpacket /usr/local/bin/suricata --list-runmodes

# Expected output includes AF_PACKET runmodes
```

### 3. Performance Validation

```bash
# Container resource usage test
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" \
  $(docker ps --filter ancestor=suricata:7.0.11 --format "{{.Names}}")

# Memory usage comparison
docker run --rm suricata:7.0.11 sh -c 'cat /proc/meminfo | grep MemTotal'
docker run --rm suricata:7.0.11-ol9-afpacket sh -c 'cat /proc/meminfo | grep MemTotal'
```

## Legacy Compatibility Validation

### 1. RPM Package Validation (Oracle Linux Only)

```bash
# Check if RPM packages were generated during build
docker run --rm --entrypoint="" suricata:7.0.11-ol9-afpacket \
  find /tmp -name "*.rpm" -type f

# Validate RPM package contents
docker run --rm --entrypoint="" suricata:7.0.11-ol9-afpacket \
  rpm -ql albert-suricata-ol9-7.0.11.rpm 2>/dev/null || echo "RPM validation requires build artifacts"
```

### 2. Legacy Package Dependencies

```bash
# Check legacy package installation - Oracle Linux
docker run --rm --entrypoint="" suricata:7.0.11-ol9-afpacket \
  rpm -qa | grep -E "(libmaxminddb|libnet|libyaml|libpcap|libcap-ng|jansson|lz4|file-libs|nspr|nss|numactl-libs|pcre|zlib)"

# Expected: All legacy dependencies present
```

## Napatech Driver Validation

### 1. Napatech Installation Check

```bash
# Check Napatech installation (if Napatech variant built)
docker run --rm --entrypoint="" suricata:7.0.11-ol9-napatech \
  ls -la /opt/napatech3/

# Check Napatech headers
docker run --rm --entrypoint="" suricata:7.0.11-ol9-napatech \
  ls -la /opt/napatech3/include/

# Check Napatech libraries
docker run --rm --entrypoint="" suricata:7.0.11-ol9-napatech \
  ls -la /opt/napatech3/lib/

# Expected: Napatech 3GD v12.4.3.1 files present
```

### 2. Napatech Configuration Validation

```bash
# Test Napatech-specific configuration
docker run --rm --entrypoint="" suricata:7.0.11-ol9-napatech \
  /usr/local/bin/suricata -T -c /etc/suricata/suricata-napatech.yaml

# Check Napatech stream configuration
docker run --rm --entrypoint="" suricata:7.0.11-ol9-napatech \
  grep -A 10 "napatech:" /etc/suricata/suricata-napatech.yaml

# Expected: Napatech configuration loaded successfully
```

## Troubleshooting Common Issues

### Build Issues

```bash
# Check build logs for errors
docker build --no-cache --progress=plain -f docker/Dockerfile.oracle-linux .

# Check Napatech download issues
curl -I "https://your-package-server.example.com/napatech/ntanl_package_3gd-12.4.3.1-linux.tar.gz"

# Verify Oracle Linux repository access
docker run --rm oraclelinux:9 yum repolist
```

### Runtime Issues

```bash
# Check container capabilities
docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW \
  suricata:7.0.11 capsh --print

# Check network interface access
docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW \
  --network host suricata:7.0.11 ip link show

# Debug startup issues
docker run --rm -e DEBUG=1 suricata:7.0.11
```

## Validation Checklist

### Pre-deployment Validation
- [ ] Alpine variant builds successfully
- [ ] Oracle Linux AF_PACKET variant builds successfully
- [ ] Oracle Linux Napatech variant builds successfully (if needed)
- [ ] All variants pass basic functionality tests
- [ ] Health checks work for all variants
- [ ] Configuration files load without errors
- [ ] suricata-update functionality works
- [ ] Network capabilities are properly set

### Production Readiness
- [ ] Container sizes meet expectations (252MB Alpine, 490MB Oracle Linux)
- [ ] Performance benchmarks meet requirements
- [ ] Security scans pass
- [ ] Legacy compatibility verified (Oracle Linux)
- [ ] Napatech drivers functional (if applicable)
- [ ] Documentation updated and accurate

This validation guide ensures comprehensive testing of both container variants and their specific features, including the refactored Oracle Linux build with Napatech support.
