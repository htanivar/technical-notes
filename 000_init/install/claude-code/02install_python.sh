#!/bin/bash

echo "========================================="
echo "         Installing pip3"
echo "========================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    local status=$1
    local message=$2
    case $status in
        "SUCCESS") echo -e "${GREEN}✓${NC} $message" ;;
        "INFO") echo -e "${YELLOW}ℹ${NC} $message" ;;
        "ERROR") echo -e "${RED}✗${NC} $message" ;;
    esac
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_status "ERROR" "Don't run this script as root/sudo. Run as normal user."
    exit 1
fi

print_status "INFO" "Updating package list..."
sudo apt update

print_status "INFO" "Installing pip3..."
sudo apt install -y python3-pip

# Verify installation
if command -v pip3 &> /dev/null; then
    pip_version=$(pip3 --version)
    print_status "SUCCESS" "pip3 installed successfully: $pip_version"
    
    # Also install some useful packages for development
    print_status "INFO" "Installing useful Python packages..."
    pip3 install --user requests beautifulsoup4 numpy pandas
    
    print_status "SUCCESS" "Setup complete! You can now install Python packages with pip3"
else
    print_status "ERROR" "pip3 installation failed. Try manually: sudo apt install python3-pip"
fi

echo "========================================="
