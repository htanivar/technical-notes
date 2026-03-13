#!/bin/bash

# PostgreSQL Uninstall Script
# Supports: Ubuntu, MX-Linux, Raspberry Pi (Raspbian), Windows (Git Bash)

set -e

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

# Function to detect OS
detect_os() {
    print_message "Detecting operating system..." "$BLUE"
    
    # Check for Windows (Git Bash/MSYS2/Cygwin)
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WINDIR" ]]; then
        echo "windows"
        return
    fi
    
    # Check for Linux distributions
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        if [[ $OS == *"Ubuntu"* ]]; then
            echo "ubuntu"
        elif [[ $OS == *"MX"* ]] || [[ $OS == *"MX Linux"* ]]; then
            echo "mx-linux"
        elif [[ $OS == *"Raspbian"* ]] || [[ $OS == *"Raspberry Pi"* ]]; then
            echo "raspberry-pi"
        else
            echo "unknown-linux"
        fi
    else
        echo "unknown"
    fi
}

# Function to uninstall PostgreSQL on Ubuntu
uninstall_ubuntu() {
    print_message "\nUninstalling PostgreSQL from Ubuntu..." "$YELLOW"
    
    # Stop PostgreSQL service
    print_message "Stopping PostgreSQL service..." "$BLUE"
    sudo systemctl stop postgresql || true
    sudo systemctl disable postgresql || true
    
    # Uninstall PostgreSQL packages
    print_message "Removing PostgreSQL packages..." "$BLUE"
    sudo apt-get remove --purge -y postgresql postgresql-* postgresql-client-* postgresql-common
    
    # Remove PostgreSQL directories
    print_message "Removing PostgreSQL directories..." "$BLUE"
    sudo rm -rf /etc/postgresql
    sudo rm -rf /var/lib/postgresql
    sudo rm -rf /var/log/postgresql
    
    # Remove PostgreSQL user and group
    print_message "Removing PostgreSQL user and group..." "$BLUE"
    sudo deluser postgres || true
    sudo delgroup postgres || true
    
    # Clean up
    print_message "Cleaning up..." "$BLUE"
    sudo apt-get autoremove -y
    sudo apt-get autoclean
    
    print_message "PostgreSQL has been completely removed from Ubuntu!" "$GREEN"
}

# Function to uninstall PostgreSQL on MX-Linux
uninstall_mx_linux() {
    print_message "\nUninstalling PostgreSQL from MX-Linux..." "$YELLOW"
    
    # Stop PostgreSQL service
    print_message "Stopping PostgreSQL service..." "$BLUE"
    sudo systemctl stop postgresql || true
    sudo systemctl disable postgresql || true
    
    # Uninstall PostgreSQL packages
    print_message "Removing PostgreSQL packages..." "$BLUE"
    sudo apt-get remove --purge -y postgresql postgresql-* postgresql-client-* postgresql-common
    
    # Remove PostgreSQL directories
    print_message "Removing PostgreSQL directories..." "$BLUE"
    sudo rm -rf /etc/postgresql
    sudo rm -rf /var/lib/postgresql
    sudo rm -rf /var/log/postgresql
    
    # Remove PostgreSQL user and group
    print_message "Removing PostgreSQL user and group..." "$BLUE"
    sudo deluser postgres || true
    sudo delgroup postgres || true
    
    # Clean up
    print_message "Cleaning up..." "$BLUE"
    sudo apt-get autoremove -y
    sudo apt-get autoclean
    
    print_message "PostgreSQL has been completely removed from MX-Linux!" "$GREEN"
}

# Function to uninstall PostgreSQL on Raspberry Pi (Raspbian)
uninstall_raspberry_pi() {
    print_message "\nUninstalling PostgreSQL from Raspberry Pi (Raspbian)..." "$YELLOW"
    
    # Stop PostgreSQL service
    print_message "Stopping PostgreSQL service..." "$BLUE"
    sudo systemctl stop postgresql || true
    sudo systemctl disable postgresql || true
    
    # Uninstall PostgreSQL packages
    print_message "Removing PostgreSQL packages..." "$BLUE"
    sudo apt-get remove --purge -y postgresql postgresql-* postgresql-client-* postgresql-common
    
    # Remove PostgreSQL directories
    print_message "Removing PostgreSQL directories..." "$BLUE"
    sudo rm -rf /etc/postgresql
    sudo rm -rf /var/lib/postgresql
    sudo rm -rf /var/log/postgresql
    
    # Remove PostgreSQL user and group
    print_message "Removing PostgreSQL user and group..." "$BLUE"
    sudo deluser postgres || true
    sudo delgroup postgres || true
    
    # Clean up
    print_message "Cleaning up..." "$BLUE"
    sudo apt-get autoremove -y
    sudo apt-get autoclean
    
    print_message "PostgreSQL has been completely removed from Raspberry Pi!" "$GREEN"
}

# Function to uninstall PostgreSQL on Windows (Git Bash)
uninstall_windows() {
    print_message "\nUninstalling PostgreSQL from Windows (Git Bash)..." "$YELLOW"
    
    # Check if PostgreSQL is installed via Chocolatey
    if command -v choco &> /dev/null; then
        print_message "PostgreSQL installation detected via Chocolatey..." "$BLUE"
        read -p "Do you want to uninstall PostgreSQL via Chocolatey? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            choco uninstall postgresql -y
            print_message "PostgreSQL uninstalled via Chocolatey!" "$GREEN"
        fi
    fi
    
    # Check common PostgreSQL installation paths
    POSTGRES_PATHS=(
        "/c/Program Files/PostgreSQL"
        "/c/Program Files (x86)/PostgreSQL"
    )
    
    for path in "${POSTGRES_PATHS[@]}"; do
        if [[ -d "$path" ]]; then
            print_message "Found PostgreSQL installation at: $path" "$BLUE"
            read -p "Do you want to remove this directory? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf "$path"
                print_message "Removed: $path" "$GREEN"
            fi
        fi
    done
    
    # Check for PostgreSQL in PATH
    if command -v psql &> /dev/null; then
        print_message "PostgreSQL commands are still in PATH." "$YELLOW"
        print_message "You may need to manually remove PostgreSQL from your system PATH." "$YELLOW"
    fi
    
    # Check for PostgreSQL service
    if command -v sc &> /dev/null; then
        if sc query "postgresql" &> /dev/null; then
            print_message "PostgreSQL Windows service detected." "$YELLOW"
            read -p "Do you want to remove the PostgreSQL Windows service? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sc stop "postgresql" || true
                sc delete "postgresql" || true
                print_message "PostgreSQL service removed!" "$GREEN"
            fi
        fi
    fi
    
    print_message "PostgreSQL uninstallation process completed on Windows!" "$GREEN"
    print_message "Note: Some components may need to be removed manually from Control Panel." "$YELLOW"
}

# Function to handle unknown OS
handle_unknown() {
    print_message "\nUnknown operating system detected!" "$RED"
    print_message "This script supports: Ubuntu, MX-Linux, Raspberry Pi (Raspbian), and Windows (Git Bash)" "$YELLOW"
    print_message "Your OS detection results:" "$BLUE"
    echo "OSTYPE: $OSTYPE"
    if [[ -f /etc/os-release ]]; then
        cat /etc/os-release
    fi
    exit 1
}

# Main execution
main() {
    print_message "=========================================" "$GREEN"
    print_message "    PostgreSQL Uninstall Script" "$GREEN"
    print_message "=========================================" "$GREEN"
    
    # Check if running with sufficient privileges
    if [[ "$EUID" -eq 0 ]]; then
        print_message "Warning: Running as root. This is not recommended." "$RED"
    fi
    
    # Confirm uninstallation
    print_message "\nThis script will completely remove PostgreSQL from your system." "$YELLOW"
    read -p "Are you sure you want to continue? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message "Uninstallation cancelled." "$RED"
        exit 0
    fi
    
    # Detect and handle OS
    OS=$(detect_os)
    print_message "Detected OS: $OS" "$GREEN"
    
    case $OS in
        "ubuntu")
            uninstall_ubuntu
            ;;
        "mx-linux")
            uninstall_mx_linux
            ;;
        "raspberry-pi")
            uninstall_raspberry_pi
            ;;
        "windows")
            uninstall_windows
            ;;
        *)
            handle_unknown
            ;;
    esac
    
    print_message "\n=========================================" "$GREEN"
    print_message "    PostgreSQL uninstallation complete!" "$GREEN"
    print_message "=========================================" "$GREEN"
}

# Run main function
main
