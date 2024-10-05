#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or using sudo."
    exit 1
fi


# Variables
APPLICATION_DIR="go"
INSTALL_DIR="/opt/${APPLICATION_DIR}"
GO_DOWNLOAD_URL="https://go.dev/dl/go1.22.3.linux-amd64.tar.gz"
TEMP_DIR="/tmp/go-installation"
ENV_FILE="/etc/environment"
LOG_FILE="/var/log/go_installation.log"
GO_TARBALL="${GO_DOWNLOAD_URL##*/}"

# Function to log messages
log_message() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOG_FILE"
}

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  log_message "Please run as root."
  exit 1
fi

log_message "Starting Go installation..."
log_message "Variables:"
log_message "APPLICATION_DIR=$APPLICATION_DIR"
log_message "INSTALL_DIR=$INSTALL_DIR"
log_message "GO_DOWNLOAD_URL=$GO_DOWNLOAD_URL"
log_message "TEMP_DIR=$TEMP_DIR"
log_message "ENV_FILE=$ENV_FILE"
log_message "LOG_FILE=$LOG_FILE"
log_message "GO_TARBALL=$GO_TARBALL"

# Create temporary directory
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR" || exit

# Download the Go tarball using wget
log_message "Downloading Go: $GO_TARBALL..."
wget --inet4-only "$GO_DOWNLOAD_URL"
if [ $? -ne 0 ]; then
  log_message "Failed to download Go."
  exit 1
fi

# Remove existing Go installation if it exists
if [ -d "$INSTALL_DIR" ]; then
  log_message "Removing existing Go installation..."
  rm -rf "$INSTALL_DIR"
fi

# Extract the tarball to the installation directory
log_message "Installing Go to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
tar -C /opt -xzf "$GO_TARBALL"
if [ $? -ne 0 ]; then
  log_message "Failed to extract Go tarball."
  exit 1
fi

# Clean up the temporary directory
cd ~ || exit
rm -rf "$TEMP_DIR"

# Update /etc/environment to include Go binary in PATH
log_message "Updating PATH in $ENV_FILE..."
if grep -q ':/opt/go/bin' "$ENV_FILE"; then
  log_message "Go path already exists in $ENV_FILE."
else
  current_path=$(grep -oP '(?<=PATH=").*(?=")' "$ENV_FILE")
  if [ -n "$current_path" ]; then
    sed -i "s|PATH=\"$current_path\"|PATH=\"$current_path:/opt/go/bin\"|" "$ENV_FILE"
  else
    echo "PATH=\"/opt/go/bin\"" >> "$ENV_FILE"
  fi
fi

# Reload /etc/environment to apply changes
log_message "Reloading environment variables..."
source "$ENV_FILE"

# Verify installation
log_message "Verifying Go installation..."
/opt/go/bin/go version
if [ $? -eq 0 ]; then
  log_message "Go has been successfully installed and added to the PATH for all users."
else
  log_message "There was an issue installing Go. Please check the output for errors."
  exit 1
fi

log_message "Go installation completed successfully."
