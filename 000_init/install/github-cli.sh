#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or using sudo."
    exit 1
fi

# GitHub CLI Auto-Installer
# Detects OS, architecture, and distribution to install GitHub CLI

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux"* ]] || [[ "$(uname -s)" == "Linux" ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]] || [[ "$(uname -s)" == "Darwin" ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS="windows"
    else
        log_error "Unsupported OS: $OSTYPE"
        exit 1
    fi
}

# Detect architecture
detect_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l|armhf)
            ARCH="armv6"
            ;;
        i386|i686)
            ARCH="386"
            ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
}

# Detect Linux distribution
detect_distro() {
    if [[ "$OS" != "linux" ]]; then
        return
    fi

    DISTRO=""
    DISTRO_LIKE=""

    if [[ -f /etc/os-release ]]; then
        DISTRO=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"'\'' ' | tr '[:upper:]' '[:lower:]')
        DISTRO_LIKE=$(grep '^ID_LIKE=' /etc/os-release | cut -d'=' -f2 | tr -d '"'\'' ' | tr '[:upper:]' '[:lower:]')
    elif [[ -f /usr/lib/os-release ]]; then
        DISTRO=$(grep '^ID=' /usr/lib/os-release | cut -d'=' -f2 | tr -d '"'\'' ' | tr '[:upper:]' '[:lower:]')
        DISTRO_LIKE=$(grep '^ID_LIKE=' /usr/lib/os-release | cut -d'=' -f2 | tr -d '"'\'' ' | tr '[:upper:]' '[:lower:]')
    elif command -v lsb_release >/dev/null 2>&1; then
        DISTRO=$(lsb_release -si 2>/dev/null | tr '[:upper:]' '[:lower:]')
    elif [[ -f /etc/redhat-release ]]; then
        DISTRO="rhel"
    elif [[ -f /etc/debian_version ]]; then
        DISTRO="debian"
    elif [[ -f /etc/arch-release ]]; then
        DISTRO="arch"
    elif [[ -f /etc/alpine-release ]]; then
        DISTRO="alpine"
    elif [[ -f /etc/SuSE-release ]] || [[ -f /etc/suse-release ]]; then
        DISTRO="opensuse"
    fi

    if [[ -z "$DISTRO" ]]; then
        DISTRO="unknown"
    fi
}

# Check if gh is already installed
check_existing() {
    if command -v gh >/dev/null 2>&1; then
        CURRENT_VERSION=$(gh --version | head -n1 | awk '{print $3}')
        log_warn "GitHub CLI is already installed (version: $CURRENT_VERSION)"
        read -p "Do you want to continue with installation/update? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled"
            exit 0
        fi
    fi
}

# Package manager installation helpers
install_debian_ubuntu() {
    log_info "Installing via APT (Debian/Ubuntu-based)"
    sudo mkdir -p -m 755 /usr/share/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install -y gh
}

install_redhat() {
    log_info "Installing via DNF/YUM (Red Hat-based)"
    if command -v dnf >/dev/null 2>&1; then
        sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo 2>/dev/null || \
        sudo dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo 2>/dev/null || \
        (sudo mkdir -p /etc/yum.repos.d && curl -fsSL https://cli.github.com/packages/rpm/gh-cli.repo | sudo tee /etc/yum.repos.d/gh-cli.repo > /dev/null)
        sudo dnf install -y gh
    elif command -v yum >/dev/null 2>&1; then
        sudo yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo 2>/dev/null || \
        (sudo mkdir -p /etc/yum.repos.d && curl -fsSL https://cli.github.com/packages/rpm/gh-cli.repo | sudo tee /etc/yum.repos.d/gh-cli.repo > /dev/null)
        sudo yum install -y gh
    else
        install_binary
    fi
}

install_suse() {
    log_info "Installing via Zypper (openSUSE/SUSE)"
    sudo zypper addrepo https://cli.github.com/packages/rpm/gh-cli.repo 2>/dev/null || true
    sudo zypper refresh
    sudo zypper install -y gh
}

install_arch() {
    log_info "Installing via Pacman (Arch-based)"
    sudo pacman -S --noconfirm github-cli
}

install_alpine() {
    log_info "Installing via APK (Alpine)"
    sudo apk add github-cli
}

install_void() {
    log_info "Installing via XBPS (Void Linux)"
    sudo xbps-install -Sy github-cli
}

install_gentoo() {
    log_info "Installing via Portage (Gentoo)"
    sudo emerge -v sys-apps/github-cli || install_binary
}

install_solus() {
    log_info "Installing via eopkg (Solus)"
    sudo eopkg it -y gh || install_binary
}

# Install via package manager (Linux)
install_via_package_manager() {
    case $DISTRO in
        ubuntu|debian|linuxmint|pop|elementary|zorin|kali|raspbian|parrot|neon|mx|deepin|pureos|astra|antix|tails|bodhi|peppermint|devuan)
            install_debian_ubuntu
            ;;
        fedora|centos|rhel|rocky|almalinux|amzn|ol|nobara|mageia|openeuler|scientific|cloudlinux|eurolinux)
            install_redhat
            ;;
        opensuse*|sles|suse)
            install_suse
            ;;
        arch|manjaro*|endeavouros|garuda|artix|arcolinux|cachyos)
            install_arch
            ;;
        alpine|postmarketos)
            install_alpine
            ;;
        void)
            install_void
            ;;
        gentoo|funtoo)
            install_gentoo
            ;;
        solus)
            install_solus
            ;;
        *)
            # Fallback by DISTRO_LIKE
            if [[ "$DISTRO_LIKE" =~ (ubuntu|debian) ]]; then
                install_debian_ubuntu
            elif [[ "$DISTRO_LIKE" =~ (rhel|fedora|centos) ]]; then
                install_redhat
            elif [[ "$DISTRO_LIKE" =~ (suse) ]]; then
                install_suse
            elif [[ "$DISTRO_LIKE" =~ (arch) ]]; then
                install_arch
            elif [[ "$DISTRO_LIKE" =~ (alpine) ]]; then
                install_alpine
            # Fallback by package manager command availability
            elif command -v apt-get >/dev/null 2>&1; then
                install_debian_ubuntu
            elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
                install_redhat
            elif command -v zypper >/dev/null 2>&1; then
                install_suse
            elif command -v pacman >/dev/null 2>&1; then
                install_arch
            elif command -v apk >/dev/null 2>&1; then
                install_alpine
            elif command -v xbps-install >/dev/null 2>&1; then
                install_void
            elif command -v eopkg >/dev/null 2>&1; then
                install_solus
            else
                log_warn "Unknown/unsupported distribution: $DISTRO"
                log_info "Falling back to binary installation"
                install_binary
            fi
            ;;
    esac
}

# Install binary directly
install_binary() {
    log_info "Installing GitHub CLI binary for $OS-$ARCH"

    # Get latest release info
    LATEST_URL="https://api.github.com/repos/cli/cli/releases/latest"

    case $OS in
        linux)
            BINARY_NAME="gh_.*_linux_${ARCH}\.tar\.gz"
            ;;
        macos)
            BINARY_NAME="gh_.*_macOS_${ARCH}\.tar\.gz"
            ;;
        windows)
            BINARY_NAME="gh_.*_windows_${ARCH}\.zip"
            ;;
    esac

    # Download and extract
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    log_info "Downloading latest GitHub CLI..."
    DOWNLOAD_URL=$(curl -s "$LATEST_URL" | grep -E "browser_download_url.*$BINARY_NAME" | cut -d '"' -f 4 | head -n1)

    if [[ -z "$DOWNLOAD_URL" ]]; then
        log_error "Could not find download URL for $OS-$ARCH"
        exit 1
    fi

    curl -L -o "gh_archive" "$DOWNLOAD_URL"

    # Extract based on file type
    if [[ "$DOWNLOAD_URL" == *.tar.gz ]]; then
        tar -xzf gh_archive
        EXTRACTED_DIR=$(find . -name "gh_*" -type d | head -n1)
        BINARY_PATH="$EXTRACTED_DIR/bin/gh"
    elif [[ "$DOWNLOAD_URL" == *.zip ]]; then
        unzip -q gh_archive
        EXTRACTED_DIR=$(find . -name "gh_*" -type d | head -n1)
        BINARY_PATH="$EXTRACTED_DIR/bin/gh.exe"
    fi

    # Install binary
    if [[ "$OS" == "windows" ]]; then
        log_info "Please manually copy $BINARY_PATH to a directory in your PATH"
        log_info "Binary downloaded to: $TEMP_DIR"
    else
        sudo cp "$BINARY_PATH" /usr/local/bin/gh
        sudo chmod +x /usr/local/bin/gh
        log_info "GitHub CLI installed to /usr/local/bin/gh"
    fi

    # Cleanup
    cd - >/dev/null
    rm -rf "$TEMP_DIR"
}

# Install via Homebrew (macOS)
install_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        log_info "Installing via Homebrew"
        brew install gh
    else
        log_warn "Homebrew not found, falling back to binary installation"
        install_binary
    fi
}

# Main installation logic
main() {
    log_info "GitHub CLI Auto-Installer"
    log_info "========================="

    detect_os
    detect_arch
    detect_distro

    log_info "Detected: $OS-$ARCH"
    [[ "$OS" == "linux" ]] && log_info "Distribution: $DISTRO"

    check_existing

    case $OS in
        linux)
            install_via_package_manager
            ;;
        macos)
            install_homebrew
            ;;
        windows)
            install_binary
            ;;
    esac

    # Verify installation
    if command -v gh >/dev/null 2>&1; then
        VERSION=$(gh --version | head -n1 | awk '{print $3}')
        log_info "GitHub CLI successfully installed! Version: $VERSION"
        log_info "Run 'gh auth login' to authenticate"
    else
        log_error "Installation failed or gh not found in PATH"
        exit 1
    fi
}

# Run main function
main "$@"
