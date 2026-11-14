#!/bin/bash
set -e

# ==============================================================================
# Ansible Interactive Uninstaller
# Supports: Debian/Ubuntu/MX Linux, RHEL/Fedora/CentOS, Arch Linux, macOS (Homebrew), Python/pip
# Location: 000_init/install/ansible/uninstall.sh
# ==============================================================================

# Formatting / Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_step()  { echo -e "${BLUE}[STEP]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${RED}=====================================================${NC}"
echo -e "${YELLOW}   ⚠️ Interactive Ansible Uninstaller   ${NC}"
echo -e "${RED}=====================================================${NC}"

if ! command -v ansible &>/dev/null; then
    log_info "Ansible does not appear to be installed on this system."
    exit 0
fi

# Interactive Confirmation
read -p "Are you sure you want to UNINSTALL Ansible from your system? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Uninstallation cancelled."
    exit 0
fi

# Detect OS
log_step "Detecting operating system..."
OS_TYPE="$(uname -s)"

if [ "$OS_TYPE" = "Darwin" ]; then
    log_step "Uninstalling Ansible via Homebrew..."
    brew uninstall ansible || true

elif [ "$OS_TYPE" = "Linux" ]; then
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        LIKE=$ID_LIKE
    else
        DISTRO="generic"
    fi

    # Debian / Ubuntu / MX Linux / Mint
    if [[ "$DISTRO" =~ ^(ubuntu|debian|mx|linuxmint|pop)$ ]] || [[ "$LIKE" =~ (ubuntu|debian) ]]; then
        log_step "Removing Ansible package via apt..."
        sudo apt-get remove --purge -y ansible || true
        if [ "$DISTRO" = "ubuntu" ] || [[ "$LIKE" =~ ubuntu ]]; then
            log_step "Cleaning up Ansible PPA..."
            sudo add-apt-repository --remove --yes ppa:ansible/ansible 2>/dev/null || true
        fi
        sudo apt-get update -y

    # RHEL / CentOS / Fedora
    elif [[ "$DISTRO" =~ ^(fedora|rhel|centos|rocky|almalinux)$ ]] || [[ "$LIKE" =~ (rhel|fedora) ]]; then
        log_step "Removing Ansible package..."
        if command -v dnf &>/dev/null; then
            sudo dnf remove -y ansible || true
        else
            sudo yum remove -y ansible || true
        fi

    # Arch Linux / Manjaro
    elif [[ "$DISTRO" =~ ^(arch|manjaro)$ ]] || [[ "$LIKE" =~ arch ]]; then
        log_step "Removing Ansible package via pacman..."
        sudo pacman -R --noconfirm ansible || true

    else
        log_step "Attempting removal via pip..."
        if command -v pip3 &>/dev/null; then
            pip3 uninstall -y ansible || true
        elif command -v pip &>/dev/null; then
            pip uninstall -y ansible || true
        fi
    fi

else
    log_error "Unsupported Operating System: $OS_TYPE"
    exit 1
fi

# Verification
log_step "Verifying uninstallation..."
if ! command -v ansible &>/dev/null; then
    echo -e "${GREEN}=====================================================${NC}"
    echo -e "${GREEN} ✅ Ansible was successfully removed from the system.${NC}"
    echo -e "${GREEN}=====================================================${NC}"
else
    log_warn "Ansible binary is still detected at $(which ansible 2>/dev/null). Manual cleanup may be required."
fi
