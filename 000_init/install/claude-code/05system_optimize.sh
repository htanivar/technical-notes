#!/bin/bash

echo "========================================="
echo "    System Optimization for Claude Code"
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

print_status "INFO" "Optimizing system for better performance..."

# Clean package cache
print_status "INFO" "Cleaning package cache..."
sudo apt autoremove -y
sudo apt autoclean

# Optimize swappiness for better RAM usage
current_swappiness=$(cat /proc/sys/vm/swappiness)
print_status "INFO" "Current swappiness: $current_swappiness"

if [ "$current_swappiness" -gt 10 ]; then
    print_status "INFO" "Optimizing swappiness for better RAM usage..."
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
    sudo sysctl vm.swappiness=10
    print_status "SUCCESS" "Swappiness optimized (will take effect after reboot)"
fi

# Enable zram for better memory compression (if available)
if ! command -v zramctl &> /dev/null; then
    print_status "INFO" "Installing zram tools..."
    sudo apt install -y zram-tools
fi

print_status "SUCCESS" "System optimization complete!"
print_status "INFO" "Consider rebooting for all changes to take effect"

echo "========================================="
