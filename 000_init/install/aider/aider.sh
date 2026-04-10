#!/usr/bin/env bash
set -euo pipefail

# Detect OS and package manager
detect_os() {
    case "$(uname -s)" in
        Linux*)
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                OS=$ID
            else
                OS="linux"
            fi
            ;;
        Darwin*)
            OS="macos"
            ;;
        CYGWIN*|MINGW32*|MSYS*|MINGW*)
            OS="windows"
            ;;
        *)
            OS="unknown"
            ;;
    esac
    echo "$OS"
}

install_dependencies() {
    local os=$1
    echo "[+] Installing dependencies for $os..."
    
    case "$os" in
        ubuntu|debian|mxlinux|raspbian)
            sudo apt update
            sudo apt install -y make build-essential libssl-dev zlib1g-dev \
                libbz2-dev libreadline-dev libsqlite3-dev curl git \
                libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
            ;;
        fedora|rhel|centos)
            sudo dnf groupinstall -y "Development Tools"
            sudo dnf install -y openssl-devel zlib-devel bzip2-devel \
                readline-devel sqlite-devel curl git ncurses-devel \
                xz-devel tk-devel libxml2-devel libxmlsec1-devel libffi-devel
            ;;
        macos)
            # Check if Homebrew is installed
            if ! command -v brew &> /dev/null; then
                echo "Homebrew is required. Please install it from https://brew.sh/"
                exit 1
            fi
            brew install openssl readline sqlite3 xz zlib tcl-tk
            ;;
        *)
            echo "[!] Unsupported OS for automatic dependency installation."
            echo "    Please install build dependencies manually."
            ;;
    esac
}

setup_pyenv() {
    echo "[+] Setting up pyenv..."
    
    if [ ! -d "$HOME/.pyenv" ]; then
        curl -fsSL https://pyenv.run | bash
    fi
    
    # Add to shell configuration
    local shell_rc=""
    if [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    else
        shell_rc="$HOME/.bashrc"
    fi
    
    # Add pyenv to shell rc if not present
    if ! grep -q 'pyenv init' "$shell_rc" 2>/dev/null; then
        echo '' >> "$shell_rc"
        echo '# Pyenv setup' >> "$shell_rc"
        echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> "$shell_rc"
        echo 'eval "$(pyenv init -)"' >> "$shell_rc"
    fi
    
    # Load pyenv for current session
    export PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init -)"
}

install_python() {
    echo "[+] Installing Python 3.11.9..."
    
    # Check if Python 3.11.9 is already installed via pyenv
    if ! pyenv versions | grep -q "3.11.9"; then
        pyenv install -s 3.11.9
    fi
    
    pyenv global 3.11.9
    
    # Verify installation
    python --version
}

setup_pipx() {
    echo "[+] Setting up pipx..."
    
    python -m pip install --upgrade pip
    python -m pip install --user pipx
    python -m pipx ensurepath
    
    # Add pipx to PATH in current session
    export PATH="$HOME/.local/bin:$PATH"
    
    # Also add to shell rc
    local shell_rc=""
    if [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    else
        shell_rc="$HOME/.bashrc"
    fi
    
    if ! grep -q '\.local/bin' "$shell_rc" 2>/dev/null; then
        echo '' >> "$shell_rc"
        echo '# Pipx path' >> "$shell_rc"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$shell_rc"
    fi
}

install_aider() {
    echo "[+] Installing aider-chat..."
    
    # Ensure pipx is in PATH
    export PATH="$HOME/.local/bin:$PATH"
    
    # Install aider-chat with specific Python version
    pipx install aider-chat --python python
    
    echo "[+] Verifying installation..."
    aider --version
}

main() {
    echo "[+] Starting aider installation..."
    
    local os=$(detect_os)
    echo "[+] Detected OS: $os"
    
    if [ "$os" = "windows" ]; then
        echo "[!] Windows detected. For Git Bash, some features may be limited."
        echo "    Consider using WSL for full compatibility."
        # Continue anyway, but note that some dependencies may fail
    fi
    
    # Install dependencies based on OS
    if [ "$os" != "unknown" ]; then
        install_dependencies "$os"
    fi
    
    # Setup pyenv
    setup_pyenv
    
    # Install Python 3.11.9
    install_python
    
    # Setup pipx
    setup_pipx
    
    # Install aider
    install_aider
    
    echo "[+] Installation complete! ✅"
    echo "[!] Note: You may need to restart your shell or run:"
    echo "    source ~/.bashrc  # or ~/.zshrc"
}

main "$@"
