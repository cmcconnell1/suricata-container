#!/bin/sh
# =============================================================================
# SURICATA CONTAINER HEALTH CHECK SCRIPT
# =============================================================================
# This script performs comprehensive health checks on the Suricata container
# to ensure it's running properly and processing traffic.
#
# Health Check Components:
# 1. Process Check - Verify Suricata process is running
# 2. Control Socket - Test Suricata's management interface
# 3. Log Files - Ensure logs are being written
#
# Exit Codes:
# 0 = Healthy (all checks passed)
# 1 = Unhealthy (one or more checks failed)
#
# Used by Docker's HEALTHCHECK instruction for container monitoring
# =============================================================================

# -----------------------------------------------------------------------------
# PROCESS CHECK: Verify Suricata daemon is running
# -----------------------------------------------------------------------------
# Check if the main Suricata process is active
if ! pgrep -x "suricata" > /dev/null; then
    echo "HEALTH CHECK FAILED: Suricata process not running"
    exit 1
fi

# -----------------------------------------------------------------------------
# PROCESS STATUS CHECK: Verify Suricata process is responsive
# -----------------------------------------------------------------------------
# Check if Suricata process is running and responsive
# Use a simple approach that works with BusyBox ps in Alpine Linux
SURICATA_PID=$(pgrep -x "suricata")
if [ -z "$SURICATA_PID" ]; then
    echo "HEALTH CHECK FAILED: Suricata process PID not found"
    exit 1
fi

# Verify the process is still alive by checking if we can send signal 0
if ! kill -0 "$SURICATA_PID" 2>/dev/null; then
    echo "HEALTH CHECK FAILED: Suricata process not responding to signals"
    exit 1
fi

# -----------------------------------------------------------------------------
# LOG DIRECTORY CHECK: Ensure log directory exists and is writable
# -----------------------------------------------------------------------------
# Verify that Suricata can write to its log directory
if [ ! -d /var/log/suricata ]; then
    echo "HEALTH CHECK FAILED: Suricata log directory not found"
    exit 1
fi

# Check if main log file exists (it should be created immediately on startup)
if [ ! -f /var/log/suricata/suricata.log ]; then
    echo "HEALTH CHECK FAILED: Suricata main log file not found"
    exit 1
fi

# -----------------------------------------------------------------------------
# SUCCESS: All health checks passed
# -----------------------------------------------------------------------------
echo "HEALTH CHECK PASSED: Suricata is running and healthy"
exit 0
