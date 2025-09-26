# =============================================================================
# SURICATA DOCKER BUILD - MULTI-STAGE DOCKERFILE
# =============================================================================
# This Dockerfile builds a production-ready Suricata IDS/IPS container
# using Alpine Linux for minimal footprint and maximum security.
#
# Build Arguments (can be overridden at build time):
# - ALPINE_VERSION: Base Alpine Linux version (default: 3.19)
# - SURICATA_VERSION: Suricata version to build (default: 7.0.11)
# - RUST_VERSION: Rust compiler version (default: 1.70.0)
# - PYTHON_VERSION: Python version for suricata-update (default: 3.11)
#
# Usage:
#   docker build -f docker/Dockerfile -t suricata .
#   docker build --build-arg SURICATA_VERSION=8.0.0 -f docker/Dockerfile -t suricata:8.0.0 .
#
# Multi-Version Support:
#   Main branch (default): Suricata 7.x (stable)
#   suricata-8.x branch: Suricata 8.x (latest features)
# =============================================================================

# -----------------------------------------------------------------------------
# BUILD STAGE: Compile Suricata from source
# -----------------------------------------------------------------------------
# This stage contains all build dependencies and compiles Suricata.
# The compiled binaries will be copied to the runtime stage.
ARG ALPINE_VERSION=3.19
FROM alpine:${ALPINE_VERSION} AS builder

# Install build dependencies
# These packages are needed to compile Suricata from source but won't be
# included in the final runtime image to keep it minimal
RUN apk add --no-cache \
    # Core build tools
    build-base \
    autoconf \
    automake \
    libtool \
    pkgconf \
    flex \
    bison \
    # Network libraries for packet capture and manipulation
    libpcap-dev \
    libnet-dev \
    # Configuration and data format libraries
    yaml-dev \
    jansson-dev \
    file-dev \
    # Pattern matching and compression
    pcre2-dev \
    zlib-dev \
    # Security capabilities
    libcap-dev \
    libcap-ng-dev \
    # SSL/TLS support
    openssl-dev \
    # Python support for suricata-update tool
    python3-dev \
    py3-pip \
    py3-yaml \
    # Version control and download tools
    git \
    curl \
    # Linux kernel headers for low-level network access
    linux-headers \
    # Rust compiler for modern Suricata features
    rust \
    cargo

# -----------------------------------------------------------------------------
# SURICATA COMPILATION: Download, configure, and build Suricata from source
# -----------------------------------------------------------------------------
# Download and compile Suricata with optimized settings for container deployment
ARG SURICATA_VERSION=7.0.11
ARG RUST_VERSION=1.70.0
ARG PYTHON_VERSION=3.11
RUN mkdir -p /usr/src/suricata && \
    cd /usr/src/suricata && \
    # Download and extract Suricata source code
    curl -L https://www.openinfosecfoundation.org/download/suricata-${SURICATA_VERSION}.tar.gz | tar xz --strip-components=1 && \
    # Configure build with container-optimized settings
    ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var \
        # Disable features not needed in containers
        --disable-lua \
        --disable-gccmarch-native \
        --disable-geoip \
        --disable-hiredis \
        # Enable modern features
        --enable-rust \
        --enable-revision \
        --with-revision="${SURICATA_VERSION}-release" && \
    # Compile Suricata (this takes several minutes)
    make && \
    # Install binaries, configs, and rules
    make install-full && \
    # Update library cache (ignore errors in containers)
    ldconfig || true

# -----------------------------------------------------------------------------
# SURICATA-UPDATE TOOL: Install Python-based rule management tool
# -----------------------------------------------------------------------------
# Install suricata-update for automatic rule downloads and management
RUN pip3 install --break-system-packages --upgrade pip && \
    pip3 install --break-system-packages suricata-update

# =============================================================================
# RUNTIME STAGE: Minimal production container
# =============================================================================
# This stage creates the final minimal container with only runtime dependencies
FROM alpine:3.20

# Install runtime dependencies (libraries only, no build tools)
# These are the minimal packages needed to run Suricata in production
RUN apk add --no-cache \
    # Core network libraries (runtime versions)
    libpcap \
    libnet \
    # Configuration and data format libraries
    yaml \
    jansson \
    file \
    # Pattern matching and compression
    pcre2 \
    zlib \
    # Security capabilities for privilege management
    libcap \
    libcap-ng \
    # SSL/TLS support
    openssl \
    # Python runtime for suricata-update
    python3 \
    py3-pip \
    py3-yaml \
    # Network debugging tools
    tcpdump \
    jq \
    # C++ standard library for Rust components
    libstdc++ \
    # Clean up package cache to reduce image size
    && rm -rf /var/cache/apk/*

# -----------------------------------------------------------------------------
# COPY COMPILED BINARIES: Transfer from build stage
# -----------------------------------------------------------------------------
# Copy the compiled Suricata binaries from the builder stage
COPY --from=builder /usr/bin/suricata /usr/bin/suricata
COPY --from=builder /usr/bin/suricatasc /usr/bin/suricatasc
COPY --from=builder /usr/bin/suricata-update /usr/bin/suricata-update
# Copy default Suricata configuration
COPY --from=builder /etc/suricata /etc/suricata

# Copy libhtp library conditionally (needed for Suricata 7.x, built-in for 8.x)
COPY --from=builder /usr/lib/libhtp* /usr/lib/

# -----------------------------------------------------------------------------
# PYTHON DEPENDENCIES: Install suricata-update in runtime stage
# -----------------------------------------------------------------------------
# Install suricata-update directly in the runtime stage to avoid version conflicts
RUN pip3 install --break-system-packages suricata-update

# -----------------------------------------------------------------------------
# CONTAINER SETUP: Create directories and copy configuration
# -----------------------------------------------------------------------------
# Create required directories for Suricata operation
RUN mkdir -p /var/log/suricata /var/run/suricata /etc/suricata/rules

# Copy custom configuration files and management scripts
COPY docker/config/suricata.yaml /etc/suricata/
COPY docker/config/rules/ /etc/suricata/rules/
COPY scripts/entrypoint.sh /usr/local/bin/
COPY scripts/healthcheck.sh /usr/local/bin/
COPY scripts/update-rules.sh /usr/local/bin/

# -----------------------------------------------------------------------------
# SECURITY AND PERMISSIONS: Set up capabilities and permissions
# -----------------------------------------------------------------------------
# Grant network capabilities to Suricata binary (required for packet capture)
# Make scripts executable
RUN setcap cap_net_raw,cap_net_admin=eip /usr/bin/suricata && \
    chmod +x /usr/local/bin/*.sh

# -----------------------------------------------------------------------------
# CONTAINER RUNTIME CONFIGURATION
# -----------------------------------------------------------------------------
# Health check to monitor container status
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

# Set working directory and define container entry point
WORKDIR /etc/suricata
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["-i", "eth0"]
