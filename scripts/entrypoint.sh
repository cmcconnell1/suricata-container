#!/bin/sh

set -e

# Handle version check specially
if [ "$1" = "--version" ] || [ "$1" = "-V" ]; then
    exec suricata -V
fi

# Initialize default values
INTERFACE=${INTERFACE:-eth0}
UPDATE_RULES=${UPDATE_RULES:-false}
LOG_LEVEL=${LOG_LEVEL:-info}

# Update rules if requested
if [ "$UPDATE_RULES" = "true" ]; then
    echo "Updating Suricata rules..."
    /usr/local/bin/update-rules.sh
fi

# Validate configuration (optional)
if [ "${SKIP_CONFIG_TEST:-false}" != "true" ]; then
    echo "Testing Suricata configuration..."
    if ! suricata -T -c /etc/suricata/suricata.yaml; then
        echo "WARNING: Configuration test failed, but continuing anyway"
        echo "Set SKIP_CONFIG_TEST=true to skip this test"
    else
        echo "Configuration test passed"
    fi
fi

# Start Suricata
echo "Starting Suricata on interface $INTERFACE with log level $LOG_LEVEL"
exec suricata -c /etc/suricata/suricata.yaml \
    --af-packet=$INTERFACE \
    --set logging.default-log-level=$LOG_LEVEL \
    "$@"
