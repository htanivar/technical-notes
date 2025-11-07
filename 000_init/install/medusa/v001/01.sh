#!/bin/bash
# 01_install_dependencies.sh

# --- Core Global Variables ---
LOG_FILE="$(pwd)/medusa_installation_$(date +%Y%m%d_%H%M%S).log"
MEDUSA_ROOT="/opt/medusa/my-store"
CERT_DIR="/etc/ssl/certs/medusa"
TEMP_ROLLBACK_FILE="/tmp/medusa_new_packages.txt"

# --- User Input ---
read -p "Enter the desired Node.js version (e.g., 20.x or 18.x). Default is 20.x: " NODE_VERSION
NODE_VERSION=${NODE_VERSION:-20.x}
echo "$NODE_VERSION" > /tmp/medusa_node_version.txt

# --- Logging Functions & Rollback (Unchanged) ---
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"; }
error_exit() { log "!!! FATAL ERROR: $1"; rollback_on_failure; }
rollback_on_failure() {
    log "--- Initiating Rollback Due to Failure ---"
    if systemctl is-active medusa &>/dev/null; then systemctl stop medusa 2>/dev/null; fi
    if [ -d "$MEDUSA_ROOT" ]; then sudo rm -rf "$MEDUSA_ROOT"; fi
    if [ -d "$CERT_DIR" ]; then sudo rm -rf "$CERT_DIR"; fi
    if [ -f "$TEMP_ROLLBACK_FILE" ]; then
        log "Attempting to remove newly installed packages listed in $TEMP_ROLLBACK_FILE..."
        while IFS= read -r pkg; do
            if [ -n "$pkg" ]; then
                if [ "$DISTRO" == "DEBIAN" ]; then sudo apt purge -y "$pkg" 2>>"$LOG_FILE";
                elif [ "$DISTRO" == "RHEL" ]; then sudo $PKG_MANAGER remove -y "$pkg" 2>>"$LOG_FILE"; fi
            fi
        done < "$TEMP_ROLLBACK_FILE"
        sudo rm -f "$TEMP_ROLLBACK_FILE"
    fi
    log "--- Rollback COMPLETE. System state is restored (best effort). ---"
    exit 1
}
trap 'error_exit "Script interrupted or exited with error code $?"' ERR

# --- Installation Functions (OS specific parts only install core dependencies) ---
install_dependencies_debian() {
    log "Detected Debian/Ubuntu. Installing dependencies (Node $NODE_VERSION, Postgres, Redis)..."
    PKG_MANAGER="apt"
    dpkg --get-selections | awk '{print $1}' > /tmp/medusa_initial_packages.txt
    log "Installing Node.js ${NODE_VERSION}..."
    sudo apt update
    sudo apt install -y curl
    curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}" | sudo -E bash -
    sudo apt install -y nodejs build-essential 2>>"$LOG_FILE" || error_exit "Node.js installation failed."
    log "Installing PostgreSQL and Redis..."
    sudo apt install -y postgresql redis-server 2>>"$LOG_FILE" || error_exit "DB/Cache installation failed."
    dpkg --get-selections | awk '{print $1}' > /tmp/medusa_final_packages.txt
    comm -13 /tmp/medusa_initial_packages.txt /tmp/medusa_final_packages.txt > "$TEMP_ROLLBACK_FILE"
    rm -f /tmp/medusa_initial_packages.txt /tmp/medusa_final_packages.txt
}
install_dependencies_rhel() {
    log "Detected RHEL/CentOS/Fedora. Installing dependencies (Node $NODE_VERSION, Postgres, Redis)..."
    if command -v dnf &> /dev/null; then PKG_MANAGER="dnf"; else PKG_MANAGER="yum"; fi
    $PKG_MANAGER list installed > /tmp/medusa_initial_packages.txt
    log "Installing Node.js ${NODE_VERSION}..."
    MAJOR_NODE_VERSION=$(echo "$NODE_VERSION" | cut -d'.' -f1)
    sudo $PKG_MANAGER install -y "nodejs:${MAJOR_NODE_VERSION}" 2>>"$LOG_FILE" || error_exit "Node.js installation failed."
    log "Installing PostgreSQL and Redis..."
    sudo $PKG_MANAGER install -y postgresql-server redis 2>>"$LOG_FILE" || error_exit "DB/Cache installation failed."
    sudo postgresql-setup initdb 2>>"$LOG_FILE"
    $PKG_MANAGER list installed > /tmp/medusa_final_packages.txt
    grep -v -f /tmp/medusa_initial_packages.txt /tmp/medusa_final_packages.txt | awk '{print $1}' | cut -d'.' -f1 > "$TEMP_ROLLBACK_FILE"
    rm -f /tmp/medusa_initial_packages.txt /tmp/medusa_final_packages.txt
}

# --- New function for global NPM modules ---
install_global_npm_packages() {
    log "Installing global NPM packages: @medusajs/cli and ts-node..."
    # FIX: Install ts-node globally alongside the CLI
    npm install -g @medusajs/cli ts-node 2>>"$LOG_FILE" || error_exit "Global NPM package installation failed (Medusa CLI/ts-node)."
    log "✅ Global NPM packages installed."
}

# --- Core Logic ---
log "--- [01/06] Starting Dependency Installation Script ---"
if [[ $EUID -ne 0 ]]; then error_exit "This script must be run as root (or with sudo)."; fi
log "✅ Root check passed."
if [[ "$(uname)" != "Linux" ]]; then error_exit "OS check failed. This script only supports Linux."; fi
log "✅ OS check passed (Linux)."

if command -v apt &> /dev/null; then DISTRO="DEBIAN"; install_dependencies_debian
elif command -v yum &> /dev/null || command -v dnf &> /dev/null; then DISTRO="RHEL"; install_dependencies_rhel
else error_exit "Unsupported Linux distribution. Cannot find apt, yum, or dnf."; fi

# 3. Install global NPM dependencies (moved from script 03)
install_global_npm_packages

log "--- [01/06] Dependency Installation SUCCESSFUL. Log file is $LOG_FILE. ---"
echo "$LOG_FILE" > /tmp/medusa_log_path.txt
exit 0