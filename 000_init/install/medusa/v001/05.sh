#!/bin/bash
# 05_start_medusa_service.sh - Configures and starts Medusa as a systemd service.

# --- Core Global Variables ---
LOG_FILE=$(cat /tmp/medusa_log_path.txt 2>/dev/null)
MEDUSA_ROOT="/opt/medusa/my-store"
RUN_USER=$(logname 2>/dev/null || whoami)
SERVICE_FILE="/etc/systemd/system/medusa.service"

# --- Logging Functions ---
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"; }
error_exit() { log "!!! FATAL ERROR: $1"; exit 1; }

# --- Core Logic ---
log "--- [05/06] Starting Medusa Service Script ---"

# 1. Create the systemd service file
log "1. Creating medusa.service file..."

# Create the service file content
sudo cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Medusa Backend Service
After=network.target postgresql.service redis-server.service

[Service]
# User/Group to run the service as (must match project owner: ravi)
User=$RUN_USER
Group=$RUN_USER
WorkingDirectory=$MEDUSA_ROOT

# The Medusa production start command
ExecStart=/usr/bin/npm start

# Environment variables (required for Node.js/Medusa to find its path)
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production

# Restart settings
Restart=always
RestartSec=5
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=medusa

[Install]
WantedBy=multi-user.target
EOF

log "   ✅ medusa.service created at $SERVICE_FILE."


# 2. Reload daemon, enable, and start service
log "2. Reloading systemd daemon, enabling, and starting service..."

# Reload systemd daemon to recognize the new service file
if sudo systemctl daemon-reload 2>>"$LOG_FILE"; then
    log "   Daemon reloaded."
else
    error_exit "Failed to reload systemd daemon."
fi

# Enable the service (ensures it starts on boot)
if sudo systemctl enable medusa 2>>"$LOG_FILE"; then
    log "   Service enabled."
else
    error_exit "Failed to enable Medusa service."
fi

# Start the service immediately
if sudo systemctl start medusa 2>>"$LOG_FILE"; then
    log "   ✅ Medusa service started successfully."
else
    # Output service status if startup fails for debugging
    sudo systemctl status medusa 2>&1 | tee -a "$LOG_FILE"
    error_exit "Failed to start Medusa service. Check status output above."
fi

log "--- [05/06] Medusa Service Setup SUCCESSFUL. ---"
exit 0