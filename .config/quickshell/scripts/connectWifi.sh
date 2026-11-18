#!/bin/bash

# Usage: ./connectWifi.sh <SSID> <PASSWORD> <SECURITY>
# SECURITY can be WPA2, WPA3, "WPA2 WPA3", or empty for open networks
# Mixed WPA2/WPA3 → fallback to WPA2 (wpa-psk)

SSID="$1"
PASSWORD="$2"
SECURITY="$3"

if [ -z "$SSID" ]; then
    echo "Error: SSID is required."
    exit 1
fi

# Determine key management type
KEY_MGMT=""
if [ -n "$SECURITY" ]; then
    case "$SECURITY" in
        "WPA2")
            KEY_MGMT="wpa-psk"
            ;;
        "WPA3")
            KEY_MGMT="sae"
            ;;
        "WPA2 WPA3"|"WPA3 WPA2")
            echo "Mixed WPA2/WPA3 detected, using fallback wpa-psk."
            KEY_MGMT="wpa-psk"
            ;;
        *)
            echo "Unknown security type '$SECURITY', using fallback wpa-psk."
            KEY_MGMT="wpa-psk"
            ;;
    esac
else
    # Empty security → open network
    KEY_MGMT=""
fi

# Remove existing connection if it exists
nmcli connection delete "$SSID" 2>/dev/null

# Add the connection
if [ -n "$PASSWORD" ]; then
    if [ -n "$KEY_MGMT" ]; then
        nmcli connection add type wifi con-name "$SSID" ssid "$SSID" wifi-sec.key-mgmt "$KEY_MGMT" wifi-sec.psk "$PASSWORD"
    else
        echo "Warning: password provided but security empty, trying open network anyway."
        nmcli connection add type wifi con-name "$SSID" ssid "$SSID"
    fi
else
    nmcli connection add type wifi con-name "$SSID" ssid "$SSID"
fi

# Bring up the connection
nmcli connection up "$SSID"

if [ $? -eq 0 ]; then
    echo "Successfully connected to $SSID"
else
    echo "Failed to connect to $SSID"
fi
