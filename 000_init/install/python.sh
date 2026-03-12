#!/bin/bash

# Python 3 Installation Script for Multiple OS
# Supports: Raspberry Pi OS, Ubuntu, Fedora, RedHat, Windows (via Git Bash)

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_message() {
    echo -e "${2}${1}${NC}"
}

# Function to check if Python 3 is already installed
check_python() {
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1)
        print_message "✅ Python 3 is already installed: $PYTHON_VERSION" "$GREEN"
        return 0
    else
        print_message "❌ Python 3 is not installed" "$YELLOW"
        return 1
    fi
}

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WSLENV" ]] || [[ -n "$GIT_BASH" ]]; then
        echo "windows"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|raspbian)
                echo "debian"
                ;;
            fedora)
                echo "fedora"
                ;;
            rhel|centos|redhat)
                echo "redhat"
                ;;
            *)
                echo "unknown"
                ;;
        esac
    else
        echo "unknown"
    fi
}

# Function to install Python 3 on Debian-based systems (Ubuntu, Raspberry Pi OS)
install_debian() {
    print_message "📦 Updating package lists..." "$BLUE"
    sudo apt-get update
    
    print_message "📦 Installing Python 3 and required packages..." "$BLUE"
    sudo apt-get install -y python3 python3-pip python3-venv python3-dev
    
    # Install additional useful packages
    sudo apt-get install -y build-essential libssl-dev libffi-dev
}

# Function to install Python 3 on Fedora
install_fedora() {
    print_message "📦 Updating package lists..." "$BLUE"
    sudo dnf check-update || true
    
    print_message "📦 Installing Python 3 and required packages..." "$BLUE"
    sudo dnf install -y python3 python3-pip python3-devel
    
    # Install additional useful packages
    sudo dnf install -y gcc openssl-devel bzip2-devel libffi-devel
}

# Function to install Python 3 on RedHat/CentOS
install_redhat() {
    print_message "📦 Installing EPEL repository..." "$BLUE"
    sudo yum install -y epel-release
    
    print_message "📦 Updating package lists..." "$BLUE"
    sudo yum check-update || true
    
    print_message "📦 Installing Python 3 and required packages..." "$BLUE"
    sudo yum install -y python3 python3-pip python3-devel
    
    # Install additional useful packages
    sudo yum install -y gcc openssl-devel bzip2-devel libffi-devel
}

# Function to install Python 3 on Windows (via Git Bash)
install_windows() {
    print_message "🪟 Windows detected - installing via Git Bash..." "$BLUE"
    
    # Check if winget is available (Windows 10/11)
    if command -v winget.exe &> /dev/null; then
        print_message "📦 Installing Python using winget..." "$BLUE"
        winget.exe install Python.Python.3
    else
        # Alternative: Download and install using PowerShell
        print_message "📦 Downloading Python installer..." "$BLUE"
        
        # Get latest Python 3 version (you can specify a version if needed)
        PYTHON_VERSION="3.11.5"  # Update this to desired version
        PYTHON_INSTALLER="python-${PYTHON_VERSION}-amd64.exe"
        PYTHON_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/${PYTHON_INSTALLER}"
        
        # Download Python installer
        curl -L -o "$PYTHON_INSTALLER" "$PYTHON_URL"
        
        if [ -f "$PYTHON_INSTALLER" ]; then
            print_message "📦 Installing Python ${PYTHON_VERSION} silently..." "$BLUE"
            # Silent installation with PATH addition
            ./"$PYTHON_INSTALLER" /quiet InstallAllUsers=1 PrependPath=1
            
            # Clean up installer
            rm "$PYTHON_INSTALLER"
        else
            print_message "❌ Failed to download Python installer" "$RED"
            print_message "💡 Please download Python manually from: https://www.python.org/downloads/" "$YELLOW"
            return 1
        fi
    fi
    
    # Add Python to PATH for current session
    export PATH="$PATH:/c/Users/$USER/AppData/Local/Programs/Python/Python311:/c/Users/$USER/AppData/Local/Programs/Python/Python311/Scripts"
    export PATH="$PATH:/c/Program Files/Python311:/c/Program Files/Python311/Scripts"
}

# Function to verify installation
verify_installation() {
    print_message "\n🔍 Verifying installation..." "$BLUE"
    
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1)
        print_message "✅ Python installed: $PYTHON_VERSION" "$GREEN"
        
        # Check pip
        if command -v pip3 &> /dev/null; then
            PIP_VERSION=$(pip3 --version 2>&1 | cut -d' ' -f1-2)
            print_message "✅ pip installed: $PIP_VERSION" "$GREEN"
        else
            print_message "❌ pip3 not found" "$RED"
        fi
    else
        print_message "❌ Installation verification failed" "$RED"
        return 1
    fi
}

# Main installation function
main() {
    print_message "=========================================" "$BLUE"
    print_message "   Python 3 Installation Script" "$BLUE"
    print_message "=========================================" "$BLUE"
    
    # Check if Python is already installed
    if check_python; then
        read -p "Python 3 is already installed. Do you want to reinstall? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_message "Installation cancelled" "$YELLOW"
            exit 0
        fi
    fi
    
    # Detect OS
    OS_TYPE=$(detect_os)
    print_message "🔍 Detected OS: $OS_TYPE" "$BLUE"
    
    # Install Python based on OS
    case "$OS_TYPE" in
        debian)
            install_debian
            ;;
        fedora)
            install_fedora
            ;;
        redhat)
            install_redhat
            ;;
        windows)
            install_windows
            ;;
        *)
            print_message "❌ Unsupported or unknown operating system" "$RED"
            print_message "💡 Please install Python 3 manually from: https://www.python.org/downloads/" "$YELLOW"
            exit 1
            ;;
    esac
    
    # Verify installation
    verify_installation
    
    print_message "\n=========================================" "$GREEN"
    print_message "   Installation Complete!" "$GREEN"
    print_message "=========================================" "$GREEN"
    print_message "💡 You can now use: python3, pip3, and python3 -m venv" "$YELLOW"
}

# Run main function
main
