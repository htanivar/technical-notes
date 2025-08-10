#!/bin/bash

# uninstall_cloudflare.sh - Remove Cloudflare Tunnel installation
# This script removes cloudflared and all related configurations

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)"
    echo "Usage: sudo $0"
    exit 1
fi

INSTALL_LOG="/tmp/cloudflare_install.log"
BACKUP_DIR="/tmp/cloudflare_backup"

echo "=== Cloudflare Tunnel Uninstallation ==="
echo "Date: $(date)"
echo ""

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
        DISTRO_NAME=$NAME
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
        VERSION=$(cat /etc/debian_version)
        DISTRO_NAME="Debian"
    elif [ -f /etc/redhat-release ]; then
        DISTRO="rhel"
        VERSION=$(grep -oE '[0-9]+\.[0-9]+' /etc/redhat-release | head -1)
        DISTRO_NAME=$(cat /etc/redhat-release)
    else
        DISTRO="unknown"
        VERSION="unknown"
        DISTRO_NAME="Unknown"
    fi
    echo "Detected distribution: $DISTRO_NAME ($DISTRO $VERSION)"
# Detect environment first
detect_distro
detect_init_system

# Stop/disable service using detected init system
stop_and_disable_cloudflared


}

# Detect init system
detect_init_system() {
    if [ -d /run/systemd/system ]; then
        INIT_SYSTEM="systemd"
    elif [ -f /sbin/openrc ]; then
        INIT_SYSTEM="openrc"
    elif [ -f /etc/init.d/rcS ]; then
        INIT_SYSTEM="sysvinit"
    elif command -v service >/dev/null 2>&1; then
        INIT_SYSTEM="service"
    else
        INIT_SYSTEM="unknown"
    fi
    echo "Detected init system: $INIT_SYSTEM"
}

# Stop and disable cloudflared service generically
stop_and_disable_cloudflared() {
    echo "Stopping and disabling cloudflared service (if present)..."
    case $INIT_SYSTEM in
        systemd)
            systemctl is-active --quiet cloudflared 2>/dev/null && systemctl stop cloudflared || true
            systemctl is-enabled --quiet cloudflared 2>/dev/null && systemctl disable cloudflared || true
            ;;
        openrc)
            if command -v rc-service >/dev/null 2>&1; then
                rc-service cloudflared status >/dev/null 2>&1 && rc-service cloudflared stop || true
            fi
            if command -v rc-update >/dev/null 2>&1; then
                rc-update del cloudflared 2>/dev/null || true
            fi
            ;;
        sysvinit|service)
            if command -v service >/dev/null 2>&1; then
                service cloudflared status >/dev/null 2>&1 && service cloudflared stop || true
            fi
            # Disable on boot where applicable
            case $DISTRO in
                debian|ubuntu|armbian)
                    update-rc.d -f cloudflared remove 2>/dev/null || true
                    ;;
                centos|rhel|fedora|rocky|almalinux)
                    chkconfig cloudflared off 2>/dev/null || true
                    ;;
            esac
            ;;
    esac
# Remove package-managed cloudflared where applicable
remove_packaged_cloudflared() {
    case $DISTRO in
        debian|ubuntu|armbian)
            if dpkg -l | grep -q '^ii\s\+cloudflared'; then
                echo "Removing cloudflared package via apt..."
                apt-get remove -y cloudflared || true
            fi
            ;;
        centos|rhel|fedora|rocky|almalinux)
            if command -v dnf >/dev/null 2>&1; then
                dnf remove -y cloudflared || true
            else
                yum remove -y cloudflared || true
            fi
            ;;
        arch|manjaro)
            if pacman -Q cloudflared >/dev/null 2>&1; then
                pacman -R --noconfirm cloudflared || true
            fi
            ;;
        alpine)
            if apk info | grep -q '^cloudflared$'; then
                apk del cloudflared || true
            fi
            ;;
        opensuse*|sles)
            if zypper se -i cloudflared >/dev/null 2>&1; then
                zypper remove -y cloudflared || true
            fi
            ;;
    esac
}

# Attempt package removal (if it was installed from repos)
remove_packaged_cloudflared

}

# Remove service files based on init system
remove_service_files() {
    echo "Removing service definitions..."
    case $INIT_SYSTEM in
        systemd)
            if [ -f "/etc/systemd/system/cloudflared.service" ]; then
                rm -f /etc/systemd/system/cloudflared.service
                systemctl daemon-reload || true
            fi
            ;;
        openrc)
            if [ -f "/etc/init.d/cloudflared" ]; then
                rm -f /etc/init.d/cloudflared
            fi
            ;;
        sysvinit|service)
            if [ -f "/etc/init.d/cloudflared" ]; then
                rm -f /etc/init.d/cloudflared
            fi
            ;;
        *)
            # Try to remove common locations anyway
            rm -f /etc/systemd/system/cloudflared.service 2>/dev/null || true
            rm -f /etc/init.d/cloudflared 2>/dev/null || true
            ;;
    esac
}
# Warning message
echo "⚠️  WARNING: This will completely remove Cloudflare Tunnel and all configurations!"
echo ""
echo "This will remove:"
echo "• Cloudflared binary"
echo "• All configuration files"
echo "• Systemd service"
echo "• Log files"
echo "• Tunnel credentials"
echo ""

read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

echo ""
echo "Starting uninstallation process..."
echo ""

# Remove service files for the detected init system
remove_service_files

# List active tunnels before removal (if possible)
if command -v cloudflared &> /dev/null; then
    echo "Checking for active tunnels..."
    
# Additional cleanup for OpenRC pid/log files
if [ "$INIT_SYSTEM" = "openrc" ]; then
    rm -f /run/cloudflared.pid 2>/dev/null || true
fi

    # Try to list tunnels (requires API token)
    if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
    echo "Active tunnels:"
    cloudflared tunnel list 2>/dev/null || echo "Could not list tunnels (API token may be invalid)"
    echo ""
    
    read -p "Do you want to delete all tunnels from Cloudflare? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Attempting to delete tunnels..."
    
    # Get tunnel list and delete each one
    TUNNEL_LIST=$(cloudflared tunnel list --output json 2>/dev/null | jq -r '.[].id' 2>/dev/null || echo "")
    
    if [ -n "$TUNNEL_LIST" ]; then
    for tunnel_id in $TUNNEL_LIST; do
    echo "Deleting tunnel: $tunnel_id"
    cloudflared tunnel delete "$tunnel_id" --force 2>/dev/null || echo "Failed to delete tunnel $tunnel_id"
    done
    else
    echo "No tunnels found or could not retrieve tunnel list"
    fi
    fi
    else
    echo "CLOUDFLARE_API_TOKEN not set - cannot manage remote tunnels"
    echo "You may need to manually delete tunnels from the Cloudflare dashboard"
    fi
fi

# Remove cloudflared binary
if [ -f "/usr/local/bin/cloudflared" ]; then
    echo "Removing cloudflared binary..."
    rm -f /usr/local/bin/cloudflared
fi

# Remove setup helper script
if [ -f "/usr/local/bin/cloudflared-setup" ]; then
    echo "Removing setup helper script..."
    rm -f /usr/local/bin/cloudflared-setup
fi

# Remove configuration directory
if [ -d "/etc/cloudflared" ]; then
    echo "Removing configuration directory..."
    
    # Create backup of configurations before removal
    if [ -n "$(ls -A /etc/cloudflared 2>/dev/null)" ]; then
    mkdir -p "$BACKUP_DIR"
    echo "Backing up configurations to $BACKUP_DIR/cloudflared_config_backup_$(date +%Y%m%d_%H%M%S)..."
    cp -r /etc/cloudflared "$BACKUP_DIR/cloudflared_config_backup_$(date +%Y%m%d_%H%M%S)"
    fi
    
    rm -rf /etc/cloudflared
fi

# Remove log directory
if [ -d "/var/log/cloudflared" ]; then
    echo "Removing log directory..."
    
    # Create backup of logs before removal
    if [ -n "$(ls -A /var/log/cloudflared 2>/dev/null)" ]; then
    mkdir -p "$BACKUP_DIR"
    echo "Backing up logs to $BACKUP_DIR/cloudflared_logs_backup_$(date +%Y%m%d_%H%M%S)..."
    cp -r /var/log/cloudflared "$BACKUP_DIR/cloudflared_logs_backup_$(date +%Y%m%d_%H%M%S)"
    fi
    
    rm -rf /var/log/cloudflared
fi

# Remove cloudflared user (optional - ask user)
if id "cloudflared" &>/dev/null; then
    read -p "Remove cloudflared user account? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing cloudflared user..."
    userdel cloudflared 2>/dev/null || echo "Warning: Could not remove cloudflared user"
    else
    echo "Keeping cloudflared user account"
    fi
fi

# Remove user's cloudflared directory if it exists
if [ -d "/root/.cloudflared" ]; then
    read -p "Remove /root/.cloudflared directory? This contains tunnel credentials. (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing /root/.cloudflared directory..."
    
    # Backup credentials before removal
    if [ -n "$(ls -A /root/.cloudflared 2>/dev/null)" ]; then
    mkdir -p "$BACKUP_DIR"
    echo "Backing up credentials to $BACKUP_DIR/cloudflared_credentials_backup_$(date +%Y%m%d_%H%M%S)..."
    cp -r /root/.cloudflared "$BACKUP_DIR/cloudflared_credentials_backup_$(date +%Y%m%d_%H%M%S)"
    fi
    
    rm -rf /root/.cloudflared
    else
    echo "Keeping /root/.cloudflared directory"
    fi
fi

# Clean up installation log if it exists
if [ -f "$INSTALL_LOG" ]; then
    echo "Removing installation log..."
    rm -f "$INSTALL_LOG"
fi

# Show backup information
if [ -d "$BACKUP_DIR" ] && [ -n "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
    echo ""
    echo "📁 Backups created in: $BACKUP_DIR"
    echo "Contents:"
    ls -la "$BACKUP_DIR"
    echo ""
    echo "You can safely delete the backup directory if you don't need these files:"
    echo "sudo rm -rf $BACKUP_DIR"
fi

echo ""
echo "✅ Cloudflare Tunnel uninstallation completed!"
echo ""
echo "Removed components:"
echo "• Cloudflared binary (/usr/local/bin/cloudflared)"
echo "• Configuration directory (/etc/cloudflared)"
echo "• Log directory (/var/log/cloudflared)"
echo "• Systemd service (cloudflared.service)"
echo "• Setup helper script (/usr/local/bin/cloudflared-setup)"
echo ""

# Check if there are any remaining cloudflared processes
if pgrep -f cloudflared >/dev/null 2>&1; then
    echo "⚠️  Warning: Some cloudflared processes are still running:"
    pgrep -f cloudflared
    echo "You may need to kill them manually: sudo pkill -f cloudflared"
    echo ""
fi

echo "Note: If you had DNS records pointing to your tunnel, you may need to"
echo "update or remove them from your Cloudflare dashboard."
echo ""
echo "To completely clean up, you may also want to:"
echo "1. Remove any environment variables (CLOUDFLARE_API_TOKEN, etc.)"
echo "2. Check for any remaining cloudflared references in your system"
echo "3. Remove DNS records from Cloudflare dashboard if no longer needed"
