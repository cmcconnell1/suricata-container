# =============================================================================
# SURICATA DOCKER BUILD - MULTI-STAGE DOCKERFILE
# =============================================================================
# This Dockerfile builds a production-ready Suricata IDS/IPS container
# using Alpine Linux for minimal footprint and maximum security.
#
# Build Arguments (can be overridden at build time):
# - ALPINE_VERSION: Base Alpine Linux version (default: 3.20)
# - SURICATA_VERSION: Suricata version to build (default: 8.0.0)
#
# Usage:
#   docker build -f docker/Dockerfile -t suricata .
#   docker build --build-arg SURICATA_VERSION=7.0.6 -f docker/Dockerfile -t suricata:7.0.6 .
# =============================================================================

# -----------------------------------------------------------------------------
# BUILD STAGE: Compile Suricata from source
# -----------------------------------------------------------------------------
# This stage contains all build dependencies and compiles Suricata.
# The compiled binaries will be copied to the runtime stage.
ARG ALPINE_VERSION=3.20
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

# Install Suricata from source
# Using latest stable version 8.0.0 (July 2025)
ARG SURICATA_VERSION=8.0.0
ARG RUST_VERSION=1.78.0
RUN mkdir -p /usr/src/suricata && \
    cd /usr/src/suricata && \
    curl -L https://www.openinfosecfoundation.org/download/suricata-${SURICATA_VERSION}.tar.gz | tar xz --strip-components=1 && \
    ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var \
        --disable-lua \
        --disable-gccmarch-native \
        --disable-geoip \
        --disable-hiredis \
        --enable-rust \
        --enable-revision \
        --with-revision="8.0.0-release" && \
    make && \
    make install-full && \
    ldconfig || true

# Install suricata-update
RUN pip3 install --break-system-packages --upgrade pip && \
    pip3 install --break-system-packages suricata-update

# Runtime stage
FROM alpine:3.20

# Install runtime dependencies
RUN apk add --no-cache \
    libpcap \
    libnet \
    yaml \
    jansson \
    file \
    pcre2 \
    zlib \
    libcap \
    libcap-ng \
    openssl \
    python3 \
    py3-pip \
    py3-yaml \
    tcpdump \
    jq \
    libstdc++ \
    && rm -rf /var/cache/apk/*

# Copy from builder
COPY --from=builder /usr/bin/suricata /usr/bin/suricata
COPY --from=builder /usr/bin/suricatasc /usr/bin/suricatasc
COPY --from=builder /usr/bin/suricata-update /usr/bin/suricata-update
COPY --from=builder /etc/suricata /etc/suricata
COPY --from=builder /usr/lib/libhtp* /usr/lib/

# Copy Python packages needed for suricata-update
COPY --from=builder /usr/lib/python3.12/site-packages/suricata /usr/lib/python3.12/site-packages/suricata
COPY --from=builder /usr/lib/python3.12/site-packages/suricata_update-1.3.3.dist-info /usr/lib/python3.12/site-packages/suricata_update-1.3.3.dist-info
COPY --from=builder /usr/lib/python3.12/site-packages/yaml /usr/lib/python3.12/site-packages/yaml
COPY --from=builder /usr/lib/python3.12/site-packages/PyYAML-6.0.1.dist-info /usr/lib/python3.12/site-packages/PyYAML-6.0.1.dist-info
COPY --from=builder /usr/lib/python3.12/site-packages/_yaml /usr/lib/python3.12/site-packages/_yaml
COPY --from=builder /usr/lib/python3.12/site-packages/packaging /usr/lib/python3.12/site-packages/packaging
COPY --from=builder /usr/lib/python3.12/site-packages/packaging-24.0.dist-info /usr/lib/python3.12/site-packages/packaging-24.0.dist-info
COPY --from=builder /usr/lib/python3.12/site-packages/pyparsing /usr/lib/python3.12/site-packages/pyparsing
COPY --from=builder /usr/lib/python3.12/site-packages/pyparsing-3.1.2.dist-info /usr/lib/python3.12/site-packages/pyparsing-3.1.2.dist-info

# Create directories
RUN mkdir -p /var/log/suricata /var/run/suricata /etc/suricata/rules

# Copy configuration
COPY docker/config/suricata.yaml /etc/suricata/
COPY docker/config/rules/ /etc/suricata/rules/
COPY scripts/entrypoint.sh /usr/local/bin/
COPY scripts/healthcheck.sh /usr/local/bin/
COPY scripts/update-rules.sh /usr/local/bin/

# Set permissions
RUN setcap cap_net_raw,cap_net_admin=eip /usr/bin/suricata && \
    chmod +x /usr/local/bin/*.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

WORKDIR /etc/suricata
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["-i", "eth0"]
