#!/bin/bash
# 02_configure_db.sh

# --- Core Global Variables (Must match 01) ---
LOG_FILE=$(cat /tmp/medusa_log_path.txt 2>/dev/null)
MEDUSA_ROOT="/opt/medusa/my-store"
CERT_DIR="/etc/ssl/certs/medusa"
TEMP_ROLLBACK_FILE="/tmp/medusa_new_packages.txt"
DB_USER="medusa_user"
DB_PASS="medusa_password"
DB_NAME="medusa_db"

# --- Logging Functions ---
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"; }
error_exit() { log "!!! FATAL ERROR: $1"; exit 1; } # Simple exit for subsequent scripts, rollback relies on 01's TEMP_ROLLBACK_FILE

# --- Core Logic ---
log "--- [02/06] Starting Database Configuration Script ---"

# 1. Start and enable services
log "1. Starting and enabling PostgreSQL and Redis services..."
sudo systemctl start postgresql 2>>"$LOG_FILE" && sudo systemctl enable postgresql 2>>"$LOG_FILE" || error_exit "PostgreSQL service management failed."
sudo systemctl start redis-server 2>>"$LOG_FILE" && sudo systemctl enable redis-server 2>>"$LOG_FILE" || error_exit "Redis service management failed."

# 2. Create PostgreSQL User and Database
log "2. Creating PostgreSQL user ($DB_USER) and database ($DB_NAME)..."
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_user WHERE usename = '$DB_USER'" | grep -q 1; then
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';" 2>>"$LOG_FILE" || error_exit "DB user creation failed."
else log "   DB user $DB_USER already exists. Skipping creation."; fi

if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1; then
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" 2>>"$LOG_FILE" || error_exit "DB creation failed."
else log "   Database $DB_NAME already exists. Skipping creation."; fi

log "   ✅ DB setup complete."
log "--- [02/06] Database Configuration SUCCESSFUL. ---"
exit 0