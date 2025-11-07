#!/bin/bash
# 04_configure_https_service.sh - Configures SSL/TLS and Medusa config.

# --- Core Global Variables ---
LOG_FILE=$(cat /tmp/medusa_log_path.txt 2>/dev/null)
MEDUSA_ROOT="/opt/medusa/my-store"
HOST_NAME="api.medusa.vdev.com"
CERT_DIR="/etc/ssl/certs/medusa"
RUN_USER=$(cat /tmp/medusa_run_user.txt 2>/dev/null) # FIX: Read RUN_USER
# ... (other variables) ...
# ... (logging functions) ...
log() {
  local msg="$1"
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  printf '[%s] %s\n' "$ts" "$msg" | tee -a "$LOG_FILE" >&2
}
# --- Core Logic ---
log "--- [04/06] Starting Configuration and Service Setup Script ---"

if [ -z "$RUN_USER" ]; then error_exit "RUN_USER variable is empty. Did script 01 run successfully?"; fi

# 1. Create Self-Signed Certificate
# ... (certificate creation logic) ...

# 2. Configure Medusa Environment Variables (.env)
log "2. Configuring Medusa Environment Variables (.env)..."
# ... (env writing logic) ...

# 3. Add Host entry for local testing
log "3. Adding $HOST_NAME to /etc/hosts for local testing..."
# ... (hosts file logic) ...

log "--- [04/06] Configuration and Service Setup SUCCESSFUL. ---"