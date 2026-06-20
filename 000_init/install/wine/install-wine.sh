#!/bin/bash

###############################################################################
# Universal Wine Installation Script
# Supports: Debian/Ubuntu, Fedora/RHEL/CentOS, Arch/Manjaro, openSUSE, 
#           macOS (via Homebrew), Windows (Git Bash / WSL2)
# Author: Automated Script Generator
# Date: 2026-06-20
###############################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="/var/log/wine-install-$(date +%Y%m%d-%H%M%S).log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/wine-backup-$(date +%Y%m%d-%H%M%S)"

###############################################################################
# UTILITY FUNCTIONS
###############################################################################

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✓${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ✗${NC} $1" | tee -a "$LOG_FILE"
}

die() {
    log_error "$1"
    exit 1
}

###############################################################################
# SUDO CHECK
###############################################################################

check_sudo() {
    log "Checking for root/sudo privileges..."

    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        # Windows Git Bash - no sudo needed, but check for admin
        if ! net session &>/dev/null; then
            die "This script requires Administrator privileges on Windows. Please run as Administrator."
        fi
        log_success "Running with Administrator privileges (Windows)"
        return 0
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - check for sudo
        if [[ $EUID -ne 0 ]]; then
            if ! sudo -n true 2>/dev/null; then
                die "This script requires sudo privileges on macOS. Please run with sudo or ensure passwordless sudo is configured."
            fi
        fi
        log_success "Running with sudo privileges (macOS)"
        return 0
    fi

    # Linux
    if [[ $EUID -ne 0 ]]; then
        die "This script must be run as root or with sudo on Linux. Please run: sudo $0"
    fi

    log_success "Running with root privileges"
}

###############################################################################
# DETECT OPERATING SYSTEM
###############################################################################

detect_os() {
    log "Detecting operating system..."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            OS_ID="$ID"
            OS_VERSION_ID="$VERSION_ID"
            OS_NAME="$PRETTY_NAME"
            OS_FAMILY="debian"

            case "$ID" in
                ubuntu|debian|linuxmint|pop|elementary|zorin|mx)
                    OS_FAMILY="debian"
                    ;;
                fedora|rhel|centos|rocky|almalinux|oracle)
                    OS_FAMILY="rhel"
                    ;;
                arch|manjaro|endeavouros|garuda)
                    OS_FAMILY="arch"
                    ;;
                opensuse*|suse*)
                    OS_FAMILY="suse"
                    ;;
                *)
                    OS_FAMILY="debian"
                    log_warning "Unknown Linux distribution '$ID'. Defaulting to Debian-based procedures."
                    ;;
            esac
        else
            OS_FAMILY="debian"
            OS_NAME="Unknown Linux"
            log_warning "Cannot detect Linux distribution. Defaulting to Debian-based procedures."
        fi

    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_FAMILY="macos"
        OS_NAME="macOS $(sw_vers -productVersion 2>/dev/null || echo 'Unknown')"

    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        OS_FAMILY="windows"
        OS_NAME="Windows (Git Bash/Cygwin)"

    else
        die "Unsupported operating system: $OSTYPE"
    fi

    log_success "Detected: $OS_NAME (Family: $OS_FAMILY)"
}

###############################################################################
# PREREQUISITE CHECKS
###############################################################################

check_prerequisites() {
    log "Checking prerequisites..."

    local missing_prereqs=()

    # Check for essential commands
    case "$OS_FAMILY" in
        debian|rhel|arch|suse)
            command -v curl &>/dev/null || missing_prereqs+=("curl")
            command -v wget &>/dev/null || missing_prereqs+=("wget")
            command -v gpg &>/dev/null || missing_prereqs+=("gpg")
            ;;
        macos)
            command -v brew &>/dev/null || missing_prereqs+=("homebrew")
            ;;
        windows)
            # Check for WSL or native Windows
            if [[ -f /proc/version ]] && grep -q "Microsoft" /proc/version; then
                IS_WSL=true
                log "WSL2 detected"
            else
                IS_WSL=false
                log "Native Windows detected"
            fi
            ;;
    esac

    # Check architecture
    ARCH=$(uname -m)
    log "Architecture: $ARCH"

    if [[ "$ARCH" != "x86_64" && "$ARCH" != "amd64" && "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
        log_warning "Architecture $ARCH may not be fully supported by Wine. x86_64/amd64 recommended."
    fi

    # Check disk space (need at least 2GB free)
    if [[ "$OS_FAMILY" != "windows" ]]; then
        local available_space=$(df /tmp 2>/dev/null | awk 'NR==2 {print $4}' || echo "0")
        if [[ "$available_space" != "0" && "$available_space" -lt 2097152 ]]; then  # 2GB in KB
            log_warning "Low disk space in /tmp. At least 2GB recommended."
        fi
    fi

    # Check internet connectivity
    if ! ping -c 1 -W 5 deb.debian.org &>/dev/null && ! ping -c 1 -W 5 google.com &>/dev/null; then
        missing_prereqs+=("internet connectivity")
    fi

    if [[ ${#missing_prereqs[@]} -gt 0 ]]; then
        log_error "Missing prerequisites: ${missing_prereqs[*]}"
        log "Please install the missing prerequisites and try again."

        case "$OS_FAMILY" in
            debian)
                log "Install missing packages with: sudo apt update && sudo apt install -y curl wget gnupg"
                ;;
            rhel)
                log "Install missing packages with: sudo dnf install -y curl wget gnupg2"
                ;;
            arch)
                log "Install missing packages with: sudo pacman -S curl wget gnupg"
                ;;
            suse)
                log "Install missing packages with: sudo zypper install -y curl wget gpg2"
                ;;
            macos)
                log "Install Homebrew from: https://brew.sh"
                ;;
        esac

        die "Prerequisites not met. Cannot continue."
    fi

    log_success "All prerequisites met"
}

###############################################################################
# BACKUP CURRENT STATE
###############################################################################

create_backup() {
    log "Creating backup of current state..."

    mkdir -p "$BACKUP_DIR"

    # Backup package lists
    case "$OS_FAMILY" in
        debian)
            dpkg --get-selections > "$BACKUP_DIR/dpkg-selections.txt" 2>/dev/null || true
            cp /etc/apt/sources.list "$BACKUP_DIR/" 2>/dev/null || true
            cp -r /etc/apt/sources.list.d "$BACKUP_DIR/" 2>/dev/null || true
            ;;
        rhel)
            rpm -qa > "$BACKUP_DIR/rpm-packages.txt" 2>/dev/null || true
            cp -r /etc/yum.repos.d "$BACKUP_DIR/" 2>/dev/null || true
            ;;
        arch)
            pacman -Q > "$BACKUP_DIR/pacman-packages.txt" 2>/dev/null || true
            cp -r /etc/pacman.d "$BACKUP_DIR/" 2>/dev/null || true
            ;;
        suse)
            rpm -qa > "$BACKUP_DIR/rpm-packages.txt" 2>/dev/null || true
            cp -r /etc/zypp/repos.d "$BACKUP_DIR/" 2>/dev/null || true
            ;;
        macos)
            brew list > "$BACKUP_DIR/brew-packages.txt" 2>/dev/null || true
            ;;
    esac

    # Backup Wine config if exists
    if [[ -d "$HOME/.wine" ]]; then
        log_warning "Existing Wine prefix found at ~/.wine. It will be preserved."
        echo "$HOME/.wine" > "$BACKUP_DIR/wine-prefix-location.txt"
    fi

    # Save environment state
    env > "$BACKUP_DIR/environment.txt" 2>/dev/null || true

    log_success "Backup created at: $BACKUP_DIR"
    echo "$BACKUP_DIR" > "$SCRIPT_DIR/.wine-backup-location"
}

###############################################################################
# INSTALL WINE
###############################################################################

install_wine_debian() {
    log "Installing Wine on Debian-based system..."

    # Enable 32-bit architecture
    dpkg --add-architecture i386

    # Update package list
    apt-get update

    # Install prerequisites
    apt-get install -y wget gnupg2 software-properties-common

    # Add WineHQ repository
    local CODENAME
    if [[ -f /etc/os-release ]]; then
        CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
    else
        CODENAME="bookworm"
    fi

    # For Debian 13 (trixie), use bookworm repo as trixie might not have dedicated WineHQ repo yet
    if [[ "$CODENAME" == "trixie" ]]; then
        CODENAME="bookworm"
        log_warning "Debian 13 (trixie) detected. Using bookworm WineHQ repository."
    fi

    # Add WineHQ GPG key
    mkdir -pm755 /etc/apt/keyrings
    wget -qO - https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key

    # Add repository
    echo "deb [signed-by=/etc/apt/keyrings/winehq-archive.key] https://dl.winehq.org/wine-builds/debian/ $CODENAME main" > /etc/apt/sources.list.d/winehq-$CODENAME.sources

    apt-get update

    # Install Wine
    apt-get install -y --install-recommends winehq-stable

    # Install Winetricks
    apt-get install -y winetricks

    log_success "Wine installed successfully on Debian-based system"
}

install_wine_rhel() {
    log "Installing Wine on RHEL-based system..."

    # Enable EPEL repository
    if command -v dnf &>/dev/null; then
        dnf install -y epel-release
        dnf config-manager --set-enabled crb 2>/dev/null || true

        # Add WineHQ repository
        dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/$(rpm -E %fedora)/winehq.repo 2>/dev/null || {
            log_warning "WineHQ repo not available for this version. Using distribution packages."
        }

        dnf install -y wine
        dnf install -y winetricks
    else
        yum install -y epel-release
        yum install -y wine
        yum install -y winetricks
    fi

    log_success "Wine installed successfully on RHEL-based system"
}

install_wine_arch() {
    log "Installing Wine on Arch-based system..."

    # Enable multilib repository
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        log "Enabling multilib repository..."
        cat >> /etc/pacman.conf << 'EOF'

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
    fi

    pacman -Sy --noconfirm
    pacman -S --noconfirm wine winetricks

    log_success "Wine installed successfully on Arch-based system"
}

install_wine_suse() {
    log "Installing Wine on openSUSE..."

    zypper refresh
    zypper install -y wine winetricks

    log_success "Wine installed successfully on openSUSE"
}

install_wine_macos() {
    log "Installing Wine on macOS..."

    if ! command -v brew &>/dev/null; then
        die "Homebrew is required but not installed. Please install Homebrew first: https://brew.sh"
    fi

    # Install Xcode Command Line Tools if not present
    if ! xcode-select -p &>/dev/null; then
        log "Installing Xcode Command Line Tools..."
        xcode-select --install
        log_warning "Please complete the Xcode Command Line Tools installation and re-run this script."
        exit 0
    fi

    # Install Wine using Homebrew
    brew install --cask wine-stable
    brew install winetricks

    log_success "Wine installed successfully on macOS"
}

install_wine_windows() {
    log "Installing Wine on Windows..."

    if [[ "${IS_WSL:-false}" == "true" ]]; then
        log "WSL2 detected. Installing Wine for Linux inside WSL..."
        detect_os
        check_prerequisites

        case "$OS_FAMILY" in
            debian)
                install_wine_debian
                ;;
            rhel)
                install_wine_rhel
                ;;
            arch)
                install_wine_arch
                ;;
            *)
                die "WSL distribution not supported by this script."
                ;;
        esac
    else
        # Native Windows with Git Bash
        log "Native Windows detected. Wine is not typically needed on Windows as it's a Windows compatibility layer for Linux/macOS."
        log "If you need to run Windows applications, you can run them natively."
        log "If you need Wine for development/testing purposes, consider using WSL2."

        # Optionally install Chocolatey for package management
        if ! command -v choco &>/dev/null; then
            log_warning "Chocolatey not found. For Windows package management, consider installing Chocolatey."
        fi

        die "Wine installation on native Windows is not supported. Use WSL2 for Wine on Windows."
    fi
}

###############################################################################
# POST-INSTALLATION CONFIGURATION
###############################################################################

post_install() {
    log "Performing post-installation configuration..."

    # Initialize Wine prefix
    if command -v wine &>/dev/null; then
        log "Initializing Wine prefix..."
        WINEARCH=win64 winecfg &>/dev/null || true

        # Verify installation
        WINE_VERSION=$(wine --version 2>/dev/null || echo "unknown")
        log_success "Wine version: $WINE_VERSION"
    fi

    # Create useful aliases and desktop entries (Linux only)
    if [[ "$OS_FAMILY" != "macos" && "$OS_FAMILY" != "windows" ]]; then
        # Create a simple wrapper script
        cat > /usr/local/bin/wine-wrapper << 'EOF'
#!/bin/bash
# Wine wrapper script for better integration
export WINEDEBUG=-all
export WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"

if [[ $# -eq 0 ]]; then
    echo "Usage: wine-wrapper <windows-application.exe>"
    exit 1
fi

wine "$@"
EOF
        chmod +x /usr/local/bin/wine-wrapper
    fi

    log_success "Post-installation configuration complete"
}

###############################################################################
# GENERATE UNINSTALL SCRIPT
###############################################################################

generate_uninstall_script() {
    log "Generating uninstall script..."

    local UNINSTALL_SCRIPT="$SCRIPT_DIR/uninstall-wine.sh"
    local BACKUP_LOC="$BACKUP_DIR"

    cat > "$UNINSTALL_SCRIPT" << EOF
#!/bin/bash
###############################################################################
# Wine Uninstall Script
# Generated: $(date)
# This script restores your system to the state before Wine installation
###############################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "\${BLUE}[\$(date '+%Y-%m-%d %H:%M:%S')]\${NC} \$1"
}

log_success() {
    echo -e "\${GREEN}[\$(date '+%Y-%m-%d %H:%M:%S')] ✓\${NC} \$1"
}

log_warning() {
    echo -e "\${YELLOW}[\$(date '+%Y-%m-%d %H:%M:%S')] ⚠\${NC} \$1"
}

log_error() {
    echo -e "\${RED}[\$(date '+%Y-%m-%d %H:%M:%S')] ✗\${NC} \$1"
}

# Check for root/sudo
if [[ \$EUID -ne 0 ]]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

BACKUP_DIR="$BACKUP_LOC"

if [[ ! -d "\$BACKUP_DIR" ]]; then
    log_warning "Backup directory not found at \$BACKUP_DIR"
    log "Attempting to locate backup..."
    BACKUP_DIR=\$(find "$(dirname "$BACKUP_DIR")" -maxdepth 1 -name "wine-backup-*" -type d | sort | tail -1)
    if [[ -z "\$BACKUP_DIR" ]]; then
        die "No backup found. Cannot safely uninstall."
    fi
fi

log "Using backup from: \$BACKUP_DIR"

###############################################################################
# DETECT OS
###############################################################################

if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS_ID="\$ID"
else
    OS_ID="unknown"
fi

case "\$OS_ID" in
    ubuntu|debian|linuxmint|pop|elementary|zorin|mx)
        OS_FAMILY="debian"
        ;;
    fedora|rhel|centos|rocky|almalinux|oracle)
        OS_FAMILY="rhel"
        ;;
    arch|manjaro|endeavouros|garuda)
        OS_FAMILY="arch"
        ;;
    opensuse*|suse*)
        OS_FAMILY="suse"
        ;;
    *)
        OS_FAMILY="unknown"
        ;;
esac

###############################################################################
# UNINSTALL WINE
###############################################################################

log "Uninstalling Wine..."

case "\$OS_FAMILY" in
    debian)
        # Remove Wine packages
        apt-get remove --purge -y winehq-stable wine-stable wine-stable-amd64 wine-stable-i386 wine winetricks 2>/dev/null || true
        apt-get autoremove -y

        # Remove WineHQ repository
        rm -f /etc/apt/sources.list.d/winehq-*.sources
        rm -f /etc/apt/keyrings/winehq-archive.key

        # Restore original sources if backed up
        if [[ -f "\$BACKUP_DIR/sources.list" ]]; then
            cp "\$BACKUP_DIR/sources.list" /etc/apt/sources.list
        fi
        if [[ -d "\$BACKUP_DIR/sources.list.d" ]]; then
            cp -r "\$BACKUP_DIR/sources.list.d"/* /etc/apt/sources.list.d/ 2>/dev/null || true
        fi

        apt-get update
        ;;

    rhel)
        if command -v dnf &>/dev/null; then
            dnf remove -y wine winetricks 2>/dev/null || true
        else
            yum remove -y wine winetricks 2>/dev/null || true
        fi

        # Remove WineHQ repo
        rm -f /etc/yum.repos.d/winehq.repo
        ;;

    arch)
        pacman -Rns --noconfirm wine winetricks 2>/dev/null || true

        # Disable multilib if it was enabled by us (check if it was in backup)
        if [[ ! -d "\$BACKUP_DIR/pacman.d" ]]; then
            log_warning "Multilib repository may have been enabled. Please disable manually in /etc/pacman.conf if needed."
        fi
        ;;

    suse)
        zypper remove -y wine winetricks 2>/dev/null || true
        ;;

    *)
        log_warning "Unknown OS family. Attempting generic removal..."
        ;;
esac

# Remove wrapper script
rm -f /usr/local/bin/wine-wrapper

# Remove Wine prefix (ask user)
if [[ -d "\$HOME/.wine" ]]; then
    log_warning "Wine prefix found at \$HOME/.wine"
    read -p "Remove Wine prefix? This will delete all installed Windows apps and data. [y/N]: " response
    if [[ "\$response" =~ ^[Yy]\$ ]]; then
        rm -rf "\$HOME/.wine"
        log_success "Wine prefix removed"
    else
        log "Wine prefix preserved at \$HOME/.wine"
    fi
fi

# Remove desktop entries
rm -f /usr/share/applications/wine*.desktop 2>/dev/null || true
rm -f \$HOME/.local/share/applications/wine*.desktop 2>/dev/null || true

log_success "Wine has been uninstalled successfully"
log "If you encounter issues, you can restore from backup at: \$BACKUP_DIR"
EOF

    chmod +x "$UNINSTALL_SCRIPT"
    log_success "Uninstall script generated: $UNINSTALL_SCRIPT"
}

###############################################################################
# GENERATE USAGE GUIDE
###############################################################################

generate_usage_guide() {
    log "Generating comprehensive usage guide..."

    local GUIDE_FILE="$SCRIPT_DIR/WINE-USAGE-GUIDE.md"
    local WINE_VERSION=$(wine --version 2>/dev/null || echo "installed version")

    cat > "$GUIDE_FILE" << 'EOF'
# Wine Usage Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Basic Commands](#basic-commands)
3. [Configuration](#configuration)
4. [Installing Windows Applications](#installing-windows-applications)
5. [Winetricks](#winetricks)
6. [Troubleshooting](#troubleshooting)
7. [Performance Tuning](#performance-tuning)
8. [Uninstallation](#uninstallation)

---

## Introduction

Wine (Wine Is Not an Emulator) is a compatibility layer capable of running Windows applications on Linux, macOS, and other POSIX-compliant operating systems. It translates Windows API calls into POSIX calls on-the-fly, eliminating the performance and memory penalties of other methods.

**Installed Version:** See output of `wine --version`

---

## Basic Commands

### Check Wine Version
```bash
wine --version
```

### Initialize Wine Prefix
```bash
WINEARCH=win64 winecfg
```

### Run a Windows Application
```bash
wine /path/to/application.exe
```

### Run with Specific Windows Version
```bash
WINEPREFIX=~/.wine-custom winecfg
# Set Windows version in the GUI, then run:
WINEPREFIX=~/.wine-custom wine application.exe
```

### List Wine Processes
```bash
wineserver -p
```

### Kill All Wine Processes
```bash
wineserver -k
```

---

## Configuration

### Wine Prefix (Virtual C: Drive)
- Default location: `~/.wine`
- Environment variable: `WINEPREFIX`
- Each prefix is an isolated Windows environment

### Creating a New Prefix
```bash
WINEPREFIX=~/.wine-new winecfg
```

### Architecture Selection
- 64-bit (default): `WINEARCH=win64`
- 32-bit: `WINEARCH=win32`

### Configuration Tool
```bash
winecfg
```
- Set Windows version (Windows 7, 10, etc.)
- Configure graphics (desktop emulation, resolution)
- Configure audio drivers
- Set drive mappings

---

## Installing Windows Applications

### Standard Installation
```bash
wine /path/to/installer.exe
```

### MSI Installers
```bash
wine msiexec /i /path/to/installer.msi
```

### Common Installation Directories
- Programs: `~/.wine/drive_c/Program Files/`
- System: `~/.wine/drive_c/windows/`
- User data: `~/.wine/drive_c/users/$USER/`

---

## Winetricks

Winetricks is a helper script to install libraries and components needed by some Windows applications.

### Launch Winetricks GUI
```bash
winetricks
```

### Install Common Components
```bash
# Install .NET Framework
winetricks dotnet48

# Install Visual C++ Runtimes
winetricks vcrun2019

# Install DirectX
winetricks dxvk

# Install Core Fonts
winetricks corefonts

# Install All Common Components
winetricks dotnet48 vcrun2019 corefonts dxvk
```

### List Available Components
```bash
winetricks list-all
```

---

## Troubleshooting

### Application Won't Start
1. Check if the application is supported: https://appdb.winehq.org
2. Try different Windows version in `winecfg`
3. Install required libraries using `winetricks`
4. Check for missing DLLs: `WINEDEBUG=+loaddll wine app.exe`

### Graphics Issues
```bash
# Enable CSMT (Command Stream Multi-Threading)
wine reg add "HKCU\Software\Wine\Direct3D" /v csmt /d 1 /t reg_dword

# Use DXVK for DirectX 9/10/11
winetricks dxvk
```

### Audio Issues
```bash
winecfg
# Go to Audio tab and select correct driver (usually ALSA or PulseAudio)
```

### Reset Wine Prefix
```bash
rm -rf ~/.wine
winecfg
```

### Debug Output
```bash
WINEDEBUG=+all wine app.exe 2>&1 | tee wine-debug.log
```

---

## Performance Tuning

### Environment Variables
```bash
# Disable debug messages (improves performance)
export WINEDEBUG=-all

# Enable CSMT
export WINEESYNC=1

# Use Fsync (if kernel supports it)
export WINEFSYNC=1

# Enable large address aware
export WINE_LARGE_ADDRESS_AWARE=1
```

### DXVK (Vulkan-based D3D9/10/11)
```bash
winetricks dxvk
# Requires Vulkan-capable GPU and drivers
```

### Esync/Fsync
- **Esync**: Requires raised file descriptor limits
- **Fsync**: Requires Linux kernel 5.16+ with fsync patch

### GPU Drivers
Ensure you have proper GPU drivers installed:
- **NVIDIA**: proprietary drivers recommended
- **AMD**: Mesa RADV (Vulkan) or AMDVLK
- **Intel**: Mesa ANV (Vulkan)

---

## Uninstallation

To completely remove Wine from your system, run the generated uninstall script:

```bash
sudo bash uninstall-wine.sh
```

This will:
1. Remove Wine packages
2. Remove WineHQ repositories
3. Optionally remove your Wine prefix (and all installed Windows apps)
4. Restore system configuration from backup

---

## Additional Resources

- **WineHQ Official Website**: https://www.winehq.org
- **Application Database**: https://appdb.winehq.org
- **Winetricks Repository**: https://github.com/Winetricks/winetricks
- **Wine Documentation**: https://wiki.winehq.org
- **Community Support**: https://forum.winehq.org

---

*Generated on: EOF
    echo "$(date)" >> "$GUIDE_FILE"
    cat >> "$GUIDE_FILE" << 'EOF'
*
EOF

    log_success "Usage guide generated: $GUIDE_FILE"
}

###############################################################################
# MAIN EXECUTION
###############################################################################

main() {
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           Universal Wine Installation Script                   ║${NC}"
    echo -e "${GREEN}║      Supports: Linux, macOS, Windows (WSL/Git Bash)            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo

    # Check sudo first
    check_sudo

    # Detect OS
    detect_os

    # Check prerequisites
    check_prerequisites

    # Create backup
    create_backup

    # Install Wine based on OS family
    case "$OS_FAMILY" in
        debian)
            install_wine_debian
            ;;
        rhel)
            install_wine_rhel
            ;;
        arch)
            install_wine_arch
            ;;
        suse)
            install_wine_suse
            ;;
        macos)
            install_wine_macos
            ;;
        windows)
            install_wine_windows
            ;;
        *)
            die "Unsupported OS family: $OS_FAMILY"
            ;;
    esac

    # Post-installation
    post_install

    # Generate uninstall script
    generate_uninstall_script

    # Generate usage guide
    generate_usage_guide

    echo
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              Installation Complete!                            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
    log_success "Wine has been installed successfully!"
    log "Log file: $LOG_FILE"
    log "Backup location: $BACKUP_DIR"
    log "Uninstall script: $SCRIPT_DIR/uninstall-wine.sh"
    log "Usage guide: $SCRIPT_DIR/WINE-USAGE-GUIDE.md"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Run 'wine --version' to verify installation"
    echo "  2. Run 'winecfg' to configure Wine"
    echo "  3. Read WINE-USAGE-GUIDE.md for detailed usage instructions"
    echo "  4. Use 'winetricks' to install additional Windows components"
    echo
}

# Run main function
main "$@"
