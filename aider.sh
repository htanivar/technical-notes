#!/usr/bin/env bash
set -euo pipefail

# This is a wrapper script for installing aider-chat
# It can either run the full installation script or check for existing installation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FULL_INSTALL_SCRIPT="$SCRIPT_DIR/000_init/install/aider/install-aider-full.sh"

echo "[+] Aider installation script"

# Check if the full install script exists
if [ -f "$FULL_INSTALL_SCRIPT" ]; then
    echo "[+] Found full installation script at: $FULL_INSTALL_SCRIPT"
    echo "[+] Running it..."
    bash "$FULL_INSTALL_SCRIPT"
else
    echo "[!] Full installation script not found at: $FULL_INSTALL_SCRIPT"
    echo "[+] Attempting to install using direct method..."
    
    # Check if Python 3.11 is available
    if command -v python3.11 &> /dev/null; then
        PYTHON_CMD="python3.11"
    elif command -v python3 &> /dev/null; then
        # Check Python version
        PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
        if [[ "$PYTHON_VERSION" == 3.11.* ]]; then
            PYTHON_CMD="python3"
        else
            echo "[!] Python 3.11 not found. Installing via pyenv..."
            # Install pyenv and Python 3.11
            curl -fsSL https://pyenv.run | bash
            export PATH="$HOME/.pyenv/bin:$PATH"
            eval "$(pyenv init -)"
            pyenv install -s 3.11.9
            pyenv global 3.11.9
            PYTHON_CMD="python"
        fi
    else
        echo "[!] Python not found. Installing via pyenv..."
        curl -fsSL https://pyenv.run | bash
        export PATH="$HOME/.pyenv/bin:$PATH"
        eval "$(pyenv init -)"
        pyenv install -s 3.11.9
        pyenv global 3.11.9
        PYTHON_CMD="python"
    fi
    
    # Install pipx and aider
    $PYTHON_CMD -m pip install --upgrade pip
    $PYTHON_CMD -m pip install --user pipx
    $PYTHON_CMD -m pipx ensurepath
    export PATH="$HOME/.local/bin:$PATH"
    pipx install aider-chat --python $PYTHON_CMD
    
    echo "[+] Verifying installation..."
    aider --version
    echo "[+] Installation complete! ✅"
fi
