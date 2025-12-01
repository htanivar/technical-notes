#!/bin/bash
# 05_start_medusa_service.sh - Configures and starts Medusa as a systemd service.

# --- Core Global Variables ---
LOG_FILE=$(cat /tmp/medusa_log_path.txt 2>/dev/null)
MEDUSA_ROOT="/opt/medusa/my-store"
RUN_USER=$(cat /tmp/medusa_run_user.txt 2>/dev/null) # FIX: Read RUN_USER
SERVICE_FILE="/etc/systemd/system/medusa.service"
DB_USER="medusa_user"
DB_PASS="medusa_password"
DB_NAME="medusa_db"
# ... (logging functions) ...

# --- Core Logic ---
log "--- [05/06] Starting Medusa Service Script ---"

if [ -z "$RUN_USER" ]; then error_exit "RUN_USER variable is empty. Did script 01 run successfully?"; fi

# 1. Create the systemd service file
log "1. Creating medusa.service file with fixes..."

sudo cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Medusa Backend Service
After=network.target postgresql.service redis-server.service

[Service]
Type=simple
User=$RUN_USER
Group=$RUN_USER
WorkingDirectory=$MEDUSA_ROOT

# CRITICAL FIX: Explicitly set DATABASE_URL environment variable
Environment="DATABASE_URL=postgres://$DB_USER:$DB_PASS@localhost/$DB_NAME"
Environment="NODE_ENV=production"

# CRITICAL FIX: Use 'npx medusa start' instead of 'npm start'
ExecStart=/usr/bin/npx medusa start

Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=medusa

[Install]
WantedBy=multi-user.target
EOF

log "   ✅ medusa.service created with all fixes."


# 2. Reload daemon, enable, and start service
log "2. Reloading systemd daemon, enabling, and starting service..."
if sudo systemctl daemon-reload 2>>"$LOG_FILE"; then
    log "   Daemon reloaded."
else
    error_exit "Failed to reload systemd daemon."
fi

if sudo systemctl enable medusa 2>>"$LOG_FILE"; then
    log "   Service enabled."
else
    error_exit "Failed to enable Medusa service."
fi

log "3. Starting the Medusa service..."
if sudo systemctl start medusa 2>>"$LOG_FILE"; then
    log "   ✅ Medusa service start command executed successfully."
else
    sudo systemctl status medusa 2>&1 | tee -a "$LOG_FILE"
    error_exit "Failed to start Medusa service. Check status output above."
fi

log "--- [05/06] Medusa Service Setup SUCCESSFUL. ---"