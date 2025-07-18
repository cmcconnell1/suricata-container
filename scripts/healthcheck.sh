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
# CONTROL SOCKET CHECK: Test Suricata's management interface
# -----------------------------------------------------------------------------
# Verify Suricata's control socket is responding to commands
# This ensures Suricata is not just running but actually functional
if ! suricatasc -c uptime > /dev/null 2>&1; then
    echo "HEALTH CHECK FAILED: Suricata control socket not responding"
    exit 1
fi

# -----------------------------------------------------------------------------
# LOG FILE CHECK: Ensure Suricata is writing logs
# -----------------------------------------------------------------------------
# Verify that Suricata is creating and writing to its log files
# This indicates that Suricata is actively processing traffic
if [ ! -f /var/log/suricata/fast.log ] || \
   [ ! -f /var/log/suricata/eve.json ]; then
    echo "HEALTH CHECK FAILED: Log files not being written"
    exit 1
fi

# -----------------------------------------------------------------------------
# SUCCESS: All health checks passed
# -----------------------------------------------------------------------------
echo "HEALTH CHECK PASSED: Suricata is running and healthy"
exit 0
