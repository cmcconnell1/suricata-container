#!/bin/sh
# =============================================================================
# SURICATA RULE UPDATE SCRIPT
# =============================================================================
# This script manages Suricata rule updates using the suricata-update tool.
# It downloads the latest threat detection rules from various sources and
# applies them to the Suricata configuration.
#
# Rule Sources:
# - ET Open: Emerging Threats open source rules
# - OISF Traffic ID: Official Suricata traffic identification rules
# - PT Research: Positive Technologies attack detection rules
#
# Process:
# 1. Update rule source definitions
# 2. Enable trusted rule sources
# 3. Disable problematic rules (if any)
# 4. Download and apply rule updates
# 5. Validate configuration with new rules
#
# Usage:
#   ./update-rules.sh                    # Manual execution
#   UPDATE_RULES=true docker run ...    # Automatic on container start
# =============================================================================

# Exit immediately if any command fails
set -e

echo "Starting Suricata rule update process..."

# -----------------------------------------------------------------------------
# RULE SOURCE MANAGEMENT: Update available rule source definitions
# -----------------------------------------------------------------------------
# Download the latest list of available rule sources
echo "Updating rule source definitions..."
suricata-update update-sources

# -----------------------------------------------------------------------------
# RULE SOURCE ACTIVATION: Enable trusted and reliable rule sources
# -----------------------------------------------------------------------------
# Enable Emerging Threats Open rules (free, community-maintained)
echo "Enabling ET Open rules..."
suricata-update enable-source et/open

# Enable OISF Traffic ID rules (official Suricata project rules)
echo "Enabling OISF Traffic ID rules..."
suricata-update enable-source oisf/trafficid

# Enable PT Research attack detection rules (advanced threat detection)
echo "Enabling PT Research rules..."
suricata-update enable-source ptresearch/attackdetection

# -----------------------------------------------------------------------------
# RULE FILTERING: Disable problematic or noisy rules
# -----------------------------------------------------------------------------
# Disable specific rule IDs that may cause false positives or performance issues
echo "Disabling problematic rules..."
suricata-update disable-sid 2019406  # Example: Disable specific rule ID
suricata-update disable-sid 2025855  # Example: Disable another rule ID

# -----------------------------------------------------------------------------
# RULE UPDATE EXECUTION: Download and apply rule updates
# -----------------------------------------------------------------------------
# Perform the actual rule update (download, merge, and install)
echo "Downloading and applying rule updates..."
suricata-update

# -----------------------------------------------------------------------------
# CONFIGURATION VALIDATION: Test configuration with new rules
# -----------------------------------------------------------------------------
# Verify that Suricata can load the new rules without errors
echo "Validating configuration with new rules..."
if ! suricata -T -c /etc/suricata/suricata.yaml; then
    echo "ERROR: Configuration test failed after rule update"
    echo "New rules may be incompatible or contain syntax errors"
    exit 1
fi

echo "Rule update completed successfully - Suricata is ready with latest rules"
