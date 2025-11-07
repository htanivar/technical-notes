#!/bin/bash
# 01_install_dependencies.sh - Installs all necessary OS dependencies and Node.js.

set -euo pipefail

# --- Core Global Variables ---
LOG_FILE="$(pwd)/medusa_installation_$(date +%Y%m%d_%H%M%S).log"
MEDUSA_ROOT="/opt/medusa/my-store"
sudo chown $USER:$USER /tmp/medusa_node_version.txt
# ... other variables ...

# --- Helper functions ---
log() {
  local msg="$1"
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  printf '[%s] %s\n' "$ts" "$msg" | tee -a "$LOG_FILE" >&2
}
error_exit() {
  local msg="${1:-Unknown error}"
  log "ERROR: $msg"
  exit 1
}
# ------------------------

# --- User Input & Global Variables Setup ---
read -p "Enter the desired Node.js version (e.g., 20.x or 18.x). Default is 20.x: " NODE_VERSION
NODE_VERSION=${NODE_VERSION:-20.x}

# CRITICAL FIX: Determine the non-root user and save global variables
RUN_USER=$(logname 2>/dev/null || whoami)
if [ "$RUN_USER" = "root" ] || [ -z "$RUN_USER" ]; then
    RUN_USER="${SUDO_USER:-$(ps -o user= -p "$PPID" | awk '{print $1}')}"
fi
if [ "$RUN_USER" = "root" ] || [ -z "$RUN_USER" ]; then
    error_exit "Cannot determine the non-root user to run Medusa. Exiting."
fi

touch /tmp/medusa_node_version.txt /tmp/medusa_log_path.txt /tmp/medusa_run_user.txt
echo "$NODE_VERSION" > /tmp/medusa_node_version.txt
echo "$LOG_FILE" > /tmp/medusa_log_path.txt
echo "$RUN_USER" > /tmp/medusa_run_user.txt

# Ensure log file exists and is writable
mkdir -p "$(dirname "$LOG_FILE")"
: > "$LOG_FILE" || error_exit "Unable to create log file at $LOG_FILE"
log "Log file created at $LOG_FILE"

# --- Installation Functions (Simplified for Debian/Ubuntu) ---
install_dependencies() {
    log "Installing dependencies (Node $NODE_VERSION, Postgres, Redis)..."
    sudo apt update 2>>"$LOG_FILE" || error_exit "apt update failed"
    sudo apt install -y curl build-essential git libpq-dev 2>>"$LOG_FILE" || error_exit "apt base packages failed"

    log "Installing Node.js ${NODE_VERSION}..."
    # nodesource setup script expects e.g. setup_20.x ; allow both "20" and "20.x" inputs
    ns_version="$NODE_VERSION"
    ns_version="${ns_version%.*}.x"  # normalize "20" -> "20.x", "20.x" -> "20.x"
    curl -fsSL "https://deb.nodesource.com/setup_${ns_version}" | sudo -E bash - >>"$LOG_FILE" 2>&1 || error_exit "NodeSource setup script failed"
    sudo apt install -y nodejs >>"$LOG_FILE" 2>&1 || error_exit "Node.js installation failed."

    log "Installing PostgreSQL and Redis..."
    sudo apt install -y postgresql redis-server >>"$LOG_FILE" 2>&1 || error_exit "DB/Cache installation failed."
    log "Dependencies installed."
}

install_global_npm_packages() {
    log "Installing global NPM packages: @medusajs/cli and ts-node..."
    sudo npm install -g @medusajs/cli ts-node >>"$LOG_FILE" 2>&1 || error_exit "Global NPM package installation failed."
    log "✅ Global NPM packages installed."
}

# --- Core Logic ---
log "--- [01/06] Starting Dependency Installation Script ---"
if command -v apt &> /dev/null; then
    install_dependencies
    install_global_npm_packages
else
    error_exit "Unsupported Linux distribution."
fi
log "Running project setup as user: $RUN_USER"
log "--- [01/06] Dependency Installation SUCCESSFUL. ---"
