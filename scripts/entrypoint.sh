#!/bin/sh
# =============================================================================
# SURICATA CONTAINER ENTRYPOINT SCRIPT
# =============================================================================
# This script handles container startup, configuration validation, and
# Suricata process initialization with proper error handling.
#
# Environment Variables:
# - INTERFACE: Network interface to monitor (default: eth0)
# - UPDATE_RULES: Whether to update rules on startup (default: false)
# - LOG_LEVEL: Suricata logging verbosity (default: info)
# - SKIP_CONFIG_TEST: Skip configuration validation (default: false)
#
# Usage:
#   docker run suricata                    # Start with defaults
#   docker run -e INTERFACE=eth1 suricata # Use specific interface
#   docker run suricata --version         # Show version and exit
# =============================================================================

# Exit immediately if any command fails
set -e

# -----------------------------------------------------------------------------
# SPECIAL COMMAND HANDLING: Version checks and shell access
# -----------------------------------------------------------------------------
# Handle version check requests (both --version and -V flags)
if [ "$1" = "--version" ] || [ "$1" = "-V" ]; then
    # Use -V flag for version check (Suricata's correct version flag)
    exec suricata -V
fi

# Handle shell commands for debugging/testing
if [ "$1" = "/bin/sh" ] || [ "$1" = "sh" ]; then
    exec "$@"
fi

# -----------------------------------------------------------------------------
# ENVIRONMENT VARIABLE INITIALIZATION: Set defaults for configuration
# -----------------------------------------------------------------------------
# Network interface to monitor (can be overridden via environment)
INTERFACE=${INTERFACE:-eth0}
# Whether to update rules on container startup
UPDATE_RULES=${UPDATE_RULES:-false}
# Suricata logging verbosity level
LOG_LEVEL=${LOG_LEVEL:-info}

# -----------------------------------------------------------------------------
# RULE MANAGEMENT: Update Suricata rules if requested
# -----------------------------------------------------------------------------
# Update rules if requested via environment variable
if [ "$UPDATE_RULES" = "true" ]; then
    echo "Updating Suricata rules..."
    /usr/local/bin/update-rules.sh
fi

# -----------------------------------------------------------------------------
# CONFIGURATION VALIDATION: Test Suricata configuration before starting
# -----------------------------------------------------------------------------
# Validate configuration unless explicitly skipped
if [ "${SKIP_CONFIG_TEST:-false}" != "true" ]; then
    echo "Testing Suricata configuration..."
    if ! suricata -T -c /etc/suricata/suricata.yaml; then
        echo "WARNING: Configuration test failed, but continuing anyway"
        echo "Set SKIP_CONFIG_TEST=true to skip this test"
    else
        echo "Configuration test passed"
    fi
fi

# -----------------------------------------------------------------------------
# SURICATA STARTUP: Launch Suricata with configured parameters
# -----------------------------------------------------------------------------
# Start Suricata with AF_PACKET mode for high-performance packet capture
echo "Starting Suricata on interface $INTERFACE with log level $LOG_LEVEL"
exec suricata -c /etc/suricata/suricata.yaml \
    --af-packet=$INTERFACE \
    --set logging.default-log-level=$LOG_LEVEL \
    "$@"
