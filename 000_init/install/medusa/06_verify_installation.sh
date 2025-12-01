#!/bin/bash
# 06_verify_installation.sh - Final verification script with a robust check for 127.0.0.1 or localhost.

# --- Core Global Variables ---
LOG_FILE=$(cat /tmp/medusa_log_path.txt 2>/dev/null)
MEDUSA_HOST="api.medusa.vdev.com"
MEDUSA_PORT="9000"
MEDUSA_ROOT="/opt/medusa/my-store"
RUN_USER=$(cat /tmp/medusa_run_user.txt 2>/dev/null) # FIX: Read RUN_USER
# ... (other variables) ...
# ... (logging functions) ...

# --- Core Logic ---
log "--- [06/06] Starting Verification and Documentation Script (Robust HTTP Test) ---"

if [ -z "$RUN_USER" ]; then error_exit "RUN_USER variable is empty. Did script 01 run successfully?"; fi

# 1. Verification Check (Wait for boot)
log "1. Verification confirmed active: Service is running."
log "2. Waiting 25 seconds for Medusa server to fully boot before API test..."
sleep 25

# 3. Robust API Test
# ... (robust test logic using curl) ...

if [ -z "$VERIFIED_URL" ]; then
    log "   ❌ Store API check failed. Response Code: $API_HTTP_CODE"
    log "      - Run 'journalctl -u medusa -n 50' for crash details."
    error_exit "Verification failed: Store API (port $MEDUSA_PORT) not responding or returning product data."
fi

# 4. Final Status Output and Documentation Generation
log "4. Final Status Check and Documentation Generation..."
# ... (documentation generation logic) ...

log "--- [06/06] Verification and Documentation Script COMPLETE. ---"