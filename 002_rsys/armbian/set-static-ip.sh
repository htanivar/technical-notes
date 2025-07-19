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

# Function to validate IP
valid_ip() {
  [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  for octet in $(echo "$1" | tr '.' ' '); do
    [[ "$octet" -ge 0 && "$octet" -le 255 ]] || return 1
  done
  return 0
}

# Get STATIC_IP from env or prompt user
attempts=0
max_attempts=5

while ! valid_ip "$STATIC_IP"; do
  if [[ $attempts -ge $max_attempts ]]; then
    echo "❌ Exceeded maximum attempts. Exiting."
    exit 2
  fi
  read -p "Enter a valid static IP (e.g. 192.168.1.100): " STATIC_IP
  ((attempts++))
done

# Check if IP is already in use
echo "🔍 Checking if $STATIC_IP is in use..."
if ping -c 2 -W 1 "$STATIC_IP" &>/dev/null; then
  echo "❌ IP address $STATIC_IP is already in use."
  exit 3
fi

echo "✅ IP $STATIC_IP appears free. Applying static config..."

# Backup current config if any
[[ -f "$NETWORK_FILE" ]] && cp "$NETWORK_FILE" "${NETWORK_FILE}.bak.$(date +%s)"

# Write static config
cat > "$NETWORK_FILE" <<EOF
[Match]
Name=$INTERFACE

[Network]
Address=$STATIC_IP$CIDR
Gateway=$GATEWAY
DNS=$DNS
EOF

# Remove runtime-generated configs
rm -f /run/systemd/network/*${INTERFACE}*.network

# Restart networking
systemctl restart systemd-networkd
networkctl reconfigure "$INTERFACE"

# Show result
echo "🌐 New static IP applied to $INTERFACE:"
ip addr show "$INTERFACE"
