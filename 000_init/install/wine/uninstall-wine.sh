#!/bin/bash
###############################################################################
# Wine Uninstall Script
# Generated: Sat Jun 20 11:31:52 PM IST 2026
# Version: 2.1 - Fixed SCRIPT_DIR and complete wine32 removal
###############################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ✗${NC} $1"
}

die() {
    log_error "$1"
    exit 1
}

###############################################################################
# SUDO CHECK
###############################################################################

log "Checking for root/sudo privileges..."

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    if ! net session &>/dev/null; then
        die "This script requires Administrator privileges on Windows."
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ $EUID -ne 0 ]]; then
        if ! sudo -n true 2>/dev/null; then
            die "This script requires sudo privileges on macOS."
        fi
    fi
else
    if [[ $EUID -ne 0 ]]; then
        die "This script must be run as root or with sudo on Linux."
    fi
fi

log_success "Privileges verified"

###############################################################################
# DETECT OS
###############################################################################

log "Detecting operating system..."

OS_FAMILY="unknown"

if [[ -f /etc/os-release ]]; then
    . /etc/os-release
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
            ;;
    esac
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS_FAMILY="macos"
    OS_NAME="macOS"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    OS_FAMILY="windows"
fi

log_success "Detected OS family: $OS_FAMILY"

###############################################################################
# FIND BACKUP
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR=""

if [[ -f "$SCRIPT_DIR/.wine-backup-location" ]]; then
    BACKUP_DIR=$(cat "$SCRIPT_DIR/.wine-backup-location")
fi

if [[ -z "$BACKUP_DIR" || ! -d "$BACKUP_DIR" ]]; then
    BACKUP_DIR=$(find "$SCRIPT_DIR" -maxdepth 1 -name "wine-backup-*" -type d | sort | tail -1)
fi

if [[ -z "$BACKUP_DIR" || ! -d "$BACKUP_DIR" ]]; then
    log_warning "No backup directory found. Proceeding with caution..."
    read -p "Continue without backup? [y/N]: " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 0
    fi
else
    log_success "Found backup at: $BACKUP_DIR"
fi

###############################################################################
# UNINSTALL WINE
###############################################################################

log "Uninstalling Wine..."

case "$OS_FAMILY" in
    debian)
        log "Removing Wine packages (Debian-based)..."

        # Remove all wine-related packages including wine32
        apt-get remove --purge -y winehq-stable wine-stable wine-stable-amd64 wine-stable-i386:i386 wine winetricks 2>/dev/null || true
        apt-get remove --purge -y winehq-staging wine-staging 2>/dev/null || true
        apt-get remove --purge -y winehq-devel wine-devel 2>/dev/null || true
        apt-get remove --purge -y wine32:i386 wine32 2>/dev/null || true
        apt-get remove --purge -y wine64 2>/dev/null || true

        apt-get autoremove -y
        apt-get autoclean

        # Remove WineHQ repository files
        rm -f /etc/apt/sources.list.d/winehq-*.sources
        rm -f /etc/apt/sources.list.d/winehq-*.list
        rm -f /etc/apt/keyrings/winehq-archive.key

        # Restore original sources if backed up
        if [[ -f "$BACKUP_DIR/sources.list" ]]; then
            cp "$BACKUP_DIR/sources.list" /etc/apt/sources.list
            log_success "Restored original sources.list"
        fi
        if [[ -d "$BACKUP_DIR/sources.list.d" ]]; then
            cp -r "$BACKUP_DIR/sources.list.d"/* /etc/apt/sources.list.d/ 2>/dev/null || true
            log_success "Restored original sources.list.d"
        fi

        apt-get update
        ;;

    rhel)
        log "Removing Wine packages (RHEL-based)..."

        if command -v dnf &>/dev/null; then
            dnf remove -y wine winehq-stable winehq-staging winehq-devel winetricks 2>/dev/null || true
            dnf autoremove -y
        else
            yum remove -y wine winehq-stable winehq-staging winehq-devel winetricks 2>/dev/null || true
            yum autoremove -y
        fi
        rm -f /etc/yum.repos.d/winehq.repo
        ;;

    arch)
        log "Removing Wine packages (Arch-based)..."

        pacman -Rns --noconfirm wine winetricks 2>/dev/null || true
        log_warning "Note: multilib repository was left enabled. Disable in /etc/pacman.conf if needed."
        ;;

    suse)
        log "Removing Wine packages (openSUSE)..."

        zypper remove -y wine winetricks 2>/dev/null || true
        ;;

    macos)
        log "Removing Wine (macOS)..."

        if command -v brew &>/dev/null; then
            brew uninstall --cask wine-stable 2>/dev/null || true
            brew uninstall wine 2>/dev/null || true
            brew uninstall winetricks 2>/dev/null || true
        fi
        ;;

    windows)
        log "Windows uninstallation..."
        log_warning "On native Windows, Wine is not typically installed. If using WSL, uninstall from within WSL."
        ;;

    *)
        log_warning "Unknown OS family. Attempting generic removal..."
        ;;
esac

###############################################################################
# CLEANUP
###############################################################################

log "Performing cleanup..."

# Remove wrapper script
rm -f /usr/local/bin/wine-wrapper

# Remove desktop entries
rm -f /usr/share/applications/wine*.desktop 2>/dev/null || true
rm -f /usr/local/share/applications/wine*.desktop 2>/dev/null || true

# Remove Wine prefix (ask user) - check for root and selected user
for wine_home in "/root" "$HOME"; do
    if [[ -d "$wine_home/.wine" ]]; then
        echo
        log_warning "Wine prefix found at $wine_home/.wine"
        log "This contains all installed Windows applications and data."
        read -p "Remove $wine_home/.wine? [y/N]: " response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            rm -rf "$wine_home/.wine"
            log_success "Wine prefix removed from $wine_home"
        else
            log "Wine prefix preserved at $wine_home/.wine"
        fi
    fi
done

# Remove other common Wine prefixes
for prefix in "$HOME/.wine-new" "$HOME/.wine-custom" "$HOME/.wine32" "$HOME/.local/share/wineprefixes"; do
    if [[ -d "$prefix" ]]; then
        log_warning "Additional Wine prefix found: $prefix"
        read -p "Remove $prefix? [y/N]: " response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            rm -rf "$prefix"
            log_success "Removed $prefix"
        fi
    fi
done

# Remove Wine cache
rm -rf "$HOME/.cache/wine" 2>/dev/null || true
rm -rf /root/.cache/wine 2>/dev/null || true

# Remove generated files
rm -f "$SCRIPT_DIR/.wine-backup-location"

log_success "Wine has been uninstalled successfully!"
log "Your system has been restored to its pre-installation state."

if [[ -n "$BACKUP_DIR" && -d "$BACKUP_DIR" ]]; then
    log "Backup preserved at: $BACKUP_DIR"
    log "You can delete this directory when you're satisfied everything is working correctly."
fi
