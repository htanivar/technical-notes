#!/bin/bash

# --- Function to get user input for IP addresses (with VM IP detection) and Password ---
get_input_data() {
    echo "--- PostgreSQL Setup Input ---"

    # 1. Get Password
    # Using read -s for silent input
    while true; do
        read -s -rp "Enter the desired password for the 'postgres' superuser: " PG_PASS
        echo
        if [[ -z "$PG_PASS" ]]; then
            echo "Password cannot be empty. Please try again."
        else
            break
        fi
    done

    # 2. Attempt to automatically determine the VM's primary IP address
    AUTO_VM_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')

    # 3. Get VM IP (Use auto-detected IP as default)
    read -rp "Enter the IP address of the VM (default: $AUTO_VM_IP): " VM_IP_INPUT

    if [[ -z "$VM_IP_INPUT" ]]; then
        if [[ -z "$AUTO_VM_IP" ]]; then
            echo "Error: Could not automatically determine VM IP. Please enter it manually."
            exit 1
        fi
        VM_IP="$AUTO_VM_IP"
    else
        VM_IP="$VM_IP_INPUT"
    fi

    # 4. Get Host/Remote IP
    read -rp "Enter the IP address of the host/remote server (e.g., 192.168.1.79): " HOST_IP
    if [[ -z "$HOST_IP" ]]; then
        echo "Host IP cannot be empty. Exiting."
        exit 1
    fi
}

# --- Execute Input Function ---
get_input_data

echo "VM IP used: $VM_IP"
echo "Host/Remote IP used: $HOST_IP"

# --- Install PostgreSQL ---
echo "--- Installing PostgreSQL ---"
sudo apt update
sudo apt install -y postgresql

# --- Get PostgreSQL Version ---
echo "--- Determining PostgreSQL Version ---"
if command -v psql &> /dev/null; then
    PGVER=$(psql -V | awk '{print $3}' | cut -d. -f1)
    echo "Detected PostgreSQL major version: $PGVER"
else
    echo "Error: psql command not found after installation. Exiting."
    exit 1
fi

# --- Set Superuser Password ---
echo "--- Setting Password for 'postgres' User ---"
# Execute psql command as the default 'postgres' system user
# The single quotes around the command ensure the password variable is properly handled.
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$PG_PASS';"

# --- Configure postgresql.conf (listen_addresses) ---
echo "--- Configuring postgresql.conf ---"

CONF_FILE="/etc/postgresql/$PGVER/main/postgresql.conf"
BACKUP_CONF_FILE="${CONF_FILE}.bak"

# Backup and edit
sudo cp "$CONF_FILE" "$BACKUP_CONF_FILE"
echo "Backup of $CONF_FILE created at $BACKUP_CONF_FILE"

# Set listen_addresses to localhost and the VM's IP
LISTEN_ADDRESSES="localhost, $VM_IP"
sudo sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '$LISTEN_ADDRESSES'/" "$CONF_FILE"
if ! grep -q "listen_addresses = '$LISTEN_ADDRESSES'" "$CONF_FILE"; then
    sudo sed -i "s/^#listen_addresses =.*/listen_addresses = '$LISTEN_ADDRESSES'/" "$CONF_FILE"
fi

echo "Updated listen_addresses to: $LISTEN_ADDRESSES"

# --- Configure pg_hba.conf (host access) ---
echo "--- Configuring pg_hba.conf ---"

HBA_FILE="/etc/postgresql/$PGVER/main/pg_hba.conf"
BACKUP_HBA_FILE="${HBA_FILE}.bak"

# Backup and edit
sudo cp "$HBA_FILE" "$BACKUP_HBA_FILE"
echo "Backup of $HBA_FILE created at $BACKUP_HBA_FILE"

# Add entry to allow access from the host/remote server.
HBA_ENTRY="host\tall\t\t\tall\t\t\t$HOST_IP/32\t\t\tmd5\t\t# Allow access from host/remote machine ($HOST_IP)"
sudo sed -i "\$a$HBA_ENTRY" "$HBA_FILE"

echo "Added the following entry to $HBA_FILE:"
echo "$HBA_ENTRY"

# --- Restart PostgreSQL and Check Status ---
echo "--- Restarting PostgreSQL Service ---"
sudo systemctl restart postgresql

echo "Waiting 10 seconds for the service to restart..."
sleep 10

echo "--- Checking PostgreSQL Service Status ---"
sudo systemctl status postgresql | grep 'Active:'

echo "--- Configuration Complete ---"