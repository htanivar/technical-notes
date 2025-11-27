#!/bin/bash
# system_manager.sh - System and user management helper functions
# Source: source "$(dirname "$0")/helpers/system_manager.sh"

# Source core utilities
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIR/core_utils.sh"

# =============================================================================
# USER MANAGEMENT
# =============================================================================

# Create user with options
create_user() {
    local username="$1"
    local password="$2"
    local home_dir="${3:-/home/$username}"
    local shell="${4:-/bin/bash}"
    local groups="${5:-}"
    local create_home="${6:-true}"
    
    require_root
    
    log_step "USER" "Creating user: $username"
    
    # Check if user already exists
    if id "$username" &>/dev/null; then
        warn "User already exists: $username"
        return 1
    fi
    
    # Build useradd command
    local useradd_cmd="useradd"
    
    if [ "$create_home" = "true" ]; then
        useradd_cmd="$useradd_cmd -m"
    fi
    
    useradd_cmd="$useradd_cmd -d $home_dir -s $shell"
    
    # Add supplementary groups
    if [ -n "$groups" ]; then
        useradd_cmd="$useradd_cmd -G $groups"
    fi
    
    useradd_cmd="$useradd_cmd $username"
    
    # Create the user
    eval "$useradd_cmd" || error_exit "Failed to create user: $username"
    
    # Set password if provided
    if [ -n "$password" ]; then
        echo "$username:$password" | chpasswd || error_exit "Failed to set password for user: $username"
        log_debug "Password set for user: $username"
    fi
    
    log_info "User created successfully: $username"
}

# Create admin user (with sudo access)
create_admin_user() {
    local username="$1"
    local password="$2"
    local home_dir="${3:-/home/$username}"
    local shell="${4:-/bin/bash}"
    
    # Create user with sudo group
    create_user "$username" "$password" "$home_dir" "$shell" "sudo"
    
    log_info "Admin user created with sudo access: $username"
}

# Delete user
delete_user() {
    local username="$1"
    local remove_home="${2:-false}"
    local remove_mail="${3:-false}"
    
    require_root
    
    log_step "USER" "Deleting user: $username"
    
    # Check if user exists
    if ! id "$username" &>/dev/null; then
        warn "User does not exist: $username"
        return 1
    fi
    
    # Build userdel command
    local userdel_cmd="userdel"
    
    if [ "$remove_home" = "true" ]; then
        userdel_cmd="$userdel_cmd -r"
    fi
    
    if [ "$remove_mail" = "true" ]; then
        userdel_cmd="$userdel_cmd -f"
    fi
    
    userdel_cmd="$userdel_cmd $username"
    
    # Delete the user
    eval "$userdel_cmd" || error_exit "Failed to delete user: $username"
    
    log_info "User deleted: $username"
}

# Add user to group
add_user_to_group() {
    local username="$1"
    local group="$2"
    
    require_root
    
    log_step "USER" "Adding user $username to group: $group"
    
    usermod -aG "$group" "$username" || error_exit "Failed to add user $username to group: $group"
    
    log_info "User $username added to group: $group"
}

# Remove user from group
remove_user_from_group() {
    local username="$1"
    local group="$2"
    
    require_root
    
    log_step "USER" "Removing user $username from group: $group"
    
    gpasswd -d "$username" "$group" || warn "Failed to remove user $username from group: $group"
    
    log_info "User $username removed from group: $group"
}

# Setup SSH key for user
setup_ssh_key() {
    local username="$1"
    local public_key_content="$2"
    local key_file="${3:-authorized_keys}"
    
    require_root
    
    log_step "SSH" "Setting up SSH key for user: $username"
    
    local home_dir=$(getent passwd "$username" | cut -d: -f6)
    if [ -z "$home_dir" ]; then
        error_exit "Could not determine home directory for user: $username"
    fi
    
    local ssh_dir="$home_dir/.ssh"
    local auth_keys_file="$ssh_dir/$key_file"
    
    # Create .ssh directory
    create_directory "$ssh_dir" "$username" "$username" 700
    
    # Add public key
    echo "$public_key_content" >> "$auth_keys_file"
    chown "$username:$username" "$auth_keys_file"
    chmod 600 "$auth_keys_file"
    
    log_info "SSH key setup completed for user: $username"
}

# Generate SSH key pair for user
generate_ssh_key() {
    local username="$1"
    local key_type="${2:-rsa}"
    local key_size="${3:-4096}"
    local comment="${4:-$username@$(hostname)}"
    
    log_step "SSH" "Generating SSH key pair for user: $username"
    
    local home_dir
    if [ "$username" = "$(whoami)" ]; then
        home_dir="$HOME"
    else
        home_dir=$(getent passwd "$username" | cut -d: -f6)
    fi
    
    if [ -z "$home_dir" ]; then
        error_exit "Could not determine home directory for user: $username"
    fi
    
    local ssh_dir="$home_dir/.ssh"
    local private_key="$ssh_dir/id_$key_type"
    local public_key="$ssh_dir/id_${key_type}.pub"
    
    # Create .ssh directory
    create_directory "$ssh_dir" "$username" "$username" 700
    
    # Generate key pair
    ssh-keygen -t "$key_type" -b "$key_size" -f "$private_key" -C "$comment" -N "" \
        || error_exit "Failed to generate SSH key pair for user: $username"
    
    # Set proper ownership and permissions
    chown "$username:$username" "$private_key" "$public_key"
    chmod 600 "$private_key"
    chmod 644 "$public_key"
    
    log_info "SSH key pair generated for user: $username"
    log_info "Private key: $private_key"
    log_info "Public key: $public_key"
}

# =============================================================================
# SYSTEM INFORMATION
# =============================================================================

# Set system hostname
set_hostname() {
    local new_hostname="$1"
    local fqdn="${2:-$new_hostname}"
    
    require_root
    
    log_step "SYSTEM" "Setting hostname to: $new_hostname"
    
    # Update hostname
    hostnamectl set-hostname "$new_hostname" || error_exit "Failed to set hostname: $new_hostname"
    
    # Update /etc/hosts
    backup_file "/etc/hosts" "/etc"
    
    # Remove old hostname entries
    sed -i '/127\.0\.1\.1/d' /etc/hosts
    
    # Add new hostname entry
    echo "127.0.1.1    $fqdn $new_hostname" >> /etc/hosts
    
    log_info "Hostname set to: $new_hostname"
}

# Set system FQDN
set_fqdn() {
    local fqdn="$1"
    local hostname="${2:-$(echo "$fqdn" | cut -d. -f1)}"
    
    set_hostname "$hostname" "$fqdn"
    log_info "FQDN set to: $fqdn"
}

# Add swap memory
add_swap_memory() {
    local swap_size="${1:-2G}"
    local swap_file="${2:-/swapfile}"
    
    require_root
    
    log_step "SYSTEM" "Adding swap memory: $swap_size"
    
    # Check if swap file already exists
    if [ -f "$swap_file" ]; then
        warn "Swap file already exists: $swap_file"
        return 1
    fi
    
    # Create swap file
    fallocate -l "$swap_size" "$swap_file" || error_exit "Failed to create swap file: $swap_file"
    chmod 600 "$swap_file"
    
    # Make it a swap file
    mkswap "$swap_file" || error_exit "Failed to make swap file: $swap_file"
    
    # Enable swap
    swapon "$swap_file" || error_exit "Failed to enable swap file: $swap_file"
    
    # Add to fstab for persistence
    backup_file "/etc/fstab" "/etc"
    echo "$swap_file none swap sw 0 0" >> /etc/fstab
    
    # Verify swap
    local total_swap
    total_swap=$(free -h | awk '/^Swap:/ { print $2 }')
    
    log_info "Swap memory added successfully: $swap_size"
    log_info "Total swap available: $total_swap"
}

# Remove swap memory
remove_swap_memory() {
    local swap_file="${1:-/swapfile}"
    
    require_root
    
    log_step "SYSTEM" "Removing swap memory: $swap_file"
    
    # Disable swap
    swapoff "$swap_file" 2>/dev/null || warn "Could not disable swap: $swap_file"
    
    # Remove from fstab
    backup_file "/etc/fstab" "/etc"
    sed -i "\|$swap_file|d" /etc/fstab
    
    # Remove swap file
    rm -f "$swap_file"
    
    log_info "Swap memory removed: $swap_file"
}

# Update system packages
update_system() {
    local upgrade="${1:-true}"
    
    require_root
    
    log_step "SYSTEM" "Updating system packages"
    
    local pm
    pm=$(detect_package_manager 2>/dev/null || echo "unknown")
    
    case "$pm" in
        apt)
            apt-get update || error_exit "Failed to update package lists"
            if [ "$upgrade" = "true" ]; then
                apt-get upgrade -y || warn "Some packages may not have been upgraded"
            fi
            ;;
        yum)
            yum check-update || true
            if [ "$upgrade" = "true" ]; then
                yum update -y || warn "Some packages may not have been updated"
            fi
            ;;
        dnf)
            dnf check-update || true
            if [ "$upgrade" = "true" ]; then
                dnf update -y || warn "Some packages may not have been updated"
            fi
            ;;
        *)
            error_exit "Unsupported package manager for system update: $pm"
            ;;
    esac
    
    log_info "System update completed"
}

# Clean system packages
clean_system() {
    require_root
    
    log_step "SYSTEM" "Cleaning system packages"
    
    local pm
    pm=$(detect_package_manager 2>/dev/null || echo "unknown")
    
    case "$pm" in
        apt)
            apt-get autoremove -y || warn "Could not remove unnecessary packages"
            apt-get autoclean || warn "Could not clean package cache"
            ;;
        yum)
            yum autoremove -y || warn "Could not remove unnecessary packages"
            yum clean all || warn "Could not clean package cache"
            ;;
        dnf)
            dnf autoremove -y || warn "Could not remove unnecessary packages"
            dnf clean all || warn "Could not clean package cache"
            ;;
        *)
            warn "System cleaning not supported for package manager: $pm"
            ;;
    esac
    
    log_info "System cleaning completed"
}

# =============================================================================
# SECURITY FUNCTIONS
# =============================================================================

# Configure firewall (ufw)
configure_firewall() {
    local action="$1"  # enable, disable, reset
    local ports="${2:-22,80,443}"  # comma-separated list
    
    require_root
    require_command "ufw"
    
    log_step "SECURITY" "Configuring firewall: $action"
    
    case "$action" in
        enable)
            ufw --force reset
            ufw default deny incoming
            ufw default allow outgoing
            
            # Allow specified ports
            IFS=',' read -ra PORT_ARRAY <<< "$ports"
            for port in "${PORT_ARRAY[@]}"; do
                ufw allow "$port" || warn "Could not allow port: $port"
            done
            
            ufw --force enable
            ;;
        disable)
            ufw --force disable
            ;;
        reset)
            ufw --force reset
            ;;
        *)
            error_exit "Invalid firewall action: $action (use: enable, disable, reset)"
            ;;
    esac
    
    log_info "Firewall configured: $action"
}

# Setup fail2ban
setup_fail2ban() {
    local services="${1:-ssh,apache-auth,apache-badbots}"
    
    require_root
    
    log_step "SECURITY" "Setting up fail2ban for services: $services"
    
    # Install fail2ban
    install_if_missing fail2ban
    
    # Create local jail configuration
    cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[ssh]
enabled = true

[apache-auth]
enabled = true

[apache-badbots]
enabled = true
EOF
    
    # Start and enable service
    enable_service fail2ban
    start_service fail2ban
    
    log_info "Fail2ban setup completed"
}

# =============================================================================
# PATH AND ENVIRONMENT MANAGEMENT
# =============================================================================

# Add directory to PATH
add_to_path() {
    local directory="$1"
    local user="${2:-$(get_current_user)}"
    local profile_file="${3:-$HOME/.bashrc}"
    
    log_step "PATH" "Adding directory to PATH: $directory"
    
    # Check if directory exists
    if [ ! -d "$directory" ]; then
        warn "Directory does not exist: $directory"
        return 1
    fi
    
    # Check if already in PATH
    if [[ ":$PATH:" == *":$directory:"* ]]; then
        log_debug "Directory already in PATH: $directory"
        return 0
    fi
    
    # Add to PATH in current session
    export PATH="$directory:$PATH"
    
    # Add to profile file for persistence
    echo "export PATH=\"$directory:\$PATH\"" >> "$profile_file"
    
    log_info "Directory added to PATH: $directory"
}

# Create symbolic link in PATH
create_path_link() {
    local target="$1"
    local link_name="$2"
    local bin_dir="${3:-$HOME/.local/bin}"
    
    log_step "LINK" "Creating symbolic link: $link_name -> $target"
    
    require_file "$target"
    
    # Create bin directory if it doesn't exist
    create_directory "$bin_dir"
    
    local link_path="$bin_dir/$link_name"
    
    # Remove existing link if it exists
    if [ -L "$link_path" ]; then
        rm "$link_path"
        log_debug "Existing symbolic link removed: $link_path"
    elif [ -e "$link_path" ]; then
        error_exit "A regular file exists at $link_path. Please remove it manually."
    fi
    
    # Create new symbolic link
    ln -s "$target" "$link_path" || error_exit "Failed to create symbolic link: $link_path"
    
    # Make sure bin directory is in PATH
    add_to_path "$bin_dir"
    
    log_info "Symbolic link created: $link_name -> $target"
}

# Setup development environment
setup_dev_environment() {
    local user="${1:-$(get_current_user)}"
    
    log_step "DEV" "Setting up development environment for user: $user"
    
    local home_dir
    home_dir=$(getent passwd "$user" | cut -d: -f6)
    
    # Create common directories
    create_directory "$home_dir/.local/bin" "$user" "$user" 755
    create_directory "$home_dir/projects" "$user" "$user" 755
    create_directory "$home_dir/scripts" "$user" "$user" 755
    
    # Add ~/.local/bin to PATH
    add_to_path "$home_dir/.local/bin" "$user" "$home_dir/.bashrc"
    
    # Install common development tools
    if [ "$EUID" -eq 0 ]; then
        install_build_tools
    else
        log_warn "Skipping package installation (not running as root)"
    fi
    
    log_info "Development environment setup completed for user: $user"
}

# Export functions
export -f create_user create_admin_user delete_user add_user_to_group remove_user_from_group
export -f setup_ssh_key generate_ssh_key set_hostname set_fqdn add_swap_memory remove_swap_memory
export -f update_system clean_system configure_firewall setup_fail2ban
export -f add_to_path create_path_link setup_dev_environment