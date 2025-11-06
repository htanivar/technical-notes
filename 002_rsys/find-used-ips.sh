#!/bin/bash
# Script to find all used IPs and gather info about them on the local network.
# Output is presented in a readable Markdown table.

# --- Configuration ---
INTERFACE="" # Leave empty to auto-detect
MAX_PARALLEL_JOBS=10
# ---------------------

# Array to store results for later table generation
declare -a SCAN_RESULTS=()

echo "🚀 Starting Local Network IP Scan..."

# Function to get network details (Network Address and CIDR)
get_network_details() {
    if [ -z "$INTERFACE" ]; then
        INTERFACE=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
        if [ -z "$INTERFACE" ]; then
            echo "❌ Could not automatically detect the default network interface." >&2
            echo "Please set the 'INTERFACE' variable manually (e.g., INTERFACE=\"wlan0\")." >&2
            exit 1
        fi
    fi

    IP_ADDR_CIDR=$(ip addr show dev "$INTERFACE" 2>/dev/null | grep 'inet ' | awk '{print $2}' | head -1)

    if [ -z "$IP_ADDR_CIDR" ]; then
        echo "❌ Could not find an IP address for interface '$INTERFACE'. Check interface name." >&2
        exit 1
    fi

    if command -v ipcalc &> /dev/null; then
        NETWORK_ADDR=$(ipcalc -n "$IP_ADDR_CIDR" 2>/dev/null | grep 'Network:' | awk '{print $2}')
    fi

    if [ -z "$NETWORK_ADDR" ]; then
        NETWORK_BASE=$(echo "$IP_ADDR_CIDR" | cut -d '.' -f 1-3)
        NETWORK_ADDR="${NETWORK_BASE}.0/24"
    fi

    echo "🌐 Interface: **$INTERFACE**"
    echo "🏠 Local IP/Mask: **$IP_ADDR_CIDR**"
    echo "📡 Network Range: **$NETWORK_ADDR**"
    echo ""
}

# Your original IP check logic, now simplified to gather data
check_ip_details() {
    local IP="$1"
    local MAC=""
    local HOSTNAME=""
    local NETBIOS=""
    local OPEN_PORTS_SUMMARY=""
    local VENDOR=""
    local LEASE_INFO="N/A"

    # 1. ARP table lookup for MAC
    MAC=$(ip neigh show "$IP" 2>/dev/null | awk '{print $5}')
    if [ -n "$MAC" ] && [ "$MAC" != "FAILED" ] && [ "$MAC" != "00:00:00:00:00:00" ]; then
        # Try to identify vendor
        if command -v curl &> /dev/null; then
            VENDOR_RAW=$(curl -s "https://api.macvendors.com/$MAC" 2>/dev/null)
            if [ -n "$VENDOR_RAW" ] && [ "$VENDOR_RAW" != "Not Found" ]; then
                VENDOR=$(echo "$VENDOR_RAW" | head -n 1 | sed 's/[^a-zA-Z0-9 ]//g' | awk '{print $1}') # Get first word
            fi
        fi
    else
        MAC="N/A"
    fi

    # 2. Hostname lookup
    HOSTNAME=$(host "$IP" 2>/dev/null | grep "domain name pointer" | awk '{print $NF}' | sed 's/\.$//' | head -n 1)
    [ -z "$HOSTNAME" ] && HOSTNAME="N/A"

    # 3. Port scan (common ports summary)
    if command -v nmap &> /dev/null; then
        # Use nmap to find all open ports quickly
        OPEN_PORTS=$(sudo nmap -F -T4 "$IP" -n -Pn 2>/dev/null | grep 'open' | awk -F'/' '{print $1}' | tr '\n' ',' | sed 's/,$//')
        [ -z "$OPEN_PORTS" ] && OPEN_PORTS_SUMMARY="None" || OPEN_PORTS_SUMMARY="${OPEN_PORTS}"
    else
        # Basic check for a few ports
        COMMON_PORTS=(22 80 443)
        OPEN_PORTS=""
        for port in "${COMMON_PORTS[@]}"; do
            if timeout 0.5 bash -c "echo >/dev/tcp/$IP/$port" 2>/dev/null; then
                OPEN_PORTS+="$port,"
            fi
        done
        OPEN_PORTS_SUMMARY=$(echo "$OPEN_PORTS" | sed 's/,$//')
        [ -z "$OPEN_PORTS_SUMMARY" ] && OPEN_PORTS_SUMMARY="None"
    fi

    # 4. NetBIOS/SMB name
    if command -v nmblookup &> /dev/null; then
        NETBIOS=$(nmblookup -A "$IP" 2>/dev/null | grep '<00>' | grep -v GROUP | head -1 | awk '{print $1}')
    fi
    [ -z "$NETBIOS" ] && NETBIOS="N/A"

    # 5. Check DHCP leases (simple check for existence)
    if [ -f /var/lib/dhcp/dhcpd.leases ] && grep -q "lease $IP" /var/lib/dhcp/dhcpd.leases 2>/dev/null; then
        LEASE_INFO="DHCPD"
    elif [ -f /var/lib/misc/dnsmasq.leases ] && grep -q "$IP" /var/lib/misc/dnsmasq.leases 2>/dev/null; then
        LEASE_INFO="DNSMASQ"
    fi

    # Format the combined result string
    local RESULT_STRING="$IP|$MAC|$VENDOR|$HOSTNAME|$NETBIOS|$OPEN_PORTS_SUMMARY|$LEASE_INFO"
    SCAN_RESULTS+=("$RESULT_STRING")

    # Clear line on progress (to keep the output clean)
    echo -ne "Scanning $IP... Done. \r"
}

# Function to generate the final table
generate_table() {
    echo ""
    echo "## 📊 Scan Results Summary"
    echo "---"

    if [ ${#SCAN_RESULTS[@]} -eq 0 ]; then
        echo "No active hosts were found on the network."
        return
    fi

    # Print the table header
    echo "| IP Address | MAC Address | Vendor | Hostname (DNS) | NetBIOS Name | Open Ports (Common) | Lease Type |"
    echo "| :--- | :--- | :--- | :--- | :--- | :--- | :--- |"

    # Print the data rows
    for RESULT in "${SCAN_RESULTS[@]}"; do
        echo "| ${RESULT//|/ \| } |"
    done
    echo "---"
    echo "Note: The Hostname (DNS) and NetBIOS Name fields may be empty if the host doesn't respond to those queries."
}

# --- Main Execution ---

get_network_details

# 1. ARP Ping Sweep (Fast discovery of live hosts)
echo "🔍 Performing quick ARP Ping Sweep (This may take a moment)..."

if command -v nmap &> /dev/null; then
    # Run nmap once to populate the ARP cache for all hosts
    sudo nmap -sn -PR -T4 "$NETWORK_ADDR" -n -Pn > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "⚠️ nmap failed or requires sudo. Proceeding with simple ping loop."
    fi
else
    echo "⚠️ nmap is not installed. Falling back to a slower ping loop."
    # Fallback ping loop to populate cache
    NETWORK_BASE=$(echo "$NETWORK_ADDR" | cut -d '.' -f 1-3)
    for i in $(seq 1 254); do
        ping -c 1 -W 1 "${NETWORK_BASE}.${i}" > /dev/null 2>&1 &
        while [ $(jobs -r | wc -l) -ge $MAX_PARALLEL_JOBS ]; do sleep 0.1; done
    done
    wait
fi

# 2. Get list of live IPs from ARP cache
echo ""
echo "✅ Discovery complete. Retrieving live hosts from ARP table..."
# Get active IPs from the ARP table
LIVE_HOSTS_ARP=$(ip neigh show | awk '/REACHABLE|STALE|DELAY|PERMANENT/ {print $1}' | grep -E "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$" | sort -u)

# Get the local IP address found earlier
LOCAL_IP=$(echo "$IP_ADDR_CIDR" | cut -d '/' -f 1)

# Combine the local IP with the discovered IPs, and ensure uniqueness
LIVE_HOSTS=$(echo "$LIVE_HOSTS_ARP $LOCAL_IP" | tr ' ' '\n' | sort -u)


if [ -z "$LIVE_HOSTS" ]; then
    echo "❌ No active hosts found (excluding self)."
    generate_table
    exit 0
fi

HOST_COUNT=$(echo "$LIVE_HOSTS" | wc -l)
echo "Found **$HOST_COUNT** potentially active host(s). Starting detailed scan..."

# Check if the host count is correct after adding self
if [ "$HOST_COUNT" -eq 1 ]; then
    echo "   (Only the local host was found.)"
fi
echo "---"

# 3. Process each live host with the detailed check
for IP in $LIVE_HOSTS; do
    # Check if we should wait for a background job to finish
    while [ $(jobs -r | wc -l) -ge $MAX_PARALLEL_JOBS ]; do
        sleep 0.5
    done

    # Run the detailed check in the background
    check_ip_details "$IP" &
done

# Wait for all background checks to finish
wait
echo -ne "\n" # Move cursor down after progress messages

# 4. Generate the final table
generate_table

echo "🎉 All detailed scans completed."