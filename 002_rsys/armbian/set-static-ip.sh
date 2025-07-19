#!/bin/bash

# Must run as root
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ This script must be run as root." >&2
  exit 1
fi

INTERFACE="wlan0"
CIDR="/24"
GATEWAY="192.168.1.1"
DNS="8.8.8.8"
NETWORK_FILE="/etc/systemd/network/10-${INTERFACE}-static.network"

# Function to validate IP format
function valid_ip() {
  [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] &&
  for i in $(echo "$1" | tr '.' ' '); do
    [[ $i -ge 0 && $i -le 255 ]] || return 1
  done
}

# Prompt for STATIC_IP if not set or invalid
attempt=0
max_attempts=5

while ! valid_ip "$STATIC_IP"; do
  if [[ $attempt -ge $max_attempts ]]; then
    echo "❌ Exceeded $max_attempts invalid attempts. Exiting."
    exit 2
  fi
  read -p "Enter static IP address (e.g., 192.168.1.100): " STATIC_IP
  if ! valid_ip "$STATIC_IP"; then
    echo "⚠️  Invalid IP format."
  fi
  ((attempt++))
done

# Check if IP is already in use
echo "🔍 Checking if $STATIC_IP is already in use..."
if ping -c 2 -W 1 "$STATIC_IP" &>/dev/null; then
  echo "❌ IP address $STATIC_IP is already in use on the network."
  exit 3
fi

echo "✅ IP $STATIC_IP appears free. Applying config..."

# Backup existing config
[[ -f "$NETWORK_FILE" ]] && cp "$NETWORK_FILE" "${NETWORK_FILE}.bak.$(date +%s)"

# Write static IP config
cat > "$NETWORK_FILE" <<EOF
[Match]
Name=$INTERFACE

[Network]
Address=$STATIC_IP$CIDR
Gateway=$GATEWAY
DNS=$DNS
EOF

# Remove conflicting configs
rm -f /etc/systemd/network/*${INTERFACE}*.network~

# Restart network
systemctl restart systemd-networkd

# Show result
echo "🌐 Assigned static IP $STATIC_IP to $INTERFACE"
ip addr show $INTERFACE

