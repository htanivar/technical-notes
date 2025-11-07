#!/bin/bash
# 01_install_dependencies.sh - Installs all necessary OS dependencies and Node.js.

# --- Core Global Variables ---
LOG_FILE="$(pwd)/medusa_installation_$(date +%Y%m%d_%H%M%S).log"
MEDUSA_ROOT="/opt/medusa/my-store"
# ... other variables ...

# --- User Input & Global Variables Setup ---
read -p "Enter the desired Node.js version (e.g., 20.x or 18.x). Default is 20.x: " NODE_VERSION
NODE_VERSION=${NODE_VERSION:-20.x}

# CRITICAL FIX: Determine the non-root user and save global variables
RUN_USER=$(logname 2>/dev/null || whoami)
if [ "$RUN_USER" == "root" ] || [ -z "$RUN_USER" ]; then
    RUN_USER=$(echo "$SUDO_USER" 2>/dev/null || ps -o user= -p $PPID | awk '{print $1}')
fi
if [ "$RUN_USER" == "root" ] || [ -z "$RUN_USER" ]; then
    echo "!!! FATAL ERROR: Cannot determine the non-root user to run Medusa. Exiting."
    exit 1
fi

echo "$NODE_VERSION" > /tmp/medusa_node_version.txt
echo "$LOG_FILE" > /tmp/medusa_log_path.txt
echo "$RUN_USER" > /tmp/medusa_run_user.txt

# --- Installation Functions (Simplified for Debian/Ubuntu) ---
# ... (logging functions) ...

install_dependencies() {
    log "Installing dependencies (Node $NODE_VERSION, Postgres, Redis)..."
    sudo apt update 2>>"$LOG_FILE"
    sudo apt install -y curl build-essential git libpq-dev 2>>"$LOG_FILE"

    log "Installing Node.js ${NODE_VERSION}..."
    curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}" | sudo -E bash - 2>>"$LOG_FILE"
    sudo apt install -y nodejs 2>>"$LOG_FILE" || error_exit "Node.js installation failed."

    log "Installing PostgreSQL and Redis..."
    sudo apt install -y postgresql redis-server 2>>"$LOG_FILE" || error_exit "DB/Cache installation failed."
}

install_global_npm_packages() {
    log "Installing global NPM packages: @medusajs/cli and ts-node..."
    npm install -g @medusajs/cli ts-node 2>>"$LOG_FILE" || error_exit "Global NPM package installation failed."
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