# Build stage
FROM alpine:3.20 AS builder

RUN apk add --no-cache \
    build-base \
    autoconf \
    automake \
    libtool \
    pkgconf \
    flex \
    bison \
    libpcap-dev \
    libnet-dev \
    yaml-dev \
    jansson-dev \
    file-dev \
    pcre2-dev \
    zlib-dev \
    libcap-dev \
    libcap-ng-dev \
    openssl-dev \
    python3-dev \
    py3-pip \
    py3-yaml \
    git \
    curl \
    linux-headers \
    rust \
    cargo

# Install Suricata from source
# Using latest stable version 8.0.0 (July 2025)
ARG SURICATA_VERSION=8.0.0
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
COPY --from=builder /usr/lib/python3.12/site-packages/suricata* /usr/lib/python3.12/site-packages/

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
