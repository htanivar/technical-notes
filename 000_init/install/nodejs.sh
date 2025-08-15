#!/bin/bash

# Identify Linux distribution
distro=$(lsb_release -is | tr '[:upper:]' '[:lower:]')

# Install pre-requisites
if [[ "$distro" == "ubuntu" || "$distro" == "debian" ]]; then
  sudo apt update && sudo apt install -y curl
elif [[ "$distro" == "centos" || "$distro" == "redhat" ]]; then
  sudo yum update -y && sudo yum install -y curl
else
  echo "Unsupported distribution: $distro"
  exit 1
fi

# Check if Node.js is already installed
node_version=$(node -v 2>/dev/null)
if [[ -z "$node_version" ]]; then
  # Install Node.js version 20 (using NodeSource)
  case $distro in
    ubuntu|debian)
      curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash -
      sudo apt install -y nodejs
      ;;
    centos|redhat)
      curl -sL https://rpm.nodesource.com/setup_latest.x | sudo -E bash -
      sudo yum install -y nodejs
      ;;
    *)
      echo "Unsupported distribution: $distro"
      exit 1
  esac
fi

# Verify Node.js and npm installation
node_version=$(node -v)
if [[ -z "$node_version" ]]; then
  echo "Failed to install Node.js!"
  exit 1
fi
npm_version=$(npm -v)
if [[ -z "$npm_version" ]]; then
  echo "Failed to install npm!"
  exit 1
fi

# Install Angular CLI globally
npm install -g @angular/cli

# Verify installation
echo "Node.js version: $node_version"
echo "npm version: $npm_version"
echo "Angular CLI version: $(ng --version)"

echo "Installation complete!"
