#!/bin/bash

set -e

# Identify Linux distribution
distro=$(lsb_release -is | tr '[:upper:]' '[:lower:]')

echo "Installing Node.js 20 on $distro..."

# Install pre-requisites
if [[ "$distro" == "ubuntu" || "$distro" == "debian" || "$distro" == "zorin" ]]; then
  sudo apt update && sudo apt install -y curl ca-certificates gnupg
elif [[ "$distro" == "centos" || "$distro" == "redhat" ]]; then
  sudo yum update -y && sudo yum install -y curl
else
  echo "Unsupported distribution: $distro"
  exit 1
fi

# Install Node.js 20 (Modern NodeSource Method)
if [[ "$distro" == "ubuntu" || "$distro" == "debian" || "$distro" == "zorin" ]]; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt install -y nodejs
else
  curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo -E bash -
  sudo yum install -y nodejs
fi

# Verify Node.js
echo "Node.js version: $(node -v)"

# Enable Corepack (for Yarn) and install PM2 system-wide
echo "Installing Yarn and PM2..."
sudo corepack enable
sudo npm install -g pm2

# Verify Tools
echo "Yarn version: $(yarn -version)"
echo "PM2 version: $(pm2 -version)"

echo "Installation complete! Node, Yarn, and PM2 are now available for all users."