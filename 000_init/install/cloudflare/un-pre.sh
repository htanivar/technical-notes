#!/bin/bash

# un-pre.sh - Remove prerequisites installed by pre.sh
# This script removes all changes made by pre.sh using the installation log

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)"
    echo "Usage: sudo $0"
    exit 1
fi

INSTALL_LOG="/tmp/cloudflare_prereq_install.log"
BACKUP_DIR="/tmp/cloudflare_backup"

echo "=== Cloudflare Tunnel Prerequisites Removal ==="
echo "Date: $(date)"
echo ""

# Check if install log exists
if [ ! -f "$INSTALL_LOG" ]; then
    echo "Error: Installation log not found at $INSTALL_LOG"
    echo "Cannot proceed with removal without installation log."
    exit 1
fi

echo "Reading installation log from: $INSTALL_LOG"
echo ""

# Function to remove packages
remove_packages() {
    echo "Removing installed packages..."
    while IFS= read -r line; do
        if [[ $line == PACKAGE:* ]]; then
            package=${line#PACKAGE:}
            echo "Removing package: $package"
            apt-get remove -y "$package" || echo "Warning: Failed to remove $package"
        fi
    done < "$INSTALL_LOG"
}

# Function to remove created directories
remove_directories() {
    echo "Removing created directories..."
    while IFS= read -r line; do
        if [[ $line == DIR_CREATED:* ]]; then
            dir=${line#DIR_CREATED:}
            if [ -d "$dir" ]; then
                echo "Removing directory: $dir"
                rm -rf "$dir"
            fi
        fi
    done < "$INSTALL_LOG"
}

# Function to remove created users
remove_users() {
    echo "Removing created users..."
    while IFS= read -r line; do
        if [[ $line == USER_CREATED:* ]]; then
            user=${line#USER_CREATED:}
            if id "$user" &>/dev/null; then
                echo "Removing user: $user"
                userdel "$user" || echo "Warning: Failed to remove user $user"
            fi
        fi
    done < "$INSTALL_LOG"
}

# Confirm removal
read -p "This will remove all packages and changes made by pre.sh. Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Removal cancelled."
    exit 0
fi

echo "Starting removal process..."
echo ""

# Remove in reverse order of installation
remove_directories
remove_users
remove_packages

# Clean up package cache
echo "Cleaning package cache..."
apt-get autoremove -y
apt-get autoclean

# Remove backup directory if it exists and is empty
if [ -d "$BACKUP_DIR" ]; then
    if [ -z "$(ls -A "$BACKUP_DIR")" ]; then
        echo "Removing empty backup directory: $BACKUP_DIR"
        rmdir "$BACKUP_DIR"
    else
        echo "Backup directory $BACKUP_DIR contains files, not removing"
    fi
fi

# Remove installation log
echo "Removing installation log: $INSTALL_LOG"
rm -f "$INSTALL_LOG"

echo ""
echo "Prerequisites removal completed!"
echo "Note: Some packages may have been kept if they were dependencies for other software."
echo "Run 'apt-get autoremove' again if needed to clean up remaining unused packages."
