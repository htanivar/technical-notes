#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or using sudo."
    exit 1
fi

# Update package list
apt update

# Install git
apt install -y git
git --version
echo "GIT installation completed."
