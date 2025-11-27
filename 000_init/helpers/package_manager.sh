#!/bin/bash
# package_manager.sh - Package management helper functions
# Source: source "$(dirname "$0")/helpers/package_manager.sh"

# Source core utilities
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIR/core_utils.sh"

# =============================================================================
# PACKAGE MANAGER DETECTION
# =============================================================================

# Detect the package manager
detect_package_manager() {
    if command -v apt &> /dev/null; then
        echo "apt"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# =============================================================================
# PACKAGE INSTALLATION FUNCTIONS
# =============================================================================

# Update package repository
update_package_repo() {
    local pm=$(detect_package_manager)
    log_step "UPDATE" "Updating package repository using $pm"
    
    case "$pm" in
        apt)
            apt-get update || error_exit "Failed to update apt repository"
            ;;
        yum)
            yum check-update || true  # yum check-update returns 100 if updates are available
            ;;
        dnf)
            dnf check-update || true
            ;;
        pacman)
            pacman -Sy || error_exit "Failed to update pacman repository"
            ;;
        zypper)
            zypper refresh || error_exit "Failed to refresh zypper repository"
            ;;
        *)
            error_exit "Unsupported package manager: $pm"
            ;;
    esac
}

# Install packages
install_packages() {
    local packages=("$@")
    local pm=$(detect_package_manager)
    
    if [ ${#packages[@]} -eq 0 ]; then
        warn "No packages specified for installation"
        return 1
    fi
    
    log_step "INSTALL" "Installing packages: ${packages[*]} using $pm"
    
    case "$pm" in
        apt)
            apt-get install -y "${packages[@]}" || error_exit "Failed to install packages: ${packages[*]}"
            ;;
        yum)
            yum install -y "${packages[@]}" || error_exit "Failed to install packages: ${packages[*]}"
            ;;
        dnf)
            dnf install -y "${packages[@]}" || error_exit "Failed to install packages: ${packages[*]}"
            ;;
        pacman)
            pacman -S --noconfirm "${packages[@]}" || error_exit "Failed to install packages: ${packages[*]}"
            ;;
        zypper)
            zypper install -y "${packages[@]}" || error_exit "Failed to install packages: ${packages[*]}"
            ;;
        *)
            error_exit "Unsupported package manager: $pm"
            ;;
    esac
    
    log_info "Successfully installed packages: ${packages[*]}"
}

# Install package if not present
install_if_missing() {
    local package_name="$1"
    local command_name="${2:-$package_name}"
    
    if command -v "$command_name" &> /dev/null; then
        log_debug "Package already available: $command_name"
        return 0
    fi
    
    log_info "Installing missing package: $package_name"
    install_packages "$package_name"
}

# Remove packages
remove_packages() {
    local packages=("$@")
    local pm=$(detect_package_manager)
    
    if [ ${#packages[@]} -eq 0 ]; then
        warn "No packages specified for removal"
        return 1
    fi
    
    log_step "REMOVE" "Removing packages: ${packages[*]} using $pm"
    
    case "$pm" in
        apt)
            apt-get remove -y "${packages[@]}" || warn "Some packages may not have been removed: ${packages[*]}"
            ;;
        yum)
            yum remove -y "${packages[@]}" || warn "Some packages may not have been removed: ${packages[*]}"
            ;;
        dnf)
            dnf remove -y "${packages[@]}" || warn "Some packages may not have been removed: ${packages[*]}"
            ;;
        pacman)
            pacman -R --noconfirm "${packages[@]}" || warn "Some packages may not have been removed: ${packages[*]}"
            ;;
        zypper)
            zypper remove -y "${packages[@]}" || warn "Some packages may not have been removed: ${packages[*]}"
            ;;
        *)
            error_exit "Unsupported package manager: $pm"
            ;;
    esac
}

# =============================================================================
# REPOSITORY MANAGEMENT
# =============================================================================

# Add repository (APT-specific for now)
add_apt_repository() {
    local repo_url="$1"
    local keyring_file="$2"
    local repo_name="$3"
    
    require_command "apt-get"
    
    log_step "REPO" "Adding APT repository: $repo_name"
    
    # Add GPG key if provided
    if [ -n "$keyring_file" ]; then
        log_debug "Adding GPG key: $keyring_file"
        # Implementation depends on the specific repository
    fi
    
    # Add repository
    echo "$repo_url" > "/etc/apt/sources.list.d/${repo_name}.list" || error_exit "Failed to add repository: $repo_name"
    
    log_info "Repository added successfully: $repo_name"
}

# =============================================================================
# NODE.JS SPECIFIC FUNCTIONS
# =============================================================================

# Install Node.js from NodeSource
install_nodejs() {
    local version="${1:-20.x}"
    
    log_step "NODEJS" "Installing Node.js version $version"
    
    # Normalize version (allow both "20" and "20.x")
    version="${version%.*}.x"
    
    # Download and run NodeSource setup script
    local setup_url="https://deb.nodesource.com/setup_${version}"
    
    log_debug "Downloading NodeSource setup script for $version"
    curl -fsSL "$setup_url" | bash - || error_exit "NodeSource setup script failed"
    
    # Install Node.js
    install_packages nodejs
    
    # Verify installation
    local node_version
    node_version=$(node --version 2>/dev/null || echo "unknown")
    log_info "Node.js installed successfully: $node_version"
}

# Install global NPM packages
install_npm_global() {
    local packages=("$@")
    
    require_command "npm"
    
    if [ ${#packages[@]} -eq 0 ]; then
        warn "No NPM packages specified"
        return 1
    fi
    
    log_step "NPM" "Installing global NPM packages: ${packages[*]}"
    npm install -g "${packages[@]}" || error_exit "Failed to install global NPM packages: ${packages[*]}"
    
    log_info "Successfully installed global NPM packages: ${packages[*]}"
}

# =============================================================================
# DOCKER SPECIFIC FUNCTIONS
# =============================================================================

# Install Docker from packages
install_docker_packages() {
    local cache_dir="$1"
    local log_file="$2"
    
    require_directory "$cache_dir"
    
    log_step "DOCKER" "Installing Docker packages from $cache_dir"
    
    # Check for .deb files
    local deb_files=("$cache_dir"/*.deb)
    if [ ${#deb_files[@]} -eq 0 ] || [ ! -f "${deb_files[0]}" ]; then
        error_exit "No .deb files found in $cache_dir"
    fi
    
    # Define installation order
    local order=(containerd.io docker-ce-cli docker-buildx-plugin docker-compose-plugin docker-ce)
    local present=()
    
    # Check which packages are present
    for package in "${order[@]}"; do
        if ls "$cache_dir/${package}_"*.deb &> /dev/null; then
            present+=("$package")
        fi
    done
    
    # Install packages
    if [ ${#present[@]} -gt 0 ]; then
        for package in "${present[@]}"; do
            log_info "Installing Docker package: $package"
            local package_file
            package_file=$(ls "$cache_dir/${package}_"*.deb | head -n1)
            dpkg -i "$package_file" || true
        done
        
        # Fix any dependency issues
        apt-get -y -o Dpkg::Options::=--force-confnew -f install || error_exit "Failed to fix Docker dependencies"
    else
        # Fallback to docker.io if available
        local docker_io_pkg
        docker_io_pkg=$(ls "$cache_dir"/docker.io_*.deb 2>/dev/null | head -n1 || true)
        if [ -n "$docker_io_pkg" ]; then
            log_info "Installing docker.io package"
            dpkg -i "$docker_io_pkg" || true
            apt-get -y -o Dpkg::Options::=--force-confnew -f install || error_exit "Failed to install docker.io"
        else
            error_exit "No Docker packages found in $cache_dir"
        fi
    fi
    
    log_info "Docker packages installed successfully"
}

# =============================================================================
# DATABASE FUNCTIONS
# =============================================================================

# Install PostgreSQL
install_postgresql() {
    local version="${1:-}"
    
    log_step "POSTGRES" "Installing PostgreSQL${version:+ version $version}"
    
    if [ -n "$version" ]; then
        install_packages "postgresql-$version" postgresql-client postgresql-contrib
    else
        install_packages postgresql postgresql-client postgresql-contrib
    fi
    
    # Start and enable service
    systemctl enable postgresql || warn "Could not enable PostgreSQL service"
    systemctl start postgresql || warn "Could not start PostgreSQL service"
    
    log_info "PostgreSQL installed and started"
}

# Install Redis
install_redis() {
    log_step "REDIS" "Installing Redis"
    
    install_packages redis-server
    
    # Start and enable service
    systemctl enable redis-server || warn "Could not enable Redis service"
    systemctl start redis-server || warn "Could not start Redis service"
    
    log_info "Redis installed and started"
}

# =============================================================================
# DEVELOPMENT TOOLS
# =============================================================================

# Install build essentials
install_build_tools() {
    local pm=$(detect_package_manager)
    
    log_step "BUILD" "Installing build tools for $pm"
    
    case "$pm" in
        apt)
            install_packages build-essential git curl wget
            ;;
        yum|dnf)
            install_packages gcc gcc-c++ make git curl wget
            ;;
        pacman)
            install_packages base-devel git curl wget
            ;;
        zypper)
            install_packages gcc gcc-c++ make git curl wget
            ;;
        *)
            error_exit "Unsupported package manager for build tools: $pm"
            ;;
    esac
}

# Note: Functions are automatically available when this script is sourced
