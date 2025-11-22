#!/bin/bash

echo "========================================="
echo "      Browser Update & Install"
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

# Check current browsers
browsers=("firefox" "google-chrome" "chromium" "brave-browser")
browser_found=false

print_status "INFO" "Checking current browsers..."

for browser in "${browsers[@]}"; do
    if command -v "$browser" &> /dev/null; then
        version=$($browser --version 2>/dev/null | head -n1)
        print_status "SUCCESS" "Found: $version"
        browser_found=true
    fi
done

if [ "$browser_found" = true ]; then
    print_status "INFO" "Updating existing browsers..."
    sudo apt update && sudo apt upgrade -y firefox chromium
else
    print_status "INFO" "No browsers found. Installing Firefox..."
    sudo apt update
    sudo apt install -y firefox
    
    if command -v firefox &> /dev/null; then
        print_status "SUCCESS" "Firefox installed successfully"
    else
        print_status "ERROR" "Firefox installation failed"
    fi
fi

echo "========================================="
echo "Browser setup complete!"
echo "========================================="
