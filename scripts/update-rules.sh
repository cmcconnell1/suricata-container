#!/bin/sh

set -e

echo "Starting rule update process..."

# Update rule sources
suricata-update update-sources

# Enable important rule sources
suricata-update enable-source et/open
suricata-update enable-source oisf/trafficid
suricata-update enable-source ptresearch/attackdetection

# Disable problematic rules
suricata-update disable-sid 2019406  # Example of disabling specific rule IDs
suricata-update disable-sid 2025855

# Perform the update
suricata-update

# Test the configuration with new rules
if ! suricata -T -c /etc/suricata/suricata.yaml; then
    echo "ERROR: Configuration test failed after rule update"
    exit 1
fi

echo "Rule update completed successfully"
