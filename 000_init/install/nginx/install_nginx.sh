#!/bin/bash

# --- Global Variables & Logging Setup ---
SCRIPT_NAME="install_nginx.sh"
LOG_FILE="/var/log/nginx_install_$(date +%Y%m%d_%H%M%S).log"
STATE_FILE="/tmp/nginx_install_state_$(date +%Y%m%d_%H%M%S).tar.gz"
CONFIG_SCRIPT="./configure_nginx.sh"
ROLLBACK_NEEDED=0

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Failure and Rollback function
fail_and_rollback() {
    log "!!! FATAL: $1"
    ROLLBACK_NEEDED=1
    log "Initiating Rollback procedure..."
    rollback
    exit 1
}

# --- Pre-Checks ---
log "--- Starting $SCRIPT_NAME ---"

# 1. Check current user is root
if [[ $EUID -ne 0 ]]; then
    fail_and_rollback "This script must be run as root."
fi
log "✅ User check passed (running as root)."

# 2. Check OS is Linux
if [[ "$(uname)" != "Linux" ]]; then
    fail_and_rollback "❌ Operating System is not Linux. Aborting."
fi
log "✅ OS check passed (Linux)."

# 3. Determine Distribution and Package Manager
if command -v apt &> /dev/null; then
    DISTRO="DEBIAN"
    INSTALL_CMD_UPDATE="apt update -y" # Add this for Debian/RHEL
    INSTALL_CMD_INSTALL="apt install -y" # Add this for Debian
    PACKAGE_LIST="nginx openssl curl"
elif command -v yum &> /dev/null; then
    DISTRO="RHEL"
    INSTALL_CMD="yum install -y"
    PACKAGE_LIST="nginx openssl curl"
elif command -v dnf &> /dev/null; then
    DISTRO="RHEL"
    INSTALL_CMD="dnf install -y"
    PACKAGE_LIST="nginx openssl curl"
else
    fail_and_rollback "❌ Unsupported Linux distribution. Cannot determine package manager (apt/yum/dnf)."
fi
log "✅ Detected distribution: **$DISTRO**. Using command: **$INSTALL_CMD**"

# --- State Capture and Rollback Setup ---

# Function to verify and install dependencies
verify_and_install_dependencies() {
log "[STEP 1/4] Verifying and installing dependencies ($PACKAGE_LIST)..."

    # 1. Update package lists
    if [ "$DISTRO" == "DEBIAN" ]; then
        apt update -y
    elif [ "$DISTRO" == "RHEL" ]; then
        # No separate update needed for yum/dnf install commands
        log "   (Skipping explicit update for $DISTRO)"
    fi

    # 2. Install packages
    if ! $INSTALL_CMD_INSTALL $PACKAGE_LIST; then
        fail_and_rollback "Failed to install required packages: $PACKAGE_LIST."
    fi
    log "✅ Dependencies installed/verified."
}

# Function to capture system state
capture_system_state() {
    log "[STEP 2/4] Capturing current system state for rollback..."

    # Capture a list of currently installed packages
    if [ "$DISTRO" == "DEBIAN" ]; then
        dpkg --get-selections > /tmp/installed_packages_before.list
    elif [ "$DISTRO" == "RHEL" ]; then
        rpm -qa > /tmp/installed_packages_before.list
    fi

    # Capture key configuration directories (empty them out if they don't exist later)
    tar -czf "$STATE_FILE" /etc/nginx /etc/ssl/certs/nginx /tmp/installed_packages_before.list /etc/hosts 2>/dev/null
    log "✅ System state captured to $STATE_FILE."
}

# Function to handle rollback
rollback() {
    if [ $ROLLBACK_NEEDED -eq 1 ]; then
        log "!!! Performing rollback..."
        # 1. Stop and purge NGINX (if installed)
        if command -v nginx &> /dev/null; then
            systemctl stop nginx 2>/dev/null
            systemctl disable nginx 2>/dev/null

            if [ "$DISTRO" == "DEBIAN" ]; then
                apt purge nginx -y
            elif [ "$DISTRO" == "RHEL" ]; then
                yum remove nginx -y || dnf remove nginx -y
            fi
            log "   NGINX stopped and removed."
        fi

        # 2. Restore captured files
        if [ -f "$STATE_FILE" ]; then
             log "   Restoring files from $STATE_FILE..."
             tar -xzf "$STATE_FILE" -C / 2>/dev/null
             log "   Files restored."
        fi

        # 3. Clean up temporary files
        rm -f "$STATE_FILE" /tmp/installed_packages_before.list
        log "   Temporary files cleaned."
        log "!!! Rollback COMPLETE. System is returned to its prior state."
    else
        log "No rollback required."
    fi
}

# --- Installation & Configuration ---

# 4. Run the detailed configuration script
run_configuration() {
    log "[STEP 3/4] Starting NGINX configuration script ($CONFIG_SCRIPT)..."

    if ! bash "$CONFIG_SCRIPT" "$LOG_FILE"; then
        fail_and_rollback "Configuration script failed. Initiating full rollback."
    fi
    log "✅ Configuration complete."
}

# 5. Testing the final installation
test_installation() {
    log "[STEP 4/4] Testing NGINX HTTPS setup..."
    # The IP 127.0.0.1 must be used instead of hostname as not all environments
    # resolve the hostname without user interaction or manual configuration.
    # We will use 'curl' to check the specific host header.

    if curl -s -k -H "Host: nginx.localhost.com" https://127.0.0.1/ | grep -q "Welcome to HTTPS NGINX Test Page"; then
        log "✅ Installation Test SUCCESSFUL. HTTPS site is live."
    else
        fail_and_rollback "❌ Installation Test FAILED. HTTPS site did not return expected content."
    fi
}

# --- Main Execution Flow ---

# Capture state BEFORE installing dependencies to enable full rollback
capture_system_state

# Ensure clean up happens even on unexpected exit (e.g., Ctrl+C)
trap 'rollback' EXIT

# Execution steps
verify_and_install_dependencies
run_configuration
test_installation

# If all successful, we exit gracefully. The trap will run 'rollback', which will see ROLLBACK_NEEDED=0.
log "--- NGINX Installation & Configuration COMPLETED SUCCESSFULLY ---"

# We explicitly remove the state file if successful so that the trap doesn't try to restore non-existent data.
ROLLBACK_NEEDED=0
rm -f "$STATE_FILE"