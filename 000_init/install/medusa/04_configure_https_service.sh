#!/bin/bash
# 04_configure_https_service.sh - Configures SSL/TLS and Medusa config.

# --- Core Global Variables ---
# FIX: Read LOG_FILE from temporary file, solving the 'tee' error.
LOG_FILE=$(cat /tmp/medusa_log_path.txt 2>/dev/null)
MEDUSA_ROOT="/opt/medusa/my-store"
HOST_NAME="api.medusa.vdev.com"
CERT_DIR="/etc/ssl/certs/medusa"

# DB credentials needed for .env file (assuming they are correct)
DB_USER="medusa_user"
DB_PASS="medusa_password"
DB_NAME="medusa_db"

# User who owns the project files (ravi)
RUN_USER=$(logname 2>/dev/null || whoami)

# --- Logging Functions ---
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"; }
error_exit() { log "!!! FATAL ERROR: $1"; exit 1; }

# --- Core Logic ---
log "--- [04/06] Starting Configuration and Service Setup Script ---"

# 1. Create Self-Signed Certificate
log "1. Creating private key and self-signed certificate for $HOST_NAME..."
sudo mkdir -p "$CERT_DIR"

if sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$CERT_DIR/medusa.key" \
    -out "$CERT_DIR/medusa.crt" \
    -subj "/C=US/ST=State/L=City/O=MedusaDev/CN=$HOST_NAME" 2>>"$LOG_FILE"; then
    log "   ✅ Certificate and Key created."
else
    error_exit "Failed to create SSL certificate/key."
fi

# 2. Configure Medusa Environment Variables (.env)
log "2. Configuring Medusa Environment Variables (.env)..."

# Ensure the .env file exists and is owned by the user
if [ ! -f "$MEDUSA_ROOT/.env" ]; then
    sudo -u "$RUN_USER" touch "$MEDUSA_ROOT/.env"
fi

# FIX: Write all essential production variables to the .env file
sudo -u "$RUN_USER" bash -c "cat > \"$MEDUSA_ROOT/.env\" <<EOF
# --- Required Database Configuration ---
DATABASE_URL=postgres://$DB_USER:$DB_PASS@localhost/$DB_NAME

# --- Server Configuration ---
PORT=9000
HOST=$HOST_NAME

# --- CORS and Secrets ---
# Use the configured hostname for secure CORS
STORE_CORS=https://$HOST_NAME
ADMIN_CORS=http://localhost:7001
AUTH_CORS=
# Generate random 32-character secrets for security
JWT_SECRET=\$(openssl rand -hex 32)
COOKIE_SECRET=\$(openssl rand -hex 32)

# --- SSL/TLS Configuration for Medusa Service (Used in Step 5) ---
NODE_ENV=production
MEDUSA_TLS_KEY_PATH=$CERT_DIR/medusa.key
MEDUSA_TLS_CERT_PATH=$CERT_DIR/medusa.crt

# --- Redis for Production (Assumed local Redis is running) ---
REDIS_URL=redis://localhost:6379
EOF" 2>>"$LOG_FILE" || error_exit "Failed to write .env file."
log "   ✅ Environment variables configured in $MEDUSA_ROOT/.env."

# 3. Add Host entry for local testing
log "3. Adding $HOST_NAME to /etc/hosts for local testing..."
if ! grep -q "127.0.0.1 $HOST_NAME" /etc/hosts; then
    # Use sudo echo with bash -c for permission to write to /etc/hosts
    sudo bash -c "echo \"127.0.0.1 $HOST_NAME\" >> /etc/hosts"
    log "   ✅ Host entry added."
else
    log "   ✅ Host entry already present."
fi

log "--- [04/06] Configuration and Service Setup SUCCESSFUL. ---"
exit 0