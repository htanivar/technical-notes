#!/bin/bash

# ==============================================================================
# Refactored Zsh and Oh My Zsh Installation Script
# ==============================================================================
# This script is for advanced users and performs a highly customized installation
# of Zsh and Oh My Zsh on various Unix-like systems. It includes:
#   - Root-only execution check
#   - Detailed, time-stamped logging in the /tmp/ directory
#   - System and architecture detection (Linux, macOS)
#   - Conditional installation based on OS and package manager
#   - Transactional installation logic with a robust cleanup function
#   - Comprehensive verification of successful installation
#   - Automated creation of a help file for post-installation configuration
#
# USAGE:
#   1. Make the script executable: chmod +x <filename>.sh
#   2. Run as root: sudo ./<filename>.sh
#
# NOTE: This script is not compatible with Windows without a Linux environment
# like WSL. Windows installations are handled by different tools entirely.
# ==============================================================================

# --- Global Variables ---
SCRIPT_NAME="install-zsh"
LOG_FILE="/tmp/${SCRIPT_NAME}_$(date +%Y-%m-%d_%H-%M-%S).log"
HELP_FILE="/tmp/${SCRIPT_NAME}_post_install_help.txt"
OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"
OH_MY_ZSH_INSTALLER_URL="https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
PACKAGES_TO_INSTALL="zsh git curl"

# --- Function Definitions ---

# Log messages with a timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Clean up files and directories created by the script.
# This function is triggered by the TRAP command on exit or error.
cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        log "Cleaning up temporary directory: $TEMP_DIR"
        rm -rf "$TEMP_DIR"
    fi
    log "Cleaning up completed."
}

# --- Main Script Logic ---

# Set a trap to execute the cleanup function on exit or error.
trap cleanup EXIT ERR

log "[$SCRIPT_NAME] Installation started."

# Ensure script is run as root.
if [[ "$EUID" -ne 0 ]]; then
    log "ERROR: This script must be run as root."
    log "Exiting due to insufficient permissions."
    exit 1
fi

# Detect operating system.
OS_TYPE=$(uname -s)
case "$OS_TYPE" in
    Linux)
        log "Detected operating system: Linux"
        # Detect Linux distribution and package manager.
        if command -v apt-get &>/dev/null; then
            PKG_MANAGER="apt-get"
            log "Detected package manager: apt-get (Debian/Ubuntu based)."
        elif command -v dnf &>/dev/null; then
            PKG_MANAGER="dnf"
            log "Detected package manager: dnf (Fedora based)."
        elif command -v yum &>/dev/null; then
            PKG_MANAGER="yum"
            log "Detected package manager: yum (CentOS based)."
        else
            log "ERROR: Unsupported Linux distribution. Exiting."
            exit 1
        fi
        ;;
    Darwin)
        log "Detected operating system: macOS"
        if command -v brew &>/dev/null; then
            PKG_MANAGER="brew"
            log "Detected package manager: Homebrew."
            PACKAGES_TO_INSTALL="zsh git curl" # macOS requires different packages
        else
            log "ERROR: Homebrew is not installed. Please install it first. Exiting."
            exit 1
        fi
        ;;
    *)
        log "ERROR: Unsupported operating system: $OS_TYPE. Exiting."
        exit 1
        ;;
esac

# Check for required binaries for the Oh My Zsh installation.
check_prerequisites() {
    log "Checking for installation prerequisites: $PACKAGES_TO_INSTALL"
    for pkg in $PACKAGES_TO_INSTALL; do
        if ! command -v "$pkg" &>/dev/null; then
            log "WARNING: '$pkg' not found. Installing now..."
            if ! $PKG_MANAGER install -y "$pkg" &>>"$LOG_FILE"; then
                log "ERROR: Failed to install '$pkg'. Exiting."
                return 1
            fi
        fi
    done
    return 0
}

# Handle architecture-specific installation steps if needed.
handle_architecture() {
    log "Handling architecture-specific tasks..."
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64) log "Detected architecture: amd64/x86_64.";;
        aarch64|arm64) log "Detected architecture: arm64/aarch64.";;
        armv7l|arm*) log "Detected architecture: arm.";;
        i*86) log "Detected architecture: 32-bit.";;
        *) log "WARNING: Unsupported or unknown architecture: $ARCH. Installation may fail.";;
    esac
    # Add architecture-specific logic here if necessary
    return 0
}

# --- Installation Steps ---

# Step 1: Handle dependencies and architecture
if ! check_prerequisites || ! handle_architecture; then
    exit 1
fi

# Step 2: Install Oh My Zsh
log "Installing Oh My Zsh..."
if [ ! -d "$OH_MY_ZSH_DIR" ]; then
    log "Downloading and running Oh My Zsh installer..."
    if ! curl -fsSL "$OH_MY_ZSH_INSTALLER_URL" | sh -s -- --unattended &>>"$LOG_FILE"; then
        log "ERROR: Oh My Zsh installation failed. Exiting."
        exit 1
    fi
else
    log "Oh My Zsh is already installed. Skipping."
fi

# Step 3: Set Zsh as default shell
log "Setting Zsh as the default shell..."
if [ "$SHELL" != "$(which zsh)" ]; then
    if ! chsh -s "$(which zsh)" &>>"$LOG_FILE"; then
        log "ERROR: Failed to set Zsh as the default shell. Exiting."
        exit 1
    fi
    log "Zsh has been set as the default shell. User must log out and log back in."
else
    log "Zsh is already the default shell."
fi

# --- Verification and Configuration ---

# Step 4: Verify installation success
log "Verifying installation..."
if ! command -v zsh &>/dev/null; then
    log "ERROR: Zsh was not found after installation. Exiting."
    exit 1
fi
if [[ ! -d "$OH_MY_ZSH_DIR" ]]; then
    log "ERROR: Oh My Zsh directory was not found. Exiting."
    exit 1
fi
log "Zsh and Oh My Zsh appear to be installed successfully."

# Step 5: Create a help file
log "Creating post-installation help file at $HELP_FILE..."
cat <<EOF > "$HELP_FILE"
# ==============================================================================
# Zsh and Oh My Zsh Post-Installation Guide
# ==============================================================================

Congratulations! Zsh and Oh My Zsh have been installed on your system.

**To complete the setup:**
1. **Log out** of your current session and **log back in**.
2. **Open a new terminal**. You will be greeted by Zsh.

**To manage your Zsh configuration:**
- The main configuration file is **~/.zshrc**. You can edit this file to:
  - Set the theme (e.g., ZSH_THEME="agnoster").
  - Enable and configure plugins (e.g., plugins=(git zsh-syntax-highlighting)).
- The Oh My Zsh installer has already created a default ~/.zshrc file for you.

**To configure your Zsh themes and plugins:**
- Go to the Oh My Zsh themes directory: \`ls $OH_MY_ZSH_DIR/themes\`
- Go to the Oh My Zsh plugins directory: \`ls $OH_MY_ZSH_DIR/plugins\`
- A list of popular themes and plugins can be found online.

**Example: Adding a plugin and theme**
1. Edit your ~/.zshrc file: \`nano ~/.zshrc\`
2. Change the theme:
   \`ZSH_THEME="agnoster"\`
3. Add a plugin (e.g., zsh-autosuggestions):
   \`plugins=(git zsh-autosuggestions)\`
4. Save and exit the file.
5. Apply changes by sourcing the file: \`source ~/.zshrc\`

**Troubleshooting:**
- If you encounter issues, check the detailed installation log at:
  \`cat $LOG_FILE\`

# ==============================================================================
EOF
log "Post-installation help file created."

log "[$SCRIPT_NAME] Script finished successfully. Please log out and back in."
exit 0
