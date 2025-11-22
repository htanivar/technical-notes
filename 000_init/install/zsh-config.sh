#!/bin/bash

#==============================================================================
# Oh My Zsh Universal Installation Script
# Version: 1.0
# Description: Comprehensive Oh My Zsh installer with multi-architecture support
# Author: System Administrator
# Requirements: Must be run as root
#==============================================================================

set -euo pipefail

# Global Variables
readonly SCRIPT_NAME="$(basename "$0")"
readonly LOG_DIR="/tmp"
readonly LOG_FILE="${LOG_DIR}/omz_install_$(date +%Y%m%d_%H%M%S).log"
readonly ERROR_LOG="${LOG_DIR}/omz_install_error_$(date +%Y%m%d_%H%M%S).log"
readonly HELP_FILE="/tmp/omz_post_install_help.txt"
readonly OMZ_REPO="https://github.com/ohmyzsh/ohmyzsh.git"
readonly INSTALL_DIR="/usr/local/share/oh-my-zsh"
readonly TEMP_DIR="/tmp/omz_install_$$"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Arrays to track operations for cleanup
declare -a CREATED_FILES=()
declare -a CREATED_DIRS=()
declare -a INSTALLED_PACKAGES=()

#==============================================================================
# Utility Functions
#==============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"

    if [[ "$level" == "ERROR" ]]; then
        echo "[$timestamp] [$level] $message" >> "$ERROR_LOG"
    fi
}

print_colored() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

error_exit() {
    local message="$1"
    local exit_code="${2:-1}"
    log "ERROR" "$message"
    print_colored "$RED" "ERROR: $message"
    cleanup_on_failure
    exit "$exit_code"
}

success_msg() {
    local message="$1"
    log "INFO" "$message"
    print_colored "$GREEN" "✓ $message"
}

warning_msg() {
    local message="$1"
    log "WARN" "$message"
    print_colored "$YELLOW" "⚠ $message"
}

info_msg() {
    local message="$1"
    log "INFO" "$message"
    print_colored "$BLUE" "ℹ $message"
}

#==============================================================================
# System Detection Functions
#==============================================================================

detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    elif [[ -f /etc/redhat-release ]]; then
        echo "rhel"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

detect_architecture() {
    local arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)
            echo "x86_64"
            ;;
        i386|i686)
            echo "i386"
            ;;
        armv6l)
            echo "armv6l"
            ;;
        armv7l)
            echo "armv7l"
            ;;
        aarch64|arm64)
            echo "aarch64"
            ;;
        *)
            echo "$arch"
            ;;
    esac
}

detect_package_manager() {
    local os="$1"
    case "$os" in
        ubuntu|debian)
            echo "apt"
            ;;
        centos|rhel|fedora)
            if command -v dnf >/dev/null 2>&1; then
                echo "dnf"
            else
                echo "yum"
            fi
            ;;
        arch)
            echo "pacman"
            ;;
        alpine)
            echo "apk"
            ;;
        macos)
            echo "brew"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

#==============================================================================
# Prerequisite Check Functions
#==============================================================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root. Use: sudo $0"
    fi
    success_msg "Root privileges confirmed"
}

check_internet() {
    info_msg "Checking internet connectivity..."
    if ! ping -c 1 google.com >/dev/null 2>&1 && ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        error_exit "No internet connection available"
    fi
    success_msg "Internet connectivity confirmed"
}

install_package() {
    local package="$1"
    local pm="$2"
    local os="$3"

    info_msg "Installing $package..."

    case "$pm" in
        apt)
            if apt-get update && apt-get install -y "$package"; then
                INSTALLED_PACKAGES+=("$package")
                success_msg "$package installed successfully"
                return 0
            fi
            ;;
        dnf)
            if dnf install -y "$package"; then
                INSTALLED_PACKAGES+=("$package")
                success_msg "$package installed successfully"
                return 0
            fi
            ;;
        yum)
            if yum install -y "$package"; then
                INSTALLED_PACKAGES+=("$package")
                success_msg "$package installed successfully"
                return 0
            fi
            ;;
        pacman)
            if pacman -S --noconfirm "$package"; then
                INSTALLED_PACKAGES+=("$package")
                success_msg "$package installed successfully"
                return 0
            fi
            ;;
        apk)
            if apk add "$package"; then
                INSTALLED_PACKAGES+=("$package")
                success_msg "$package installed successfully"
                return 0
            fi
            ;;
        brew)
            if brew install "$package"; then
                INSTALLED_PACKAGES+=("$package")
                success_msg "$package installed successfully"
                return 0
            fi
            ;;
    esac

    return 1
}

check_prerequisites() {
    local os="$1"
    local pm="$2"

    info_msg "Checking prerequisites..."

    # Check for required commands
    local required_commands=("git" "curl" "zsh")
    local missing_commands=()

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done

    # Install missing commands
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        warning_msg "Missing required packages: ${missing_commands[*]}"

        for cmd in "${missing_commands[@]}"; do
            local package_name="$cmd"

            # Handle special package names
            case "$os" in
                centos|rhel)
                    [[ "$cmd" == "zsh" ]] && package_name="zsh"
                    ;;
            esac

            if ! install_package "$package_name" "$pm" "$os"; then
                error_exit "Failed to install required package: $package_name"
            fi
        done
    fi

    success_msg "All prerequisites satisfied"
}

#==============================================================================
# Installation Functions
#==============================================================================

create_temp_directory() {
    info_msg "Creating temporary directory..."
    if mkdir -p "$TEMP_DIR"; then
        CREATED_DIRS+=("$TEMP_DIR")
        success_msg "Temporary directory created: $TEMP_DIR"
    else
        error_exit "Failed to create temporary directory"
    fi
}

download_ohmyzsh() {
    info_msg "Downloading Oh My Zsh..."
    cd "$TEMP_DIR"

    if git clone --depth=1 "$OMZ_REPO" ohmyzsh; then
        success_msg "Oh My Zsh downloaded successfully"
    else
        error_exit "Failed to download Oh My Zsh"
    fi
}

install_ohmyzsh() {
    info_msg "Installing Oh My Zsh to $INSTALL_DIR..."

    # Create installation directory
    if mkdir -p "$INSTALL_DIR"; then
        CREATED_DIRS+=("$INSTALL_DIR")
    else
        error_exit "Failed to create installation directory"
    fi

    # Copy files
    if cp -r "$TEMP_DIR/ohmyzsh/"* "$INSTALL_DIR/"; then
        success_msg "Oh My Zsh files copied successfully"
    else
        error_exit "Failed to copy Oh My Zsh files"
    fi

    # Set proper permissions
    chmod -R 755 "$INSTALL_DIR"
    success_msg "Permissions set correctly"
}

configure_for_users() {
    info_msg "Configuring Oh My Zsh for all users..."

    # Create global configuration script
    local global_config="/etc/profile.d/ohmyzsh.sh"
    cat > "$global_config" << 'EOF'
#!/bin/bash
# Oh My Zsh global configuration

if [ -n "$ZSH_VERSION" ]; then
    export ZSH="/usr/local/share/oh-my-zsh"
    export ZSH_THEME="robbyrussell"

    # Enable useful plugins
    plugins=(git sudo history-substring-search)

    # Source Oh My Zsh
    if [ -f "$ZSH/oh-my-zsh.sh" ]; then
        source "$ZSH/oh-my-zsh.sh"
    fi
fi
EOF

    chmod 644 "$global_config"
    CREATED_FILES+=("$global_config")
    success_msg "Global configuration created"

    # Create user setup script
    local user_setup="/usr/local/bin/setup-ohmyzsh"
    cat > "$user_setup" << 'EOF'
#!/bin/bash
# User Oh My Zsh setup script

USER_HOME="$HOME"
USER_ZSHRC="$USER_HOME/.zshrc"

if [ ! -f "$USER_ZSHRC" ]; then
    cp /usr/local/share/oh-my-zsh/templates/zshrc.zsh-template "$USER_ZSHRC"
    sed -i 's|export ZSH=.*|export ZSH="/usr/local/share/oh-my-zsh"|' "$USER_ZSHRC"
    echo "Oh My Zsh configured for user: $(whoami)"
else
    echo "Oh My Zsh already configured for user: $(whoami)"
fi
EOF

    chmod 755 "$user_setup"
    CREATED_FILES+=("$user_setup")
    success_msg "User setup script created"
}

#==============================================================================
# Verification Functions
#==============================================================================

verify_installation() {
    info_msg "Verifying installation..."

    # Check if Oh My Zsh directory exists
    if [[ ! -d "$INSTALL_DIR" ]]; then
        error_exit "Installation directory not found"
    fi

    # Check if main script exists
    if [[ ! -f "$INSTALL_DIR/oh-my-zsh.sh" ]]; then
        error_exit "Oh My Zsh main script not found"
    fi

    # Check if themes directory exists
    if [[ ! -d "$INSTALL_DIR/themes" ]]; then
        error_exit "Themes directory not found"
    fi

    # Check if plugins directory exists
    if [[ ! -d "$INSTALL_DIR/plugins" ]]; then
        error_exit "Plugins directory not found"
    fi

    success_msg "Installation verification completed successfully"
}

#==============================================================================
# Help File Generation
#==============================================================================

create_help_file() {
    info_msg "Creating help file..."

    cat > "$HELP_FILE" << 'EOF'
# Oh My Zsh Post-Installation Configuration Guide

## Overview
Oh My Zsh has been successfully installed system-wide and is available for all users.

## For Individual Users

### Setup Oh My Zsh for your account:
```bash
/usr/local/bin/setup-ohmyzsh
```

### Change your default shell to zsh:
```bash
chsh -s $(which zsh)
```

### Logout and login again to apply changes.

## Configuration

### Installation Location:
- Oh My Zsh: /usr/local/share/oh-my-zsh
- Global config: /etc/profile.d/ohmyzsh.sh
- User setup script: /usr/local/bin/setup-ohmyzsh

### Customization:
1. Edit your ~/.zshrc file to customize themes and plugins
2. Available themes: ls /usr/local/share/oh-my-zsh/themes/
3. Available plugins: ls /usr/local/share/oh-my-zsh/plugins/

### Popular Themes:
- robbyrussell (default)
- agnoster
- powerlevel10k (requires separate installation)
- spaceship (requires separate installation)

### Useful Plugins:
- git: Git aliases and functions
- sudo: Press ESC twice to add sudo to current command
- history-substring-search: Search history with up/down arrows
- zsh-autosuggestions (requires separate installation)
- zsh-syntax-highlighting (requires separate installation)

## Troubleshooting

### If zsh is not your default shell:
```bash
echo $SHELL
chsh -s $(which zsh)
```

### If Oh My Zsh is not loading:
1. Check if ~/.zshrc exists and contains Oh My Zsh configuration
2. Run: source ~/.zshrc
3. Check global config: cat /etc/profile.d/ohmyzsh.sh

### For permission issues:
```bash
sudo chmod -R 755 /usr/local/share/oh-my-zsh
```

## Additional Resources
- Official documentation: https://ohmyz.sh/
- GitHub repository: https://github.com/ohmyzsh/ohmyzsh
- Community themes: https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
- Community plugins: https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins

## Log Files
- Installation log: Check /tmp/ for omz_install_*.log files
- Error log: Check /tmp/ for omz_install_error_*.log files
EOF

    chmod 644 "$HELP_FILE"
    success_msg "Help file created: $HELP_FILE"
}

#==============================================================================
# Cleanup Functions
#==============================================================================

cleanup_temp() {
    info_msg "Cleaning up temporary files..."
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        success_msg "Temporary files cleaned up"
    fi
}

cleanup_on_failure() {
    warning_msg "Installation failed. Performing cleanup..."

    # Remove created files
    for file in "${CREATED_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            log "INFO" "Removed file: $file"
        fi
    done

    # Remove created directories
    for dir in "${CREATED_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            rm -rf "$dir"
            log "INFO" "Removed directory: $dir"
        fi
    done

    # Remove installed packages (optional - commented out to avoid breaking system)
    # for package in "${INSTALLED_PACKAGES[@]}"; do
    #     log "INFO" "Consider removing package: $package"
    # done

    cleanup_temp

    print_colored "$RED" "Cleanup completed. Check error log: $ERROR_LOG"
}

#==============================================================================
# Main Installation Function
#==============================================================================

main() {
    print_colored "$BLUE" "Oh My Zsh Universal Installation Script"
    print_colored "$BLUE" "======================================"

    log "INFO" "Starting Oh My Zsh installation"
    log "INFO" "Script: $SCRIPT_NAME"
    log "INFO" "Log file: $LOG_FILE"
    log "INFO" "Error log: $ERROR_LOG"

    # System detection
    local os=$(detect_os)
    local arch=$(detect_architecture)
    local pm=$(detect_package_manager "$os")

    info_msg "Detected OS: $os"
    info_msg "Detected Architecture: $arch"
    info_msg "Package Manager: $pm"

    # Handle unsupported systems
    if [[ "$os" == "windows" ]]; then
        error_exit "Windows is not supported. Please use WSL (Windows Subsystem for Linux)"
    fi

    if [[ "$pm" == "unknown" ]]; then
        error_exit "Unsupported package manager for OS: $os"
    fi

    # Pre-installation checks
    check_root
    check_internet
    check_prerequisites "$os" "$pm"

    # Installation process
    create_temp_directory
    download_ohmyzsh
    install_ohmyzsh
    configure_for_users

    # Post-installation
    verify_installation
    create_help_file
    cleanup_temp

    # Success message
    print_colored "$GREEN" "\n🎉 Oh My Zsh installation completed successfully!"
    print_colored "$GREEN" "📖 Please read the help file: $HELP_FILE"
    print_colored "$GREEN" "📋 Installation log: $LOG_FILE"

    log "INFO" "Oh My Zsh installation completed successfully"

    # Display next steps
    print_colored "$YELLOW" "\nNext steps for users:"
    print_colored "$YELLOW" "1. Run: /usr/local/bin/setup-ohmyzsh"
    print_colored "$YELLOW" "2. Run: chsh -s \$(which zsh)"
    print_colored "$YELLOW" "3. Logout and login again"
}

#==============================================================================
# Script Entry Point
#==============================================================================

# Handle script arguments
case "${1:-}" in
    -h|--help)
        cat << 'EOF'
Oh My Zsh Universal Installation Script

Usage: sudo ./install_ohmyzsh.sh [OPTIONS]

Options:
  -h, --help    Show this help message
  -v, --version Show version information

Requirements:
  - Must be run as root
  - Internet connection required
  - Supported OS: Linux distributions, macOS

The script will:
  - Detect your system architecture and OS
  - Install required prerequisites
  - Download and install Oh My Zsh system-wide
  - Configure it for all users
  - Create setup scripts and help documentation
  - Provide detailed logging

Log files will be created in /tmp/ directory.
EOF
        exit 0
        ;;
    -v|--version)
        echo "Oh My Zsh Universal Installation Script v1.0"
        exit 0
        ;;
    "")
        # No arguments, proceed with installation
        main
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use -h or --help for usage information"
        exit 1
        ;;
esac
