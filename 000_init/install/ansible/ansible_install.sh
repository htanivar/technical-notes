#!/bin/bash
set -e

# ==============================================================================
# Ansible Interactive Installer
# Supports: Debian/Ubuntu/MX Linux, RHEL/Fedora/CentOS, Arch Linux, macOS (Homebrew), Python/pip fallback
# Location: 000_init/install/ansible/ansible_install.sh
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

echo -e "${BLUE}=====================================================${NC}"
echo -e "${GREEN}   🚀 Interactive Ansible Installer   ${NC}"
echo -e "${BLUE}=====================================================${NC}"

# Pre-check: Check if Ansible is already installed and up to date
log_step "Checking current Ansible installation..."

INSTALLED_VERSION=""
LATEST_VERSION=""
NEEDS_INSTALL_OR_UPDATE=true

if command -v ansible &>/dev/null; then
    INSTALLED_VERSION=$(ansible --version 2>/dev/null | head -n 1 | awk '{print $2}' | tr -d ']')
    log_info "Ansible is currently installed: v${INSTALLED_VERSION}"

    log_step "Checking for latest Ansible version from PyPI..."
    LATEST_VERSION=$(curl -s --connect-timeout 5 https://pypi.org/pypi/ansible/json 2>/dev/null | grep -o '"version":"[^"]*"' | head -n 1 | cut -d'"' -f4 || echo "")

    if [ -n "$LATEST_VERSION" ]; then
        log_info "Latest Ansible version available: v${LATEST_VERSION}"
        if [ "$INSTALLED_VERSION" = "$LATEST_VERSION" ]; then
            log_info "✅ You already have the latest version of Ansible (v${INSTALLED_VERSION}) installed!"
            NEEDS_INSTALL_OR_UPDATE=false
        else
            log_warn "⚡ An update is available! Current: v${INSTALLED_VERSION} -> Latest: v${LATEST_VERSION}"
        fi
    else
        log_warn "Unable to fetch latest version info from PyPI. Proceeding with user choice."
    fi
else
    log_info "Ansible is NOT currently installed on this system."
fi

# If already up-to-date, ask if user wants to force reinstall/update anyway
if [ "$NEEDS_INSTALL_OR_UPDATE" = "false" ]; then
    read -p "Do you still want to re-run the installation/update? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "No actions needed. Exiting without requesting sudo access or downloading packages."
        exit 0
    fi
else
    read -p "Do you want to proceed with the Ansible installation/update? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warn "Installation cancelled by user."
        exit 0
    fi
fi

# Detect OS
log_step "Detecting operating system..."
OS_TYPE="$(uname -s)"

if [ "$OS_TYPE" = "Darwin" ]; then
    log_info "Detected OS: macOS"
    if ! command -v brew &>/dev/null; then
        log_error "Homebrew is required for macOS installation. Please install brew first."
        exit 1
    fi
    log_step "Installing/Updating Ansible via Homebrew..."
    brew install ansible || brew upgrade ansible

elif [ "$OS_TYPE" = "Linux" ]; then
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        LIKE=$ID_LIKE
    else
        log_error "Cannot detect Linux distribution (/etc/os-release missing)."
        exit 1
    fi

    log_info "Detected Linux Distribution: $NAME ($DISTRO)"

    # Debian / Ubuntu / MX Linux / Mint
    if [[ "$DISTRO" =~ ^(ubuntu|debian|mx|linuxmint|pop)$ ]] || [[ "$LIKE" =~ (ubuntu|debian) ]]; then
        log_step "Updating package lists & installing base dependencies (gpg, curl)..."
        sudo apt-get update -y
        sudo apt-get install -y gpg curl 2>/dev/null || sudo apt-get install -y gnupg curl
        sudo apt-get install -y software-properties-common 2>/dev/null || true

        # On Ubuntu, use official PPA if available
        if [ "$DISTRO" = "ubuntu" ] || [[ "$LIKE" =~ ubuntu ]]; then
            if command -v add-apt-repository &>/dev/null; then
                log_step "Adding Ansible PPA..."
                sudo add-apt-repository --yes --update ppa:ansible/ansible || true
            fi
        fi

        log_step "Installing/Updating Ansible via apt..."
        sudo apt-get update -y
        sudo apt-get install -y ansible

    # RHEL / CentOS / Fedora
    elif [[ "$DISTRO" =~ ^(fedora|rhel|centos|rocky|almalinux)$ ]] || [[ "$LIKE" =~ (rhel|fedora) ]]; then
        if command -v dnf &>/dev/null; then
            log_step "Installing/Updating Ansible via dnf..."
            sudo dnf install -y epel-release 2>/dev/null || true
            sudo dnf install -y ansible
        else
            log_step "Installing/Updating Ansible via yum..."
            sudo yum install -y epel-release 2>/dev/null || true
            sudo yum install -y ansible
        fi

    # Arch Linux / Manjaro
    elif [[ "$DISTRO" =~ ^(arch|manjaro)$ ]] || [[ "$LIKE" =~ arch ]]; then
        log_step "Installing/Updating Ansible via pacman..."
        sudo pacman -Sy --noconfirm ansible

    else
        log_warn "Unrecognized Linux distribution '$DISTRO'. Attempting Python pip installation..."
        if command -v pip3 &>/dev/null; then
            log_step "Installing/Updating Ansible via pip3..."
            pip3 install --upgrade ansible
        elif command -v pip &>/dev/null; then
            log_step "Installing/Updating Ansible via pip..."
            pip install --upgrade ansible
        else
            log_error "Neither apt/dnf/pacman nor python-pip were found. Please install Python and pip first."
            exit 1
        fi
    fi

else
    log_error "Unsupported Operating System: $OS_TYPE"
    exit 1
fi

# Verification
log_step "Verifying Ansible installation..."
if command -v ansible &>/dev/null; then
    echo -e "${GREEN}=====================================================${NC}"
    echo -e "${GREEN} ✅ Ansible check complete!${NC}"
    echo -e "${GREEN} Version details:${NC}"
    ansible --version | head -n 2
    echo -e "${GREEN}=====================================================${NC}"
else
    log_error "Installation failed. Ansible executable not found in PATH."
    exit 1
fi
