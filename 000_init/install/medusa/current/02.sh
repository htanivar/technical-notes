#!/bin/bash
# 02_configure_db.sh - Unified script for PostgreSQL/Redis setup and remote access configuration.

set -euo pipefail

# --- Core Global Variables ---
LOG_FILE=$(cat /tmp/medusa_log_path.txt 2>/dev/null || echo "$(pwd)/medusa_db_$(date +%Y%m%d_%H%M%S).log")
DB_USER="medusa_user"
DB_PASS="medusa_password"
DB_NAME="medusa_db"

log() {
  local msg="$1"
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  printf '[%s] %s\n' "$ts" "$msg" | tee -a "$LOG_FILE" >&2
}
log_cmd() {
  echo "CMD Issued: $1" | tee -a "$LOG_FILE" >&2
}
error_exit() {
  log "ERROR: $1"
  exit 1
}

log "--- [02/06] Starting Database Configuration Script ---"

# Prompt for VM IP, auto-detect if blank
read -p "Enter the VM IP address (leave blank to auto-detect): " VM_IP
if [ -z "$VM_IP" ]; then
  VM_IP=$(hostname -I | awk '{print $1}')
  log "   Auto-detected VM IP: $VM_IP"
else
  log "   Using provided VM IP: $VM_IP"
fi

# Prompt for Host IP, skip if blank
read -p "Enter the Host IP address to allow DB access (leave blank to skip remote access): " HOST_IP
if [ -z "$HOST_IP" ]; then
  log "   No Host IP provided, skipping remote access configuration."
else
  log "   Will allow DB access from host IP: $HOST_IP"
fi

# 1. Start and enable PostgreSQL and Redis services
log "1. Starting and enabling PostgreSQL and Redis services..."
log_cmd "sudo systemctl start postgresql && sudo systemctl enable postgresql"
sudo systemctl start postgresql 2>>"$LOG_FILE" && sudo systemctl enable postgresql 2>>"$LOG_FILE" || error_exit "PostgreSQL service management failed."
log_cmd "sudo systemctl start redis-server && sudo systemctl enable redis-server"
sudo systemctl start redis-server 2>>"$LOG_FILE" && sudo systemctl enable redis-server 2>>"$LOG_FILE" || error_exit "Redis service management failed."
log "   ✅ Services started."

# 2. Create PostgreSQL user and database
log "2. Creating PostgreSQL user ($DB_USER) and database ($DB_NAME)..."
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_user WHERE usename = '$DB_USER'" | grep -q 1; then
    log_cmd "sudo -u postgres psql -c \"CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';\""
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';" 2>>"$LOG_FILE" || error_exit "DB user creation failed."
else
    log "   DB user $DB_USER already exists. Skipping creation."
fi

if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1; then
    log_cmd "sudo -u postgres psql -c \"CREATE DATABASE $DB_NAME OWNER $DB_USER;\""
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" 2>>"$LOG_FILE" || error_exit "DB creation failed."
else
    log "   Database $DB_NAME already exists. Skipping creation."
fi

log "   ✅ DB setup complete."

# 3. Configure PostgreSQL for remote access if HOST_IP is provided
if [ -n "$HOST_IP" ]; then
  log "3. Configuring PostgreSQL for remote access..."

  # Find postgresql.conf and pg_hba.conf
  PG_CONF=$(sudo -u postgres psql -t -P format=unaligned -c "SHOW config_file;")
  PG_HBA=$(dirname "$PG_CONF")/pg_hba.conf

  # Allow listening on all interfaces
  log_cmd "sudo sed -i \"s/^#listen_addresses =.*/listen_addresses = '*'/'\" \"$PG_CONF\""
  sudo sed -i "s/^#listen_addresses =.*/listen_addresses = '*'/" "$PG_CONF"

  # Add host rule for the provided HOST_IP
  log_cmd "echo 'host    all    all    $HOST_IP/32    md5' | sudo tee -a $PG_HBA"
  echo "host    all    all    $HOST_IP/32    md5" | sudo tee -a "$PG_HBA"

  # Restart PostgreSQL to apply changes
  log_cmd "sudo systemctl restart postgresql"
  sudo systemctl restart postgresql 2>>"$LOG_FILE" || error_exit "PostgreSQL restart failed."

  # Confirm PostgreSQL is running
  log_cmd "systemctl is-active --quiet postgresql"
  if systemctl is-active --quiet postgresql; then
    log "✅ PostgreSQL is running."
  else
    error_exit "PostgreSQL is NOT running after restart."
  fi

  log "   ✅ Remote access configured for $HOST_IP."
else
  log "   Skipping remote access configuration."
fi

log "--- [02/06] Database Configuration SUCCESSFUL. ---"