#!/bin/bash

# Define key URL and key destination
KEY_URL="https://dl.google.com/linux/linux_signing_key.pub"
KEYRING_PATH="/usr/share/keyrings/google-keyring.gpg"
REPO_FILE="/etc/apt/sources.list.d/google-chrome.list"
REPO_ENTRY="deb [signed-by=$KEYRING_PATH] http://dl.google.com/linux/chrome/deb/ stable main"

# Ensure the script is run with sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo ./add_google_signing_key.sh)"
  exit 1
fi

# Download and add Google's signing key
echo "Downloading Google's signing key..."
wget -qO - "$KEY_URL" | tee "$KEYRING_PATH" > /dev/null

if [ -f "$KEYRING_PATH" ]; then
  echo "Google signing key added successfully at $KEYRING_PATH"
else
  echo "Error: Failed to add Google signing key."
  exit 1
fi

# Add Google Chrome repository
if [ ! -f "$REPO_FILE" ]; then
  echo "Adding Google Chrome repository..."
  echo "$REPO_ENTRY" | tee "$REPO_FILE"
  echo "Repository added successfully."
else
  echo "Google Chrome repository already exists."
fi

# Update package lists
echo "Updating package lists..."
apt update -y

echo "Google repository setup completed!"
