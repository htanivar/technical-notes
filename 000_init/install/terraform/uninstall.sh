#!/bin/bash
set -e

# ==============================================================================
# Terraform Interactive Uninstaller
# Supports: Debian/Ubuntu/MX Linux, RHEL/Fedora/CentOS, Arch Linux, macOS (Homebrew)
# Location: 000_init/install/terraform/uninstall.sh
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
echo -e "${YELLOW}   ⚠️ Interactive Terraform Uninstaller   ${NC}"
echo -e "${RED}=====================================================${NC}"

if ! command -v terraform &>/dev/null && [ ! -f /usr/local/bin/terraform ]; then
    log_info "Terraform does not appear to be installed on this system."
    exit 0
fi

# Interactive Confirmation
read -p "Are you sure you want to UNINSTALL Terraform from your system? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Uninstallation cancelled."
    exit 0
fi

# Detect OS
log_step "Detecting operating system..."
OS_TYPE="$(uname -s)"

if [ "$OS_TYPE" = "Darwin" ]; then
    log_step "Uninstalling Terraform via Homebrew..."
    brew uninstall terraform || true
    brew untap hashicorp/tap || true

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
        log_step "Removing Terraform package via apt..."
        sudo apt-get remove --purge -y terraform || true
        log_step "Cleaning up HashiCorp repository & keyring..."
        sudo rm -f /etc/apt/sources.list.d/hashicorp.list
        sudo rm -f /usr/share/keyrings/hashicorp-archive-keyring.gpg
        sudo apt-get update -y

    # RHEL / CentOS / Fedora
    elif [[ "$DISTRO" =~ ^(fedora|rhel|centos|rocky|almalinux)$ ]] || [[ "$LIKE" =~ (rhel|fedora) ]]; then
        log_step "Removing Terraform package..."
        if command -v dnf &>/dev/null; then
            sudo dnf remove -y terraform || true
        else
            sudo yum remove -y terraform || true
        fi
        sudo rm -f /etc/yum.repos.d/hashicorp.repo

    # Arch Linux / Manjaro
    elif [[ "$DISTRO" =~ ^(arch|manjaro)$ ]] || [[ "$LIKE" =~ arch ]]; then
        log_step "Removing Terraform package via pacman..."
        sudo pacman -R --noconfirm terraform || true

    else
        log_step "Removing manual binary at /usr/local/bin/terraform..."
        sudo rm -f /usr/local/bin/terraform
    fi

    # Check for remaining manual binary if any
    if [ -f /usr/local/bin/terraform ]; then
        log_step "Removing leftover /usr/local/bin/terraform..."
        sudo rm -f /usr/local/bin/terraform
    fi

else
    log_error "Unsupported Operating System: $OS_TYPE"
    exit 1
fi

# Verification
log_step "Verifying uninstallation..."
if ! command -v terraform &>/dev/null && [ ! -f /usr/local/bin/terraform ]; then
    echo -e "${GREEN}=====================================================${NC}"
    echo -e "${GREEN} ✅ Terraform was successfully removed from the system.${NC}"
    echo -e "${GREEN}=====================================================${NC}"
else
    log_warn "Terraform binary is still detected at $(which terraform 2>/dev/null || echo '/usr/local/bin/terraform'). Manual cleanup may be required."
fi
