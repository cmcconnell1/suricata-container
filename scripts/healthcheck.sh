#!/bin/sh

# Check if Suricata process is running
if ! pgrep -x "suricata" > /dev/null; then
    echo "Suricata process not running"
    exit 1
fi

# Check if control socket is responding
if ! suricatasc -c uptime > /dev/null 2>&1; then
    echo "Suricata control socket not responding"
    exit 1
fi

# Check if logs are being written
if [ ! -f /var/log/suricata/fast.log ] || \
   [ ! -f /var/log/suricata/eve.json ]; then
    echo "Log files not being written"
    exit 1
fi

exit 0
