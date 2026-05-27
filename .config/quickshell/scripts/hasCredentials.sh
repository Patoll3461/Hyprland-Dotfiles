#!/bin/sh

# check-wifi.sh
# Usage: ./check-wifi.sh "SSID_NAME"

SSID="$1"

if [ -z "$SSID" ]; then
    echo "Usage: $0 <SSID>"
    exit 1
fi

# Check if a saved connection profile exists for this SSID
if nmcli connection show | grep -q "^$SSID"; then
    echo "true"
else
    echo "false"
fi
