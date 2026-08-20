#!/bin/bash
set -e

# ==============================================================================
# Terraform Interactive Installer
# Supports: Debian/Ubuntu/MX Linux, RHEL/Fedora/CentOS, Arch Linux, macOS (Homebrew)
# Location: 000_init/install/terraform/terraform_install.sh
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
echo -e "${GREEN}   🚀 Interactive Terraform Installer   ${NC}"
echo -e "${BLUE}=====================================================${NC}"

# Interactive Confirmation
read -p "Do you want to proceed with the Terraform installation? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warn "Installation cancelled by user."
    exit 0
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
    log_step "Installing Terraform via Homebrew..."
    brew tap hashicorp/tap
    brew install hashicorp/tap/terraform

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
        log_step "Installing dependencies (wget, gpg, coreutils)..."
        sudo apt-get update -y
        sudo apt-get install -y wget gpg coreutils lsb-release

        log_step "Adding HashiCorp GPG key..."
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg --yes

        log_step "Adding HashiCorp repository..."
        UBUNTU_CODENAME=$(lsb_release -cs 2>/dev/null || echo "jammy")
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${UBUNTU_CODENAME} main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

        log_step "Installing Terraform via apt..."
        sudo apt-get update -y
        sudo apt-get install -y terraform

    # RHEL / CentOS / Fedora
    elif [[ "$DISTRO" =~ ^(fedora|rhel|centos|rocky|almalinux)$ ]] || [[ "$LIKE" =~ (rhel|fedora) ]]; then
        log_step "Installing yum-utils / dnf-plugins-core..."
        if command -v dnf &>/dev/null; then
            sudo dnf install -y dnf-plugins-core
            sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/Fedora/hashicorp.repo || \
            sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
            log_step "Installing Terraform via dnf..."
            sudo dnf install -y terraform
        else
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
            log_step "Installing Terraform via yum..."
            sudo yum install -y terraform
        fi

    # Arch Linux / Manjaro
    elif [[ "$DISTRO" =~ ^(arch|manjaro)$ ]] || [[ "$LIKE" =~ arch ]]; then
        log_step "Installing Terraform via pacman..."
        sudo pacman -Sy --noconfirm terraform

    else
        log_warn "Unrecognized Linux distribution '$DISTRO'. Attempting direct binary download..."
        TERRAFORM_VERSION="1.9.5"
        ARCH="$(uname -m)"
        case "$ARCH" in
            x86_64) ARCH_TYPE="amd64" ;;
            aarch64|arm64) ARCH_TYPE="arm64" ;;
            *) log_error "Unsupported architecture: $ARCH"; exit 1 ;;
        esac
        
        TMP_DIR="$(mktemp -d)"
        log_step "Downloading Terraform v${TERRAFORM_VERSION} binary..."
        wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH_TYPE}.zip" -O "${TMP_DIR}/terraform.zip"
        unzip -q "${TMP_DIR}/terraform.zip" -d "${TMP_DIR}"
        sudo mv "${TMP_DIR}/terraform" /usr/local/bin/terraform
        rm -rf "${TMP_DIR}"
    fi

else
    log_error "Unsupported Operating System: $OS_TYPE"
    exit 1
fi

# Verification
log_step "Verifying Terraform installation..."
if command -v terraform &>/dev/null; then
    echo -e "${GREEN}=====================================================${NC}"
    echo -e "${GREEN} ✅ Terraform successfully installed!${NC}"
    echo -e "${GREEN} Version details:${NC}"
    terraform -version
    echo -e "${GREEN}=====================================================${NC}"
else
    log_error "Installation failed. Terraform executable not found in PATH."
    exit 1
fi
