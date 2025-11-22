#!/bin/bash

# --- Global Variables & Logging Setup ---
SCRIPT_NAME="uninstall_nginx.sh"
LOG_FILE="/var/log/nginx_uninstall_$(date +%Y%m%d_%H%M%S).log"
HOST_NAME="nginx.localhost.com"
NGINX_ROOT="/var/www/html/$HOST_NAME"
CERT_DIR="/etc/ssl/certs/nginx"
CONF_FILE="/etc/nginx/conf.d/$HOST_NAME.conf"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "--- Starting $SCRIPT_NAME ---"

# 1. Check current user is root
if [[ $EUID -ne 0 ]]; then
    log "!!! FATAL: This script must be run as root."
    exit 1
fi
log "✅ User check passed (running as root)."

# 2. Determine Distribution and Package Manager
if command -v apt &> /dev/null; then
    DISTRO="DEBIAN"
    REMOVE_CMD="apt purge -y"
    CLEANUP_CMD="apt autoremove -y"
elif command -v yum &> /dev/null; then
    DISTRO="RHEL"
    REMOVE_CMD="yum remove -y"
    CLEANUP_CMD="yum autoremove -y"
elif command -v dnf &> /dev/null; then
    DISTRO="RHEL"
    REMOVE_CMD="dnf remove -y"
    CLEANUP_CMD="dnf autoremove -y"
else
    log "❌ Unsupported Linux distribution. Cannot proceed with package removal."
    exit 1
fi
log "✅ Detected distribution: **$DISTRO**."

# 3. Stop and disable NGINX service
log "3. Stopping and disabling NGINX service..."
systemctl stop nginx 2>/dev/null
systemctl disable nginx 2>/dev/null
log "   ✅ Service stopped and disabled."

# 4. Remove NGINX packages
log "4. Removing NGINX packages (nginx, nginx-common)..."
if $REMOVE_CMD nginx; then
    log "   ✅ NGINX packages removed."
else
    log "   ⚠️ WARNING: Failed to remove NGINX package (it might not have been installed)."
fi

# 5. Clean up configuration and data files
log "5. Cleaning up configuration, data, and log files..."

# Remove NGINX site configuration file
[ -f "$CONF_FILE" ] && rm -f "$CONF_FILE" && log "   - Removed site config: $CONF_FILE"

# Remove the test document root
[ -d "$NGINX_ROOT" ] && rm -rf "$NGINX_ROOT" && log "   - Removed document root: $NGINX_ROOT"

# Remove the created certificate directory and files
[ -d "$CERT_DIR" ] && rm -rf "$CERT_DIR" && log "   - Removed certificates: $CERT_DIR"

# Clean up default configuration files that may have been created
# Note: /etc/nginx itself and its standard subfolders are often left by the package manager purge
# but files related to the specific install should be gone.
log "   ✅ Configuration files removed."

# 6. Remove /etc/hosts entry
log "6. Removing /etc/hosts entry for $HOST_NAME..."
if grep -q "$HOST_NAME" /etc/hosts; then
    sed -i "/$HOST_NAME/d" /etc/hosts
    log "   ✅ /etc/hosts entry removed."
else
    log "   ✅ /etc/hosts entry not found (no action needed)."
fi

# 7. Autoremove dependencies
log "7. Cleaning up unused dependencies..."
$CLEANUP_CMD
log "   ✅ Cleanup complete."

log "--- NGINX Uninstall COMPLETE ---"
log "NOTE: The uninstallation process is logged in $LOG_FILE"