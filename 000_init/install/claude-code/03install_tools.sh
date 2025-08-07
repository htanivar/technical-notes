#!/bin/bash

echo "========================================="
echo "    Installing Development Tools"
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

print_status "INFO" "Updating package list..."
sudo apt update

# Install essential development tools
tools=("git" "curl" "wget" "nano" "vim" "build-essential")

for tool in "${tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        print_status "INFO" "Installing $tool..."
        sudo apt install -y "$tool"
        
        if command -v "$tool" &> /dev/null; then
            print_status "SUCCESS" "$tool installed successfully"
        else
            print_status "ERROR" "Failed to install $tool"
        fi
    else
        print_status "SUCCESS" "$tool already installed"
    fi
done

# Optional: Install VS Code (great for Claude Code integration)
read -p "Do you want to install VS Code? (y/n): " install_vscode
if [[ $install_vscode =~ ^[Yy]$ ]]; then
    print_status "INFO" "Installing VS Code..."
    
    # Add Microsoft GPG key and repository
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    
    sudo apt update
    sudo apt install -y code
    
    if command -v code &> /dev/null; then
        print_status "SUCCESS" "VS Code installed successfully"
        print_status "INFO" "You can now install Claude extensions in VS Code"
    else
        print_status "ERROR" "VS Code installation failed"
    fi
fi

echo "========================================="
echo "Development tools setup complete!"
echo "========================================="
