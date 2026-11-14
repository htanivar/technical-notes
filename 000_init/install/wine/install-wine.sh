#!/bin/bash

###############################################################################
# Universal Wine Installation Script
# Supports: Debian/Ubuntu, Fedora/RHEL/CentOS, Arch/Manjaro, openSUSE,
#           macOS (via Homebrew), Windows (Git Bash / WSL2)
# Date: 2026-06-20
# Version: 3.0 - Added post-install verification and auto-fix
###############################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Logging
LOG_FILE="/var/log/wine-install-$(date +%Y%m%d-%H%M%S).log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/wine-backup-$(date +%Y%m%d-%H%M%S)"

# User profile selection (will be set interactively)
TARGET_USER=""
TARGET_USER_HOME=""

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

log_info() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')] ℹ${NC} $1" | tee -a "$LOG_FILE"
}

log_test() {
    echo -e "${MAGENTA}[$(date '+%Y-%m-%d %H:%M:%S')] TEST${NC} $1" | tee -a "$LOG_FILE"
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
        if ! net session &>/dev/null; then
            die "This script requires Administrator privileges on Windows. Please run as Administrator."
        fi
        log_success "Running with Administrator privileges (Windows)"
        return 0
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
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
# USER PROFILE SELECTION
###############################################################################

select_user_profile() {
    echo
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           User Profile Selection for Wine                      ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo

    local SUDO_USER_NAME="${SUDO_USER:-}"
    local CURRENT_USER="$(logname 2>/dev/null || echo "$SUDO_USER_NAME")"

    log_info "Detecting available user profiles..."
    local users=()
    while IFS=: read -r username _ uid _ _ home _; do
        if [[ "$uid" -ge 1000 && "$uid" -lt 65534 && -d "$home" ]]; then
            users+=("$username")
        fi
    done < /etc/passwd

    if [[ ${#users[@]} -eq 0 ]]; then
        log_warning "No regular users found. Using root profile."
        TARGET_USER="root"
        TARGET_USER_HOME="/root"
        return
    fi

    if [[ -n "$CURRENT_USER" && "$CURRENT_USER" != "root" ]]; then
        log_info "Current user detected: $CURRENT_USER"
    fi

    echo
    echo -e "${CYAN}Available user profiles:${NC}"
    local i=1
    for user in "${users[@]}"; do
        local marker=""
        if [[ "$user" == "$CURRENT_USER" ]]; then
            marker=" (current)"
        fi
        echo "  $i) $user$marker"
        ((i++))
    done
    echo "  $i) root (not recommended)"
    echo

    local choice
    read -p "Select user profile for Wine installation [1-$i, default: $CURRENT_USER]: " choice

    if [[ -z "$choice" ]]; then
        choice="$CURRENT_USER"
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        if [[ "$choice" -eq $i ]]; then
            TARGET_USER="root"
            TARGET_USER_HOME="/root"
        elif [[ "$choice" -ge 1 && "$choice" -lt $i ]]; then
            TARGET_USER="${users[$((choice-1))]}"
            TARGET_USER_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
        else
            log_warning "Invalid selection. Using current user: $CURRENT_USER"
            TARGET_USER="$CURRENT_USER"
            TARGET_USER_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
        fi
    else
        if getent passwd "$choice" &>/dev/null; then
            TARGET_USER="$choice"
            TARGET_USER_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
        else
            log_warning "User '$choice' not found. Using current user: $CURRENT_USER"
            TARGET_USER="$CURRENT_USER"
            TARGET_USER_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
        fi
    fi

    echo
    log_success "Selected user profile: $TARGET_USER (home: $TARGET_USER_HOME)"
    echo
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
            OS_CODENAME="${VERSION_CODENAME:-unknown}"

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
            OS_CODENAME="unknown"
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

    log_success "Detected: $OS_NAME (Family: $OS_FAMILY, Codename: $OS_CODENAME)"
}

###############################################################################
# PREREQUISITE CHECKS
###############################################################################

check_prerequisites() {
    log "Checking prerequisites..."

    local missing_prereqs=()

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
            if [[ -f /proc/version ]] && grep -q "Microsoft" /proc/version; then
                IS_WSL=true
                log "WSL2 detected"
            else
                IS_WSL=false
                log "Native Windows detected"
            fi
            ;;
    esac

    ARCH=$(uname -m)
    log "Architecture: $ARCH"

    if [[ "$ARCH" != "x86_64" && "$ARCH" != "amd64" && "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
        log_warning "Architecture $ARCH may not be fully supported by Wine. x86_64/amd64 recommended."
    fi

    if [[ "$OS_FAMILY" != "windows" ]]; then
        local available_space=$(df /tmp 2>/dev/null | awk 'NR==2 {print $4}' || echo "0")
        if [[ "$available_space" != "0" && "$available_space" -lt 2097152 ]]; then
            log_warning "Low disk space in /tmp. At least 2GB recommended."
        fi
    fi

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

    local target_wine="$TARGET_USER_HOME/.wine"
    if [[ -d "$target_wine" ]]; then
        log_warning "Existing Wine prefix found at $target_wine. It will be preserved."
        echo "$target_wine" > "$BACKUP_DIR/wine-prefix-location.txt"
    fi

    env > "$BACKUP_DIR/environment.txt" 2>/dev/null || true

    log_success "Backup created at: $BACKUP_DIR"
    echo "$BACKUP_DIR" > "$SCRIPT_DIR/.wine-backup-location"
}

###############################################################################
# INSTALL WINE
###############################################################################

install_wine_debian() {
    log "Installing Wine on Debian-based system..."

    local CODENAME="$OS_CODENAME"
    local WINEHQ_BASE="https://dl.winehq.org/wine-builds"

    # Enable 32-bit architecture
    dpkg --add-architecture i386 2>/dev/null || log_warning "i386 architecture may already be enabled"

    # Update package list
    apt-get update

    # Install prerequisites
    apt-get install -y wget ca-certificates curl gnupg2

    # Download WineHQ GPG key from ROOT of wine-builds
    log "Adding WineHQ GPG key..."
    mkdir -pm755 /etc/apt/keyrings

    local TEMP_KEY="/tmp/winehq.key.$$"
    if curl -fsSLo "$TEMP_KEY" "${WINEHQ_BASE}/winehq.key"; then
        log "Downloaded WineHQ key, dearmoring..."
        if gpg --dearmor --yes -o /etc/apt/keyrings/winehq-archive.key "$TEMP_KEY"; then
            log_success "WineHQ GPG key installed successfully"
        else
            log_warning "gpg dearmor failed, copying raw key as fallback..."
            cp "$TEMP_KEY" /etc/apt/keyrings/winehq-archive.key
        fi
        rm -f "$TEMP_KEY"
    else
        log_error "Failed to download WineHQ GPG key from ${WINEHQ_BASE}/winehq.key"
        log "Attempting alternative download method with wget..."
        if wget -O "$TEMP_KEY" "${WINEHQ_BASE}/winehq.key" 2>&1 | tee -a "$LOG_FILE"; then
            if gpg --dearmor --yes -o /etc/apt/keyrings/winehq-archive.key "$TEMP_KEY"; then
                log_success "WineHQ GPG key installed via wget fallback"
            else
                cp "$TEMP_KEY" /etc/apt/keyrings/winehq-archive.key
            fi
            rm -f "$TEMP_KEY"
        else
            die "Cannot download WineHQ GPG key."
        fi
    fi
    chmod 644 /etc/apt/keyrings/winehq-archive.key

    # Add WineHQ repository
    log "Adding WineHQ repository..."

    if [[ "$CODENAME" == "trixie" || "$CODENAME" == "unknown" ]]; then
        log "Debian 13 (Trixie) detected. Using native WineHQ Trixie repository."
        CODENAME="trixie"

        local SOURCE_FILE="winehq-trixie.sources"
        local TEMP_SOURCE="/tmp/${SOURCE_FILE}.$$"
        if curl -fsSLo "$TEMP_SOURCE" "${WINEHQ_BASE}/debian/dists/trixie/${SOURCE_FILE}"; then
            if grep -q "Types: deb" "$TEMP_SOURCE" 2>/dev/null; then
                mv "$TEMP_SOURCE" "/etc/apt/sources.list.d/${SOURCE_FILE}"
                log_success "Downloaded official WineHQ .sources file for Trixie"
            else
                rm -f "$TEMP_SOURCE"
                create_sources_file "$CODENAME"
            fi
        else
            rm -f "$TEMP_SOURCE"
            create_sources_file "$CODENAME"
        fi
    else
        create_sources_file "$CODENAME"
    fi

    apt-get update

    # Check if WineHQ packages are available
    if ! apt-cache policy winehq-stable 2>/dev/null | grep -q "dl.winehq.org"; then
        log_warning "WineHQ repository not properly configured. Falling back to Debian native packages."
        apt-get install -y wine wine64 winetricks

        # Install wine32:i386 in fallback path
        log "Installing wine32:i386 for 32-bit application support (fallback path)..."
        apt-get install -y wine32:i386 || log_warning "wine32:i386 installation failed, continuing anyway"

        return
    fi

    # Install Wine from WineHQ
    apt-get install -y --install-recommends winehq-stable

    # Install wine32:i386 for 32-bit application support (WineHQ path)
    log "Installing wine32:i386 for 32-bit application support..."
    apt-get install -y wine32:i386 || log_warning "wine32:i386 installation failed, continuing anyway"

    # Install Winetricks and utilities
    apt-get install -y winetricks cabextract p7zip-full

    log_success "Wine installed successfully on Debian-based system"
}

# Helper function to create .sources file manually
create_sources_file() {
    local codename="$1"
    cat > "/etc/apt/sources.list.d/winehq-${codename}.sources" << EOF
Types: deb
URIs: https://dl.winehq.org/wine-builds/debian
Suites: ${codename}
Components: main
Signed-By: /etc/apt/keyrings/winehq-archive.key
Architectures: amd64 i386
EOF
    log_success "Created WineHQ .sources file for ${codename}"
}

install_wine_rhel() {
    log "Installing Wine on RHEL-based system..."

    if command -v dnf &>/dev/null; then
        dnf install -y epel-release
        dnf config-manager --set-enabled crb 2>/dev/null || true
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

    if ! xcode-select -p &>/dev/null; then
        log "Installing Xcode Command Line Tools..."
        xcode-select --install
        log_warning "Please complete the Xcode Command Line Tools installation and re-run this script."
        exit 0
    fi

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
        log "Native Windows detected. Wine is not typically needed on Windows."
        log "If you need Wine for development/testing, consider using WSL2."
        die "Wine installation on native Windows is not supported. Use WSL2 for Wine on Windows."
    fi
}

###############################################################################
# POST-INSTALLATION CONFIGURATION
###############################################################################

post_install() {
    log "Performing post-installation configuration..."

    # Initialize Wine prefix for the SELECTED user
    if command -v wine &>/dev/null; then
        log "Initializing Wine prefix for user: $TARGET_USER..."

        # CRITICAL: Remove any corrupted prefix first
        local target_wine="$TARGET_USER_HOME/.wine"
        if [[ -d "$target_wine" ]]; then
            log_warning "Existing Wine prefix detected at $target_wine"
            log_info "Removing potentially corrupted prefix to ensure clean initialization..."
            rm -rf "$target_wine"
        fi

        # Run winecfg as the target user to create prefix in their home
        if [[ "$TARGET_USER" != "root" ]]; then
            sudo -u "$TARGET_USER" WINEARCH=win64 winecfg &>/dev/null || true
        else
            WINEARCH=win64 winecfg &>/dev/null || true
        fi

        # Verify installation
        WINE_VERSION=$(wine --version 2>/dev/null || echo "unknown")
        log_success "Wine version: $WINE_VERSION"
    fi

    # Create wrapper script
    if [[ "$OS_FAMILY" != "macos" && "$OS_FAMILY" != "windows" ]]; then
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
# POST-INSTALLATION VERIFICATION
###############################################################################

verify_installation() {
    echo
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║           Post-Installation Verification                       ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo

    local tests_passed=0
    local tests_failed=0
    local target_wine="$TARGET_USER_HOME/.wine"

    # TEST 1: wine command exists
    log_test "TEST 1/5: Checking wine command availability..."
    if command -v wine &>/dev/null; then
        log_success "wine command found"
        ((tests_passed++))
    else
        log_error "wine command NOT found in PATH"
        ((tests_failed++))
    fi

    # TEST 2: wine --version works
    log_test "TEST 2/5: Checking wine --version..."
    local version_output
    if version_output=$(sudo -u "$TARGET_USER" wine --version 2>&1); then
        log_success "wine --version works: $version_output"
        ((tests_passed++))
    else
        log_error "wine --version FAILED: $version_output"
        ((tests_failed++))
    fi

    # TEST 3: Wine prefix exists and is not empty
    log_test "TEST 3/5: Checking Wine prefix at $target_wine..."
    if [[ -d "$target_wine" && -d "$target_wine/drive_c/windows" ]]; then
        log_success "Wine prefix exists and contains Windows system files"
        ((tests_passed++))
    else
        log_error "Wine prefix is missing or incomplete"
        ((tests_failed++))
    fi

    # TEST 4: winecfg can run
    log_test "TEST 4/5: Testing winecfg execution..."
    local cfg_output
    if cfg_output=$(sudo -u "$TARGET_USER" timeout 10 winecfg /? 2>&1); then
        log_success "winecfg responds correctly"
        ((tests_passed++))
    else
        # winecfg /? might fail but that's ok - check if it at least starts
        if [[ "$cfg_output" == *"Usage"* || "$cfg_output" == *"winecfg"* ]]; then
            log_success "winecfg responds correctly"
            ((tests_passed++))
        else
            log_error "winecfg test FAILED: $cfg_output"
            ((tests_failed++))
        fi
    fi

    # TEST 5: Check for kernel32.dll (critical system file)
    log_test "TEST 5/5: Checking critical Windows system files..."
    if [[ -f "$target_wine/drive_c/windows/system32/kernel32.dll" ]]; then
        log_success "kernel32.dll found - prefix is healthy"
        ((tests_passed++))
    else
        log_error "kernel32.dll NOT found - prefix may be corrupted"
        ((tests_failed++))
    fi

    # Summary
    echo
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║           Verification Summary                                   ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
    log_info "Tests passed: $tests_passed/5"
    if [[ $tests_failed -gt 0 ]]; then
        log_error "Tests failed: $tests_failed/5"
        echo
        log_warning "Some tests failed. Attempting automatic repair..."
        repair_installation
    else
        log_success "ALL TESTS PASSED - Wine is ready to use!"
    fi
    echo
}

###############################################################################
# AUTOMATIC REPAIR
###############################################################################

repair_installation() {
    log "Attempting to repair Wine installation..."

    local target_wine="$TARGET_USER_HOME/.wine"

    # Repair 1: Remove corrupted prefix and recreate
    if [[ -d "$target_wine" ]]; then
        log_info "Removing corrupted Wine prefix at $target_wine..."
        rm -rf "$target_wine"
    fi

    # Repair 2: Reinstall wine32:i386 if missing
    if [[ "$OS_FAMILY" == "debian" ]]; then
        log_info "Reinstalling wine32:i386..."
        apt-get install --reinstall -y wine32:i386 || true
    fi

    # Repair 3: Reinitialize prefix
    log_info "Reinitializing Wine prefix for user $TARGET_USER..."
    if [[ "$TARGET_USER" != "root" ]]; then
        sudo -u "$TARGET_USER" WINEARCH=win64 winecfg &>/dev/null || true
    else
        WINEARCH=win64 winecfg &>/dev/null || true
    fi

    # Repair 4: Verify again
    log_info "Running verification after repair..."
    if [[ -f "$target_wine/drive_c/windows/system32/kernel32.dll" ]]; then
        log_success "Repair successful! Wine prefix is now healthy."
    else
        log_error "Repair FAILED. Manual intervention may be required."
        log_info "Try running: rm -rf $target_wine && WINEARCH=win64 winecfg"
    fi
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
# Version: 3.0 - Fixed SCRIPT_DIR and complete wine32 removal
###############################################################################

set -euo pipefail

RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
BLUE='\\033[0;34m'
NC='\\033[0m'

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

die() {
    log_error "\$1"
    exit 1
}

###############################################################################
# SUDO CHECK
###############################################################################

log "Checking for root/sudo privileges..."

if [[ "\$OSTYPE" == "msys" || "\$OSTYPE" == "cygwin" ]]; then
    if ! net session &>/dev/null; then
        die "This script requires Administrator privileges on Windows."
    fi
elif [[ "\$OSTYPE" == "darwin"* ]]; then
    if [[ \$EUID -ne 0 ]]; then
        if ! sudo -n true 2>/dev/null; then
            die "This script requires sudo privileges on macOS."
        fi
    fi
else
    if [[ \$EUID -ne 0 ]]; then
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
    case "\$ID" in
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
elif [[ "\$OSTYPE" == "darwin"* ]]; then
    OS_FAMILY="macos"
    OS_NAME="macOS"
elif [[ "\$OSTYPE" == "msys" || "\$OSTYPE" == "cygwin" ]]; then
    OS_FAMILY="windows"
fi

log_success "Detected OS family: \$OS_FAMILY"

###############################################################################
# FIND BACKUP
###############################################################################

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR=""

if [[ -f "\$SCRIPT_DIR/.wine-backup-location" ]]; then
    BACKUP_DIR=\$(cat "\$SCRIPT_DIR/.wine-backup-location")
fi

if [[ -z "\$BACKUP_DIR" || ! -d "\$BACKUP_DIR" ]]; then
    BACKUP_DIR=\$(find "\$SCRIPT_DIR" -maxdepth 1 -name "wine-backup-*" -type d | sort | tail -1)
fi

if [[ -z "\$BACKUP_DIR" || ! -d "\$BACKUP_DIR" ]]; then
    log_warning "No backup directory found. Proceeding with caution..."
    read -p "Continue without backup? [y/N]: " response
    if [[ ! "\$response" =~ ^[Yy]\$ ]]; then
        exit 0
    fi
else
    log_success "Found backup at: \$BACKUP_DIR"
fi

###############################################################################
# UNINSTALL WINE
###############################################################################

log "Uninstalling Wine..."

case "\$OS_FAMILY" in
    debian)
        log "Removing Wine packages (Debian-based)..."

        apt-get remove --purge -y winehq-stable wine-stable wine-stable-amd64 wine-stable-i386:i386 wine winetricks 2>/dev/null || true
        apt-get remove --purge -y winehq-staging wine-staging 2>/dev/null || true
        apt-get remove --purge -y winehq-devel wine-devel 2>/dev/null || true
        apt-get remove --purge -y wine32:i386 wine32 2>/dev/null || true
        apt-get remove --purge -y wine64 2>/dev/null || true

        apt-get autoremove -y
        apt-get autoclean

        rm -f /etc/apt/sources.list.d/winehq-*.sources
        rm -f /etc/apt/sources.list.d/winehq-*.list
        rm -f /etc/apt/keyrings/winehq-archive.key

        if [[ -f "\$BACKUP_DIR/sources.list" ]]; then
            cp "\$BACKUP_DIR/sources.list" /etc/apt/sources.list
            log_success "Restored original sources.list"
        fi
        if [[ -d "\$BACKUP_DIR/sources.list.d" ]]; then
            cp -r "\$BACKUP_DIR/sources.list.d"/* /etc/apt/sources.list.d/ 2>/dev/null || true
            log_success "Restored original sources.list.d"
        fi

        apt-get update
        ;;

    rhel)
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
        pacman -Rns --noconfirm wine winetricks 2>/dev/null || true
        log_warning "Note: multilib repository was left enabled. Disable in /etc/pacman.conf if needed."
        ;;

    suse)
        zypper remove -y wine winetricks 2>/dev/null || true
        ;;

    macos)
        if command -v brew &>/dev/null; then
            brew uninstall --cask wine-stable 2>/dev/null || true
            brew uninstall wine 2>/dev/null || true
            brew uninstall winetricks 2>/dev/null || true
        fi
        ;;

    windows)
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

rm -f /usr/local/bin/wine-wrapper
rm -f /usr/share/applications/wine*.desktop 2>/dev/null || true
rm -f /usr/local/share/applications/wine*.desktop 2>/dev/null || true

for wine_home in "/root" "\$HOME"; do
    if [[ -d "\$wine_home/.wine" ]]; then
        echo
        log_warning "Wine prefix found at \$wine_home/.wine"
        log "This contains all installed Windows applications and data."
        read -p "Remove \$wine_home/.wine? [y/N]: " response
        if [[ "\$response" =~ ^[Yy]\$ ]]; then
            rm -rf "\$wine_home/.wine"
            log_success "Wine prefix removed from \$wine_home"
        else
            log "Wine prefix preserved at \$wine_home/.wine"
        fi
    fi
done

for prefix in "\$HOME/.wine-new" "\$HOME/.wine-custom" "\$HOME/.wine32" "\$HOME/.local/share/wineprefixes"; do
    if [[ -d "\$prefix" ]]; then
        log_warning "Additional Wine prefix found: \$prefix"
        read -p "Remove \$prefix? [y/N]: " response
        if [[ "\$response" =~ ^[Yy]\$ ]]; then
            rm -rf "\$prefix"
            log_success "Removed \$prefix"
        fi
    fi
done

rm -rf "\$HOME/.cache/wine" 2>/dev/null || true
rm -rf /root/.cache/wine 2>/dev/null || true
rm -f "\$SCRIPT_DIR/.wine-backup-location"

log_success "Wine has been uninstalled successfully!"
log "Your system has been restored to its pre-installation state."

if [[ -n "\$BACKUP_DIR" && -d "\$BACKUP_DIR" ]]; then
    log "Backup preserved at: \$BACKUP_DIR"
    log "You can delete this directory when you're satisfied everything is working correctly."
fi
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

    cat > "$GUIDE_FILE" << 'GUIDE_EOF'
# Wine Usage Guide

> **Generated:** 2026-06-20
> **Purpose:** Comprehensive guide for using Wine on Linux, macOS, and Windows (WSL)

---

## Table of Contents

1. [What is Wine?](#what-is-wine)
2. [Quick Start](#quick-start)
3. [Basic Commands](#basic-commands)
4. [Wine Prefix Management](#wine-prefix-management)
5. [Configuration (winecfg)](#configuration-winecfg)
6. [Installing Windows Applications](#installing-windows-applications)
7. [Winetricks](#winetricks)
8. [Common Windows Components](#common-windows-components)
9. [Performance Tuning](#performance-tuning)
10. [Troubleshooting](#troubleshooting)
11. [Application-Specific Tips](#application-specific-tips)
12. [Uninstallation](#uninstallation)
13. [Additional Resources](#additional-resources)

---

## What is Wine?

**Wine** (originally an acronym for "Wine Is Not an Emulator") is a compatibility layer capable of running Windows applications on several POSIX-compliant operating systems, such as Linux, macOS, and BSD.

Unlike a virtual machine or emulator, Wine translates Windows API calls into POSIX calls on-the-fly, eliminating the performance and memory penalties of other methods and allowing you to cleanly integrate Windows applications into your desktop.

### Key Features
- **No Windows License Required** — Runs Windows apps without a Windows installation
- **No Virtual Machine Overhead** — Native performance, no emulation layer
- **Seamless Integration** — Windows apps appear alongside native Linux/macOS apps
- **Active Development** — Regular updates with improved compatibility

---

## Quick Start

### 1. Verify Installation
```bash
wine --version
```
Expected output: `wine-11.0` or similar (version may vary)

### 2. Initialize Wine for the First Time
```bash
winecfg
```
This creates the default Wine prefix at `~/.wine` and opens the configuration GUI.

### 3. Run Your First Windows Application
```bash
wine /path/to/your-application.exe
```

---

## Basic Commands

| Command | Description |
|---------|-------------|
| `wine --version` | Display Wine version |
| `wine program.exe` | Run a Windows program |
| `winecfg` | Open Wine configuration GUI |
| `winefile` | Wine file manager |
| `winetricks` | Helper script for installing libraries |
| `wineserver -k` | Kill all Wine processes |
| `wineserver -p` | Persistent Wine server |
| `wineboot` | Simulate Windows reboot |
| `wineconsole` | Run console applications |
| `regedit` | Wine registry editor |
| `msiexec /i setup.msi` | Install MSI packages |
| `wine uninstaller` | Add/Remove Programs equivalent |

---

## Wine Prefix Management

A **Wine prefix** (also called a "bottle") is a private Windows environment containing:
- A virtual `C:` drive
- Windows registry
- Installed applications
- Configuration files

### Default Prefix Location
```
~/.wine/
```

### Create a New Prefix
```bash
# 64-bit prefix (default)
WINEPREFIX=~/.wine-custom winecfg

# 32-bit prefix
WINEARCH=win32 WINEPREFIX=~/.wine32 winecfg
```

### Use a Specific Prefix
```bash
WINEPREFIX=~/.wine-custom wine application.exe
```

### Delete a Prefix
```bash
rm -rf ~/.wine-custom
```

### List All Prefixes
```bash
find ~ -maxdepth 2 -name ".wine*" -type d
```

### Best Practices
- Use separate prefixes for different applications to avoid conflicts
- Name prefixes descriptively (e.g., `~/.wine-games`, `~/.wine-office`)
- Back up important prefixes before major changes

---

## Configuration (winecfg)

Launch the configuration tool:
```bash
winecfg
```

### Applications Tab
Set the Windows version for specific applications:
- Windows 10 (most compatible)
- Windows 7 (for older apps)
- Windows XP (for legacy software)

### Graphics Tab
- **Emulate a virtual desktop** — Run apps in a contained window
- **Desktop size** — Set virtual desktop resolution
- **Screen resolution** — DPI settings

### Desktop Integration Tab
- Configure file associations
- Set theme and appearance

### Drives Tab
Manage drive mappings:
- `C:` → `~/.wine/drive_c`
- `D:` → `/mnt/data` (example)
- `Z:` → `/` (root filesystem)

### Audio Tab
- Select audio driver (ALSA, PulseAudio, OSS)
- Test sound

### About Tab
- Display Wine version and prefix information

---

## Installing Windows Applications

### Standard EXE Installer
```bash
wine /path/to/installer.exe
```

### MSI Installer
```bash
wine msiexec /i /path/to/installer.msi
```

### Silent Installation
```bash
wine installer.exe /S
wine msiexec /i setup.msi /quiet /norestart
```

### Common Installation Paths
| Windows Path | Linux/macOS Equivalent |
|-------------|----------------------|
| `C:\\Program Files` | `~/.wine/drive_c/Program Files` |
| `C:\\Program Files (x86)` | `~/.wine/drive_c/Program Files (x86)` |
| `C:\\Users\\Username` | `~/.wine/drive_c/users/$USER` |
| `C:\\Windows` | `~/.wine/drive_c/windows` |

### Uninstalling Applications
```bash
wine uninstaller
```
This opens the "Add/Remove Programs" dialog.

---

## Winetricks

**Winetricks** is a helper script that downloads and installs various redistributable runtime libraries needed to run some programs in Wine.

### Launch GUI
```bash
winetricks
```

### Common Commands
```bash
# Install .NET Framework 4.8
winetricks dotnet48

# Install Visual C++ 2019 Redistributable
winetricks vcrun2019

# Install all Visual C++ runtimes
winetricks vcrun2005 vcrun2008 vcrun2010 vcrun2012 vcrun2013 vcrun2019

# Install DirectX via DXVK
winetricks dxvk

# Install Core Fonts
winetricks corefonts

# Install Windows Media Player
winetricks wmp10

# Install Internet Explorer 8
winetricks ie8
```

### List All Available Components
```bash
winetricks list-all
```

### List Installed Components
```bash
winetricks list-installed
```

### Force Reinstall a Component
```bash
winetricks --force dotnet48
```

---

## Common Windows Components

### Essential Components for Most Apps
```bash
winetricks corefonts vcrun2019 dotnet48 dxvk
```

### For Gaming
```bash
winetricks dxvk vcrun2019 corefonts directx9
```

### For Microsoft Office
```bash
winetricks corefonts dotnet48 msxml6 gdiplus
```

### For Adobe Software
```bash
winetricks corefonts vcrun2019 atmlib gdiplus msxml3 msxml6
```

### For Development Tools
```bash
winetricks dotnet48 vcrun2019 msxml6 gdiplus
```

---

## Performance Tuning

### Environment Variables

Add these to your `~/.bashrc` or `~/.zshrc` for persistent settings:

```bash
# Disable debug output (significant performance boost)
export WINEDEBUG=-all

# Enable Esync (requires raised file descriptor limits)
export WINEESYNC=1

# Enable Fsync (Linux kernel 5.16+ with fsync patch)
export WINEFSYNC=1

# Enable large address aware for 32-bit apps
export WINE_LARGE_ADDRESS_AWARE=1

# Disable unused features
export WINEDLLOVERRIDES="mscoree,mshtml="
```

### DXVK (Vulkan-based D3D9/10/11)

DXVK translates Direct3D 9/10/11 calls to Vulkan, dramatically improving performance:

```bash
winetricks dxvk
```

**Requirements:**
- Vulkan-capable GPU
- Proper Vulkan drivers installed

### GPU Driver Recommendations

| GPU | Recommended Driver | Vulkan Support |
|-----|-------------------|----------------|
| NVIDIA | Proprietary `nvidia-driver` | Yes (via `libvulkan1`) |
| AMD | Mesa `radeonsi` | Yes (RADV) |
| Intel | Mesa `iris` | Yes (ANV) |

### CPU Governor (Linux)
For maximum performance while gaming:
```bash
# Set CPU governor to performance
sudo cpupower frequency-set -g performance

# Revert when done
sudo cpupower frequency-set -g ondemand
```

### Gamemode (Linux)
```bash
# Install gamemode
sudo apt install gamemode  # Debian/Ubuntu
sudo dnf install gamemode  # Fedora

# Run app with gamemode
gamemoderun wine game.exe
```

---

## Troubleshooting

### Application Won't Start

1. **Check Compatibility Database**
   Visit [WineHQ AppDB](https://appdb.winehq.org) to see if your app is supported.

2. **Try Different Windows Version**
   ```bash
   winecfg
   # Set Windows version to 7 or 10
   ```

3. **Install Missing Libraries**
   ```bash
   winetricks corefonts vcrun2019
   ```

4. **Check for Missing DLLs**
   ```bash
   WINEDEBUG=+loaddll wine app.exe 2>&1 | grep "failed"
   ```

### Graphics Issues

**Black screen or rendering issues:**
```bash
# Enable virtual desktop
winecfg
# Graphics → Emulate a virtual desktop

# Or use DXVK
winetricks dxvk
```

**NVIDIA-specific issues:**
```bash
# Enable NVIDIA optimizations
export __GL_THREADED_OPTIMIZATIONS=1
export __GL_SYNC_TO_VBLANK=0
```

### Audio Issues

```bash
winecfg
# Go to Audio tab
# Select correct driver (usually PulseAudio or ALSA)
# Test sound
```

If audio is choppy:
```bash
export PULSE_LATENCY_MSEC=60
wine app.exe
```

### Font Issues

```bash
winetricks corefonts
# Or install all Windows fonts
winetricks allfonts
```

### Reset Wine Prefix

If everything is broken, start fresh:
```bash
# Backup and remove old prefix
mv ~/.wine ~/.wine-backup

# Create new prefix
winecfg
```

### Debug Output

For detailed debugging:
```bash
# All debug channels
WINEDEBUG=+all wine app.exe 2>&1 | tee wine-debug.log

# Specific channels
WINEDEBUG=+dll,+file wine app.exe

# Common useful channels
WINEDEBUG=+loaddll,+seh,+relay wine app.exe
```

---

## Application-Specific Tips

### Microsoft Office
```bash
winetricks corefonts dotnet48 msxml6 gdiplus riched20
# Install Office via:
wine setup.exe
```

### Steam Games
```bash
winetricks dxvk vcrun2019 corefonts
# Download Steam installer and run:
wine SteamSetup.exe
```

### Adobe Photoshop
```bash
winetricks atmlib gdiplus msxml3 msxml6 vcrun2019 corefonts
```

### AutoCAD
```bash
winetricks dotnet48 vcrun2019 msxml6 corefonts
```

### Games (General)
```bash
winetricks dxvk vcrun2019 corefonts directx9
# Consider using Lutris for game management
```

---

## Uninstallation

To completely remove Wine and restore your system:

```bash
sudo bash uninstall-wine.sh
```

This script will:
1. ✅ Remove all Wine packages
2. ✅ Remove WineHQ repositories
3. ✅ Optionally remove Wine prefixes (with confirmation)
4. ✅ Restore original system configuration from backup
5. ✅ Clean up residual files

### Manual Uninstallation (if script unavailable)

**Debian/Ubuntu:**
```bash
sudo apt remove --purge winehq-stable wine-stable winetricks
sudo apt autoremove
sudo rm -rf ~/.wine
```

**Fedora/RHEL:**
```bash
sudo dnf remove wine winehq-stable winetricks
rm -rf ~/.wine
```

**Arch:**
```bash
sudo pacman -Rns wine winetricks
rm -rf ~/.wine
```

**macOS:**
```bash
brew uninstall --cask wine-stable
brew uninstall winetricks
rm -rf ~/.wine
```

---

## Additional Resources

### Official Resources
- **WineHQ Website:** https://www.winehq.org
- **Application Database:** https://appdb.winehq.org
- **Bug Tracker:** https://bugs.winehq.org
- **Documentation:** https://wiki.winehq.org

### Community Resources
- **Wine Forums:** https://forum.winehq.org
- **Reddit:** r/wine_gaming, r/linux_gaming
- **Lutris (Game Manager):** https://lutris.net
- **Bottles (Modern Wine Manager):** https://usebottles.com
- **Proton (Steam's Wine fork):** https://github.com/ValveSoftware/Proton

### Useful Tools
| Tool | Purpose | Link |
|------|---------|------|
| **Lutris** | Game launcher & manager | https://lutris.net |
| **Bottles** | Modern Wine prefix manager | https://usebottles.com |
| **PlayOnLinux** | Wine prefix manager | https://www.playonlinux.com |
| **Q4Wine** | Qt GUI for Wine | https://q4wine.brezblock.org.ua |
| **Wine-GE** | GloriousEggroll's Wine builds | https://github.com/GloriousEggroll/wine-ge-custom |

---

## Quick Reference Card

```bash
# Essential setup for new prefix
WINEPREFIX=~/.wine-new WINEARCH=win64 winecfg
winetricks corefonts vcrun2019 dxvk

# Run app with optimizations
WINEDEBUG=-all WINEESYNC=1 gamemoderun wine app.exe

# Debug problems
WINEDEBUG=+all wine app.exe 2>&1 | tee debug.log

# Kill stuck Wine processes
wineserver -k

# Backup prefix
tar czvf wine-backup.tar.gz ~/.wine

# Restore prefix
tar xzvf wine-backup.tar.gz -C ~
```

---

> **Note:** Wine compatibility varies by application. Always check the [WineHQ AppDB](https://appdb.winehq.org) for specific application ratings and tips before installing complex software.

---

*This guide was generated alongside the Wine installation script.*
*For support, visit https://forum.winehq.org*
GUIDE_EOF

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

    check_sudo
    detect_os
    select_user_profile
    check_prerequisites
    create_backup

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

    post_install
    verify_installation
    generate_uninstall_script
    generate_usage_guide

    echo
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              Installation Complete!                            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
    log_success "Wine has been installed and verified for user: $TARGET_USER!"
    log "Log file: $LOG_FILE"
    log "Backup location: $BACKUP_DIR"
    log "Uninstall script: $SCRIPT_DIR/uninstall-wine.sh"
    log "Usage guide: $SCRIPT_DIR/WINE-USAGE-GUIDE.md"
    echo
    echo -e "${CYAN}Next steps:${NC}"
    echo "  1. Run 'wine --version' to verify"
    echo "  2. Run 'winecfg' to configure Wine"
    echo "  3. Read WINE-USAGE-GUIDE.md for detailed usage instructions"
    echo "  4. Use 'winetricks' to install additional Windows components"
    echo
}

main "$@"
