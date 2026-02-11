#!/usr/bin/env bash

set -e

# Must be run as root (sudo)
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo."
    exit 1
fi

# Check if ssh server is installed
if command -v sshd >/dev/null 2>&1; then
    echo "OpenSSH server is already installed."
else
    echo "Installing OpenSSH server..."
    apt update -y
    apt install -y openssh-server
fi

# Enable and start ssh service
systemctl enable ssh
systemctl restart ssh

echo "SSH is installed and running."
