#!/bin/bash

# pre.sh - Install prerequisites for Cloudflare Tunnel on Armbian
# This script installs necessary dependencies and logs changes for easy removal

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)"
    echo "Usage: sudo $0"
    exit 1
fi

INSTALL_LOG="/tmp/cloudflare_prereq_install.log"
BACKUP_DIR="/tmp/cloudflare_backup"

echo "=== Cloudflare Tunnel Prerequisites Installation ===" | tee "$INSTALL_LOG"
echo "Date: $(date)" | tee -a "$INSTALL_LOG"
echo "System: $(uname -a)" | tee -a "$INSTALL_LOG"
echo "" | tee -a "$INSTALL_LOG"

# Create backup directory
mkdir -p "$BACKUP_DIR"
echo "BACKUP_DIR=$BACKUP_DIR" >> "$INSTALL_LOG"

# Function to log package installations
log_package() {
    echo "PACKAGE:$1" >> "$INSTALL_LOG"
}

# Function to log file changes
log_file_change() {
    echo "FILE_CHANGE:$1" >> "$INSTALL_LOG"
}

echo "Updating package lists..." | tee -a "$INSTALL_LOG"
apt-get update

echo "Installing required packages..." | tee -a "$INSTALL_LOG"

# Install curl if not present
if ! command -v curl &> /dev/null; then
    echo "Installing curl..." | tee -a "$INSTALL_LOG"
    apt-get install -y curl
    log_package "curl"
fi

# Install wget if not present
if ! command -v wget &> /dev/null; then
    echo "Installing wget..." | tee -a "$INSTALL_LOG"
    apt-get install -y wget
    log_package "wget"
fi

# Install gnupg for key management
if ! command -v gpg &> /dev/null; then
    echo "Installing gnupg..." | tee -a "$INSTALL_LOG"
    apt-get install -y gnupg
    log_package "gnupg"
fi

# Install lsb-release for system identification
if ! command -v lsb_release &> /dev/null; then
    echo "Installing lsb-release..." | tee -a "$INSTALL_LOG"
    apt-get install -y lsb-release
    log_package "lsb-release"
fi

# Install ca-certificates for SSL
echo "Installing ca-certificates..." | tee -a "$INSTALL_LOG"
apt-get install -y ca-certificates
log_package "ca-certificates"

# Install software-properties-common for repository management
echo "Installing software-properties-common..." | tee -a "$INSTALL_LOG"
apt-get install -y software-properties-common
log_package "software-properties-common"

# Create cloudflare user if it doesn't exist
if ! id "cloudflared" &>/dev/null; then
    echo "Creating cloudflared user..." | tee -a "$INSTALL_LOG"
    useradd -r -s /bin/false -d /nonexistent cloudflared
    echo "USER_CREATED:cloudflared" >> "$INSTALL_LOG"
fi

# Create necessary directories
echo "Creating directories..." | tee -a "$INSTALL_LOG"
mkdir -p /etc/cloudflared
mkdir -p /var/log/cloudflared
chown cloudflared:cloudflared /etc/cloudflared
chown cloudflared:cloudflared /var/log/cloudflared
echo "DIR_CREATED:/etc/cloudflared" >> "$INSTALL_LOG"
echo "DIR_CREATED:/var/log/cloudflared" >> "$INSTALL_LOG"

echo "" | tee -a "$INSTALL_LOG"
echo "Prerequisites installation completed successfully!" | tee -a "$INSTALL_LOG"
echo "Installation log saved to: $INSTALL_LOG" | tee -a "$INSTALL_LOG"
echo "Backup directory: $BACKUP_DIR" | tee -a "$INSTALL_LOG"
echo "" | tee -a "$INSTALL_LOG"
echo "Next steps:" | tee -a "$INSTALL_LOG"
echo "1. Run access_check.sh to verify Cloudflare account access" | tee -a "$INSTALL_LOG"
echo "2. Run install_cloudflare.sh to install Cloudflare Tunnel" | tee -a "$INSTALL_LOG"
