#!/usr/bin/env bash

# ==============================================================================
# Script Name:  create-sysuser.sh
# Description:  Interactive, secure Linux system user creation script.
# Author:       Antigravity Pair-Programming Agent
# Date:         2026-07-03
# License:      MIT
# ==============================================================================

# Exit on error in subshells, and ensure pipes fail fast if any command fails
set -o pipefail

# ------------------------------------------------------------------------------
# Color Output Definitions
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# ------------------------------------------------------------------------------
# Logging Functions
# ------------------------------------------------------------------------------
log_info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1" >&2
}

log_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1" >&2
}

log_warning() {
    printf "${YELLOW}[WARNING]${NC} %s\n" "$1" >&2
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1" >&2
}

log_heading() {
    printf "\n${BOLD}${PURPLE}=== %s ===${NC}\n" "$1" >&2
}

# ------------------------------------------------------------------------------
# Security & System Checks
# ------------------------------------------------------------------------------
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root. Please run with sudo or as the root user."
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# Interactive Helper Functions
# ------------------------------------------------------------------------------
prompt_yes_no() {
    local prompt_text="$1"
    local default_val="$2" # "y" or "n"
    local choice
    local prompt_suffix

    if [[ "$default_val" == "y" || "$default_val" == "Y" ]]; then
        prompt_suffix="[Y/n]"
    else
        prompt_suffix="[y/N]"
    fi

    while true; do
        read -r -p "$prompt_text $prompt_suffix: " choice
        choice="${choice:-$default_val}"
        case "${choice:0:1}" in
            [yY]) return 0 ;;
            [nN]) return 1 ;;
            *) log_warning "Please enter y or n." ;;
        esac
    done
}

prompt_password() {
    local password
    local password_confirm
    while true; do
        # -s disables echoing of characters
        read -r -s -p "Enter password for the new user: " password
        echo >&2
        if [[ ${#password} -lt 8 ]]; then
            log_warning "Password should be at least 8 characters long for security."
            if ! prompt_yes_no "Use this password anyway?" "n"; then
                continue
            fi
        fi
        read -r -s -p "Confirm password: " password_confirm
        echo >&2
        if [[ "$password" == "$password_confirm" ]]; then
            echo "$password"
            return 0
        else
            log_error "Passwords do not match. Please try again."
        fi
    done
}

# ------------------------------------------------------------------------------
# Input Gathering & Validation Functions
# ------------------------------------------------------------------------------
get_username() {
    local username=""
    while true; do
        read -r -p "Enter username: " username
        if [[ -z "$username" ]]; then
            log_error "Username cannot be empty."
            continue
        fi
        # Validate format: 2-32 chars, lowercase, underscores, hyphens, starting with a letter/underscore
        if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]{1,31}$ ]]; then
            log_error "Invalid username. Must be 2-32 chars, lowercase letters, numbers, underscores, or hyphens, starting with a letter/underscore."
            continue
        fi
        # Check if user already exists
        if getent passwd "$username" >/dev/null 2>&1; then
            log_error "User '$username' already exists."
            continue
        fi
        break
    done
    echo "$username"
}

get_primary_group() {
    local username="$1"
    local default_group="$username"
    local groupname=""
    log_info "Every user must belong to a primary group, which defines default file ownership permissions."
    while true; do
        read -r -p "Enter primary group name [$default_group]: " groupname
        groupname="${groupname:-$default_group}"
        if [[ ! "$groupname" =~ ^[a-z_][a-z0-9_-]{1,31}$ ]]; then
            log_error "Invalid group name format."
            continue
        fi
        break
    done
    echo "$groupname"
}

get_custom_uid() {
    log_info "A User ID (UID) is a unique number assigned to each Linux user. By default, the system automatically assigns the next available UID."
    if prompt_yes_no "Do you want to assign a custom UID?" "n"; then
        local uid=""
        while true; do
            read -r -p "Enter custom UID: " uid
            if [[ ! "$uid" =~ ^[0-9]+$ ]]; then
                log_error "UID must be a number."
                continue
            fi
            if getent passwd "$uid" >/dev/null 2>&1; then
                local existing_user
                existing_user=$(getent passwd "$uid" | cut -d: -f1)
                log_error "UID $uid is already in use by user '$existing_user'."
                continue
            fi
            break
        done
        echo "$uid"
    else
        echo ""
    fi
}

get_supplementary_groups() {
    local groups_input=""
    local valid_groups=()
    log_info "Supplementary groups grant the user additional permissions (e.g., access to 'docker' or 'nginx' services)."
    read -r -p "Enter supplementary groups (space-separated, e.g. 'docker nginx sudo') [None]: " groups_input
    if [[ -n "$groups_input" ]]; then
        for g in $groups_input; do
            if getent group "$g" >/dev/null 2>&1; then
                valid_groups+=("$g")
            else
                log_warning "Group '$g' does not exist on the system. It will be skipped."
            fi
        done
    fi
    echo "${valid_groups[*]}"
}

get_ssh_options() {
    log_heading "SSH Access Configuration"
    log_info "SSH access allows remote login to the system. Disabling it makes the account a local 'service account' (more secure)."
    echo "Choose SSH access option for the system user:" >&2
    echo "  A) SSH Enabled  - Allow remote SSH login" >&2
    echo "  B) SSH Disabled - Service-only local account (more secure)" >&2
    
    local ssh_choice=""
    while true; do
        read -r -p "Select option [A/B] (default: B): " ssh_choice
        ssh_choice="${ssh_choice:-B}"
        case "${ssh_choice^^}" in
            A)
                echo "true"
                return 0
                ;;
            B)
                echo "false"
                return 0
                ;;
            *)
                log_error "Invalid selection. Please choose A or B."
                ;;
        esac
    done
}

get_home_dir() {
    local username="$1"
    local ssh_enabled="$2"
    if [[ "$ssh_enabled" == "true" ]]; then
        log_info "A Home Directory stores the user's personal files, configurations, and SSH keys."
        if prompt_yes_no "Do you want to create a home directory for this user (recommended for SSH key authentication)?" "n"; then
            local default_home="/home/$username"
            local home_dir
            while true; do
                read -r -p "Enter home directory [$default_home]: " home_dir
                home_dir="${home_dir:-$default_home}"
                if [[ ! "$home_dir" =~ ^/ ]]; then
                    log_error "Home directory must be an absolute path starting with /."
                    continue
                fi
                break
            done
            echo "$home_dir"
        else
            echo "/nonexistent"
        fi
    else
        echo "/nonexistent"
    fi
}

get_working_dir() {
    local username="$1"
    local default_work="/var/www/$username"
    local work_dir
    log_info "An application working directory is a dedicated directory (typically under /var/www) for the user's application files."
    if prompt_yes_no "Do you want to create an application working directory?" "n"; then
        while true; do
            read -r -p "Enter working directory [$default_work]: " work_dir
            work_dir="${work_dir:-$default_work}"
            if [[ ! "$work_dir" =~ ^/ ]]; then
                log_error "Working directory must be an absolute path starting with /."
                continue
            fi
            break
        done
        echo "$work_dir"
    else
        echo ""
    fi
}

get_shell() {
    local ssh_enabled="$1"
    if [[ "$ssh_enabled" == "true" ]]; then
        log_info "The shell is the command-line environment (like bash) that the user gets when logging in."
        local default_shell="/bin/bash"
        local user_shell
        while true; do
            read -r -p "Enter shell [$default_shell]: " user_shell
            user_shell="${user_shell:-$default_shell}"
            if [[ ! -x "$user_shell" ]]; then
                log_warning "Shell '$user_shell' is not executable or not found on the system."
                if ! prompt_yes_no "Use it anyway?" "n"; then
                    continue
                fi
            fi
            break
        done
        echo "$user_shell"
    else
        echo "/usr/sbin/nologin"
    fi
}

get_auth_method() {
    log_heading "SSH Authentication Method"
    log_info "SSH Key auth uses cryptographic keys (very secure). Password auth uses standard passwords (less secure)."
    echo "Select SSH Authentication Method:" >&2
    echo "  1) SSH Key (recommended, more secure)" >&2
    echo "  2) Password" >&2
    echo "  3) Both (Allow either SSH Key or Password)" >&2
    
    local auth_choice=""
    while true; do
        read -r -p "Select method [1-3] (default: 1): " auth_choice
        auth_choice="${auth_choice:-1}"
        case "$auth_choice" in
            1) echo "key"; return 0 ;;
            2) echo "password"; return 0 ;;
            3) echo "both"; return 0 ;;
            *) log_error "Invalid selection. Please choose 1, 2, or 3." ;;
        esac
    done
}

validate_ssh_key_string() {
    local key="$1"
    # Match standard public key formats: ssh-rsa, ssh-ed25519, ecdsa-sha2-*, ssh-dss
    if [[ "$key" =~ ^(ssh-rsa|ssh-ed25519|ecdsa-sha2-[a-zA-Z0-9-]+|ssh-dss)\ [A-Za-z0-9+/=]+ ]]; then
        return 0
    else
        return 1
    fi
}

get_ssh_key() {
    log_info "You can provide a public key by specifying a file path or pasting the key content directly."
    
    # Check common locations for the real user running the script via sudo or root
    local user_home="$HOME"
    if [[ -n "$SUDO_USER" ]]; then
        user_home=$(eval echo "~$SUDO_USER")
    fi
    
    local default_key_path=""
    if [[ -f "$user_home/.ssh/id_ed25519.pub" ]]; then
        default_key_path="$user_home/.ssh/id_ed25519.pub"
    elif [[ -f "$user_home/.ssh/id_rsa.pub" ]]; then
        default_key_path="$user_home/.ssh/id_rsa.pub"
    fi

    local prompt_msg="Enter file path to public key (e.g. ~/.ssh/id_ed25519.pub) OR paste the raw key"
    if [[ -n "$default_key_path" ]]; then
        prompt_msg="Enter file path to public key OR paste the raw key [$(basename "$default_key_path")]"
    fi
    prompt_msg="$prompt_msg: "

    local key_input=""
    local key_content=""
    while true; do
        read -r -p "$prompt_msg" key_input
        key_input="${key_input:-$default_key_path}"
        if [[ -z "$key_input" ]]; then
            log_error "SSH key cannot be empty when using key authentication."
            continue
        fi
        
        # Manually expand ~ to HOME if necessary
        local expanded_path="${key_input/#\~/$user_home}"
        if [[ -f "$expanded_path" ]]; then
            if ! key_content=$(cat "$expanded_path" 2>/dev/null); then
                log_error "Could not read file at '$expanded_path'."
                continue
            fi
            if validate_ssh_key_string "$key_content"; then
                echo "$key_content"
                return 0
            fi
        else
            if validate_ssh_key_string "$key_input"; then
                echo "$key_input"
                return 0
            fi
        fi
        log_error "Invalid SSH public key format. Must start with ssh-rsa, ssh-ed25519, ecdsa-sha2-*, or ssh-dss."
    done
}

get_ssh_key_restrictions() {
    log_info "SSH key restrictions limit what the user can do when logged in with this key (e.g. blocking port forwarding/X11)."
    if prompt_yes_no "Do you want to restrict SSH key permissions?" "n"; then
        echo "restrict,pty"
    else
        echo ""
    fi
}

get_force_key_auth() {
    local auth_method="$1"
    if [[ "$auth_method" == "key" ]]; then
        log_info "Disabling password auth ensures the user can ONLY log in via their SSH key."
        if prompt_yes_no "Do you want to explicitly disable password authentication for this user in SSH daemon configuration?" "n"; then
            echo "true"
        else
            echo "false"
        fi
    else
        echo "false"
    fi
}

get_chroot() {
    local ssh_enabled="$1"
    if [[ "$ssh_enabled" == "true" ]]; then
        log_info "A Chroot Jail isolates a user by restricting their directory access to a specific path, preventing them from viewing the rest of the filesystem."
        if prompt_yes_no "Do you want to jail/chroot the user (advanced)?" "n"; then
            log_info "Jailing restricts the user to a specific directory branch."
            echo "1) SFTP-only Chroot (restricts user to SFTP, disables shell access)" >&2
            echo "2) Custom SSH Chroot directory (requires manual files setup to work)" >&2
            local choice
            while true; do
                read -r -p "Choose chroot option [1-2] (default: 1): " choice
                choice="${choice:-1}"
                case "$choice" in
                    1)
                        local chroot_dir
                        read -r -p "Enter chroot directory path [/home/%u or custom]: " chroot_dir
                        chroot_dir="${chroot_dir:-/home/%u}"
                        echo "sftp:$chroot_dir"
                        break
                        ;;
                    2)
                        local chroot_dir
                        read -r -p "Enter custom chroot directory: " chroot_dir
                        if [[ ! "$chroot_dir" =~ ^/ ]]; then
                            log_error "Chroot directory must be an absolute path."
                            continue
                        fi
                        echo "custom:$chroot_dir"
                        break
                        ;;
                    *) log_error "Invalid choice." ;;
                esac
            done
        else
            echo ""
        fi
    else
        echo ""
    fi
}

get_subdirs() {
    local work_dir="$1"
    if [[ -n "$work_dir" ]]; then
        log_info "Standard subdirectories (logs, tmp, cache) can be automatically created and configured with appropriate permissions."
        if prompt_yes_no "Create standard subdirectories (logs, tmp, cache) under the working directory?" "n"; then
            echo "logs tmp cache"
        else
            echo ""
        fi
    else
        echo ""
    fi
}

get_limits() {
    log_info "Resource limits (ulimits) restrict system resources like max open files or processes the user can start, preventing resource exhaustion."
    if prompt_yes_no "Configure custom security/resource limits (ulimit) for this user?" "n"; then
        local max_files
        local max_procs
        read -r -p "Enter max open files (nofile) [65536]: " max_files
        max_files="${max_files:-65536}"
        read -r -p "Enter max processes (nproc) [4096]: " max_procs
        max_procs="${max_procs:-4096}"
        echo "$max_files:$max_procs"
    else
        echo ""
    fi
}

get_sudo_rules() {
    log_info "Sudo permissions allow the user to execute administrative commands as root or other users."
    if prompt_yes_no "Configure sudo permissions for this user?" "n"; then
        log_info "Sudo Options:"
        echo "  1) Full root privileges (requires user password confirmation)" >&2
        echo "  2) Full root privileges WITHOUT password (NOPASSWD)" >&2
        echo "  3) Specific commands only (restricted)" >&2
        local choice
        while true; do
            read -r -p "Choose sudo option [1-3] (default: 1): " choice
            choice="${choice:-1}"
            case "$choice" in
                1) echo "full:passwd"; break ;;
                2) echo "full:nopasswd"; break ;;
                3)
                    local cmds
                    read -r -p "Enter comma-separated commands (absolute paths, e.g. '/usr/bin/systemctl restart nginx,/usr/bin/git'): " cmds
                    if [[ -z "$cmds" ]]; then
                        log_error "Commands list cannot be empty for restricted sudo."
                        continue
                    fi
                    echo "restricted:$cmds"
                    break
                    ;;
                *) log_error "Invalid choice." ;;
            esac
        done
    else
        echo ""
    fi
}

get_switch_alias() {
    log_info "A shell alias (e.g. 'to-sysdevtwin') allows root to quickly switch to this user's context without typing the full 'su' command."
    if prompt_yes_no "Create a helper shell alias 'to-username' for root to quickly switch to this user?" "n"; then
        echo "true"
    else
        echo "false"
    fi
}

# ------------------------------------------------------------------------------
# Warning & Summary Displays
# ------------------------------------------------------------------------------
warn_password_security() {
    if [[ "$auth_method" == "password" || "$auth_method" == "both" ]]; then
        log_warning "Password authentication is enabled. This increases susceptibility to brute-force attacks."
        log_warning "It is highly recommended to enforce SSH Key-only authentication in production environments."
    fi
}

show_summary() {
    log_heading "Configuration Summary Review"
    printf "${BOLD}%-30s:${NC} %s\n" "Username" "$username"
    printf "${BOLD}%-30s:${NC} %s\n" "UID" "${uid:-Default (Auto-assigned)}"
    printf "${BOLD}%-30s:${NC} %s\n" "Primary Group" "$groupname"
    printf "${BOLD}%-30s:${NC} %s\n" "Supplementary Groups" "${supp_groups:-None}"
    printf "${BOLD}%-30s:${NC} %s\n" "Shell" "$shell"
    printf "${BOLD}%-30s:${NC} %s\n" "Description/Comment" "$comment"
    
    if [[ "$ssh_enabled" == "true" ]]; then
        printf "${BOLD}%-30s:${NC} %s\n" "SSH Access" "${GREEN}Enabled${NC}"
        printf "${BOLD}%-30s:${NC} %s\n" "Home Directory" "$home_dir"
        printf "${BOLD}%-30s:${NC} %s\n" "Auth Method" "${auth_method^^}"
        if [[ "$auth_method" == "key" || "$auth_method" == "both" ]]; then
            printf "${BOLD}%-30s:${NC} %s\n" "SSH Key Configured" "Yes"
            if [[ -n "$ssh_restrictions" ]]; then
                printf "${BOLD}%-30s:${NC} %s\n" "SSH Key Restrictions" "$ssh_restrictions"
            else
                printf "${BOLD}%-30s:${NC} %s\n" "SSH Key Restrictions" "None"
            fi
            printf "${BOLD}%-30s:${NC} %s\n" "Force Key-Only SSH" "$force_key_auth"
        fi
        if [[ "$auth_method" == "password" || "$auth_method" == "both" ]]; then
            printf "${BOLD}%-30s:${NC} %s\n" "Password Configured" "Yes"
        fi
        if [[ -n "$chroot" ]]; then
            printf "${BOLD}%-30s:${NC} %s\n" "Chroot Jail" "$chroot"
        else
            printf "${BOLD}%-30s:${NC} %s\n" "Chroot Jail" "Disabled"
        fi
    else
        printf "${BOLD}%-30s:${NC} %s\n" "SSH Access" "${RED}Disabled (Service Account)${NC}"
        printf "${BOLD}%-30s:${NC} %s\n" "Home Directory" "None (/nonexistent)"
    fi
    
    if [[ -n "$work_dir" ]]; then
        printf "${BOLD}%-30s:${NC} %s\n" "Working Directory" "$work_dir"
        printf "${BOLD}%-30s:${NC} %s\n" "Create Subdirectories" "${subdirs:-None}"
    else
        printf "${BOLD}%-30s:${NC} %s\n" "Working Directory" "None"
    fi
    
    if [[ -n "$limits" ]]; then
        local max_files
        local max_procs
        max_files=$(echo "$limits" | cut -d: -f1)
        max_procs=$(echo "$limits" | cut -d: -f2)
        printf "${BOLD}%-30s:${NC} Max Files: %s, Max Procs: %s\n" "Resource Limits" "$max_files" "$max_procs"
    else
        printf "${BOLD}%-30s:${NC} %s\n" "Resource Limits" "Default"
    fi
    
    if [[ -n "$sudo_rules" ]]; then
        printf "${BOLD}%-30s:${NC} %s\n" "Sudo Configuration" "$sudo_rules"
    else
        printf "${BOLD}%-30s:${NC} %s\n" "Sudo Configuration" "No Sudo Access"
    fi
    echo
}

# ------------------------------------------------------------------------------
# Implementation Configurations
# ------------------------------------------------------------------------------
setup_force_key_auth() {
    if [[ "$force_key_auth" == "true" ]]; then
        local sshd_config_dir="/etc/ssh/sshd_config.d"
        local config_file="$sshd_config_dir/99-sysuser-$username.conf"
        
        # Check if the directory exists and if sshd_config includes it
        if [[ -d "$sshd_config_dir" ]] && grep -iq "^Include /etc/ssh/sshd_config.d/\*.conf" /etc/ssh/sshd_config; then
            log_info "Creating SSH daemon config override in $config_file..."
            cat <<EOF > "$config_file"
# Disable password auth for user $username
Match User $username
    PasswordAuthentication no
EOF
            chmod 644 "$config_file"
            ssh_reloaded_required="true"
        else
            log_warning "Could not automatically write config to $sshd_config_dir. Please append the following to /etc/ssh/sshd_config manually:"
            printf "${BLUE}Match User %s${NC}\n" "$username"
            printf "${BLUE}    PasswordAuthentication no${NC}\n"
        fi
    fi
}

setup_chroot() {
    if [[ -n "$chroot" ]]; then
        local chroot_type
        local chroot_path
        chroot_type=$(echo "$chroot" | cut -d: -f1)
        chroot_path=$(echo "$chroot" | cut -d: -f2)
        
        # Substitute %u with the actual username
        chroot_path="${chroot_path//%u/$username}"
        
        log_info "Setting up Chroot Jail at '$chroot_path'..."
        mkdir -p "$chroot_path"
        
        # SSH ChrootDirectory MUST be owned by root and not writable by any other user or group
        log_info "Enforcing root ownership and 755 permissions on Chroot directory..."
        chown root:root "$chroot_path"
        chmod 755 "$chroot_path"
        
        if [[ "$chroot_type" == "sftp" ]]; then
            local sshd_config_dir="/etc/ssh/sshd_config.d"
            local config_file="$sshd_config_dir/99-sysuser-$username.conf"
            
            if [[ -d "$sshd_config_dir" ]] && grep -iq "^Include /etc/ssh/sshd_config.d/\*.conf" /etc/ssh/sshd_config; then
                # Append to existing or create new config file
                {
                    echo ""
                    echo "# Chroot configuration for user $username"
                    echo "Match User $username"
                    echo "    ChrootDirectory $chroot_path"
                    echo "    ForceCommand internal-sftp"
                    echo "    AllowTcpForwarding no"
                    echo "    X11Forwarding no"
                } >> "$config_file"
                chmod 644 "$config_file"
                ssh_reloaded_required="true"
            else
                log_warning "Could not automatically write SSH chroot configuration. Please append this to /etc/ssh/sshd_config manually:"
                printf "${BLUE}Match User %s${NC}\n" "$username"
                printf "${BLUE}    ChrootDirectory %s${NC}\n" "$chroot_path"
                printf "${BLUE}    ForceCommand internal-sftp${NC}\n"
                printf "${BLUE}    AllowTcpForwarding no${NC}\n"
                printf "${BLUE}    X11Forwarding no${NC}\n"
            fi
            
            # Since the user cannot write to the root-owned chroot directory itself, we create a writable subdirectory
            local uploads_dir="$chroot_path/uploads"
            log_info "Creating writable subdirectory for uploads: '$uploads_dir'..."
            mkdir -p "$uploads_dir"
            chown "$username:$groupname" "$uploads_dir"
            chmod 750 "$uploads_dir"
        fi
    fi
}

setup_sudo_rules() {
    if [[ -n "$sudo_rules" ]]; then
        local sudo_type
        local sudo_cmds
        sudo_type=$(echo "$sudo_rules" | cut -d: -f1)
        sudo_cmds=$(echo "$sudo_rules" | cut -d: -f2)
        
        local sudo_file="/etc/sudoers.d/$username"
        log_info "Writing sudo rules to '$sudo_file'..."
        
        if [[ "$sudo_type" == "full" ]]; then
            if [[ "$sudo_cmds" == "nopasswd" ]]; then
                echo "$username ALL=(ALL:ALL) NOPASSWD: ALL" > "$sudo_file"
            else
                echo "$username ALL=(ALL:ALL) ALL" > "$sudo_file"
            fi
        elif [[ "$sudo_type" == "restricted" ]]; then
            echo "$username ALL=(ALL:ALL) NOPASSWD: $sudo_cmds" > "$sudo_file"
        fi
        
        # Verify sudoers syntax using visudo
        if visudo -cf "$sudo_file" >/dev/null 2>&1; then
            chmod 440 "$sudo_file"
            log_success "Sudo rules configured successfully."
        else
            log_error "Sudo configuration invalid. Removing $sudo_file to protect sudo system safety."
            rm -f "$sudo_file"
        fi
    fi
}

setup_switch_alias() {
    if [[ "$switch_alias" == "true" ]]; then
        local alias_file="/root/.bash_aliases"
        if [[ ! -f "$alias_file" ]]; then
            alias_file="/root/.bashrc"
        fi
        log_info "Adding helper alias 'to-$username' to '$alias_file'..."
        echo "alias to-$username='sudo -i -u $username'" >> "$alias_file"
        log_success "Alias 'to-$username' added. Run 'exec bash' or source your terminal configs to activate."
    fi
}

show_post_creation() {
    log_heading "User Creation Complete!"
    log_success "User '$username' has been successfully configured."
    
    # Retrieve actual UID and GID to ensure correctness
    local actual_uid
    local actual_gid
    actual_uid=$(id -u "$username")
    actual_gid=$(id -g "$username")
    
    printf "${BOLD}%-20s:${NC} %s\n" "Username" "$username"
    printf "${BOLD}%-20s:${NC} %s (UID: %s)\n" "Primary Group" "$groupname" "$actual_gid"
    printf "${BOLD}%-20s:${NC} %s\n" "UID" "$actual_uid"
    printf "${BOLD}%-20s:${NC} %s\n" "Home Directory" "$home_dir"
    printf "${BOLD}%-20s:${NC} %s\n" "Shell" "$shell"
    
    if [[ -n "$work_dir" ]]; then
        printf "${BOLD}%-20s:${NC} %s\n" "Working Directory" "$work_dir"
    fi
    
    if [[ "$ssh_enabled" == "true" ]]; then
        log_heading "SSH Connection & Login Information"
        local ip_address
        ip_address=$(hostname -I | awk '{print $1}')
        ip_address="${ip_address:-<your-server-ip>}"
        
        echo "The user can connect using the following command structure:"
        if [[ "$auth_method" == "key" || "$auth_method" == "both" ]]; then
            printf "  ${GREEN}ssh -i /path/to/private_key %s@%s${NC}\n" "$username" "$ip_address"
            if [[ -n "$chroot" ]]; then
                log_info "Note: User is locked in a Chroot Jail ($chroot). They will be jailed upon connecting."
            fi
        fi
        if [[ "$auth_method" == "password" || "$auth_method" == "both" ]]; then
            printf "  ${GREEN}ssh %s@%s${NC} (and enter password)\n" "$username" "$ip_address"
        fi
        
        if [[ "$ssh_reloaded_required" == "true" ]]; then
            log_warning "Important: You MUST reload the SSH service to apply configurations:"
            printf "  ${YELLOW}systemctl reload ssh${NC}  or  ${YELLOW}systemctl reload sshd${NC}\n"
        fi
    else
        log_heading "Service Account Usage"
        log_info "This is a service-only account. Interactive login and SSH are disabled."
        echo "You can run processes or daemons under this user."
    fi
    
    log_heading "Systemd Service Example Template"
    echo "To run a daemon/service as this user, save this to /etc/systemd/system/myservice.service:"
    printf "${CYAN}"
    cat <<EOF
[Unit]
Description=My Daemon running as $username
After=network.target

[Service]
Type=simple
User=$username
Group=$groupname
EOF
    if [[ -n "$work_dir" ]]; then
        echo "WorkingDirectory=$work_dir"
    fi
    cat <<EOF
ExecStart=/path/to/your/executable --args
Restart=on-failure

# Security enhancements
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=${work_dir:-/var/tmp}

[Install]
WantedBy=multi-user.target
EOF
    printf "${NC}\n"
    
    log_heading "Test & Debugging Commands"
    echo "1. Run a command as this user from root/sudo:"
    printf "   ${GREEN}sudo -u %s whoami${NC}\n" "$username"
    
    if [[ "$ssh_enabled" == "true" ]]; then
        echo "2. Run an interactive shell as this user (for testing):"
        printf "   ${GREEN}sudo -i -u %s${NC}\n" "$username"
    else
        echo "2. Attempt interactive shell (should fail):"
        printf "   ${GREEN}sudo -u %s -s${NC} (expected: shell will print 'This account is currently not available.' and exit)\n" "$username"
    fi
    
    log_heading "Deletion Instructions"
    echo "To completely remove this user and all associated configurations, execute the following as root:"
    printf "  ${RED}sudo userdel -r %s${NC}\n" "$username"
    if [[ -f "/etc/security/limits.d/$username.conf" ]]; then
        printf "  ${RED}sudo rm -f /etc/security/limits.d/%s.conf${NC}\n" "$username"
    fi
    if [[ -f "/etc/sudoers.d/$username" ]]; then
        printf "  ${RED}sudo rm -f /etc/sudoers.d/%s${NC}\n" "$username"
    fi
    if [[ -f "/etc/ssh/sshd_config.d/99-sysuser-$username.conf" ]]; then
        printf "  ${RED}sudo rm -f /etc/ssh/sshd_config.d/99-sysuser-%s.conf${NC}\n" "$username"
        printf "  ${RED}sudo systemctl reload sshd${NC}\n"
    fi
    echo
}

# ------------------------------------------------------------------------------
# Main Application Flow
# ------------------------------------------------------------------------------
main() {
    # 1. Root check
    check_root
    
    # Global state vars
    local username=""
    local uid=""
    local groupname=""
    local supp_groups=""
    local ssh_enabled="false"
    local home_dir=""
    local shell=""
    local comment=""
    local auth_method=""
    local ssh_key=""
    local ssh_restrictions=""
    local force_key_auth="false"
    local password=""
    local chroot=""
    local work_dir=""
    local subdirs=""
    local limits=""
    local sudo_rules=""
    local switch_alias="false"
    local ssh_reloaded_required="false"

    # 2. Welcome Banner
    log_heading "Linux Interactive System User Creator"
    log_info "This script will guide you through creating a system or interactive user."
    log_info "Press Enter at any prompt to accept the default value [shown in brackets]."
    
    # 3. Gather username
    username=$(get_username)
    
    # 4. Custom UID
    uid=$(get_custom_uid)
    
    # 5. Primary group
    groupname=$(get_primary_group "$username")
    
    # 6. Supplementary groups
    supp_groups=$(get_supplementary_groups)
    
    # 7. SSH access choice (Option A or Option B)
    local ssh_choice
    ssh_choice=$(get_ssh_options)
    if [[ "$ssh_choice" == "true" ]]; then
        ssh_enabled="true"
    else
        ssh_enabled="false"
    fi
    
    # 8. Home directory and Shell
    home_dir=$(get_home_dir "$username" "$ssh_enabled")
    shell=$(get_shell "$ssh_enabled")
    
    # 9. User Description / Comment
    local default_comment="System user for $username"
    read -r -p "Enter user description/comment [$default_comment]: " comment
    comment="${comment:-$default_comment}"
    
    # 10. SSH specific configs if enabled
    if [[ "$ssh_enabled" == "true" ]]; then
        auth_method=$(get_auth_method)
        if [[ "$auth_method" == "key" || "$auth_method" == "both" ]]; then
            ssh_key=$(get_ssh_key)
            ssh_restrictions=$(get_ssh_key_restrictions)
            force_key_auth=$(get_force_key_auth "$auth_method")
        else
            ssh_key=""
            ssh_restrictions=""
            force_key_auth="false"
        fi
        
        if [[ "$auth_method" == "password" || "$auth_method" == "both" ]]; then
            password=$(prompt_password)
        else
            password=""
        fi
        
        chroot=$(get_chroot "$ssh_enabled")
    else
        auth_method=""
        ssh_key=""
        ssh_restrictions=""
        force_key_auth="false"
        password=""
        chroot=""
    fi
    
    # 11. Working Directory & Subdirectories
    work_dir=$(get_working_dir "$username")
    subdirs=$(get_subdirs "$work_dir")
    
    # 12. Resource Limits
    limits=$(get_limits)
    
    # 13. Sudo Rules
    sudo_rules=$(get_sudo_rules)
    
    # 14. Switch Helper Alias
    switch_alias=$(get_switch_alias)
    
    # 15. Security warnings
    warn_password_security
    
    # 16. Show Summary & Confirm
    show_summary
    
    if ! prompt_yes_no "Do you want to proceed with user creation based on these settings?" "n"; then
        log_warning "User creation cancelled. No changes were made to the system."
        exit 0
    fi
    
    # 17. Perform User Creation Actions
    log_heading "Executing User Creation Tasks"
    
    # Step A: Primary Group Creation
    if ! getent group "$groupname" >/dev/null 2>&1; then
        log_info "Creating group '$groupname'..."
        if ! groupadd "$groupname"; then
            log_error "Failed to create group '$groupname'."
            exit 1
        fi
        log_success "Group '$groupname' created."
    fi
    
    # Step B: Useradd execution
    local useradd_args=()
    if [[ "$ssh_enabled" == "true" ]]; then
        if [[ "$home_dir" == "/nonexistent" ]]; then
            useradd_args+=("-M" "-d" "/nonexistent" "-s" "$shell")
        else
            useradd_args+=("-m" "-d" "$home_dir" "-s" "$shell")
        fi
    else
        useradd_args+=("-M" "-d" "/nonexistent" "-s" "/usr/sbin/nologin")
    fi
    
    useradd_args+=("-c" "$comment")
    
    if [[ -n "$uid" ]]; then
        useradd_args+=("-u" "$uid")
    fi
    
    useradd_args+=("-g" "$groupname")
    
    if [[ -n "$supp_groups" ]]; then
        local supp_groups_comma
        supp_groups_comma=$(echo "$supp_groups" | tr ' ' ',')
        useradd_args+=("-G" "$supp_groups_comma")
    fi
    
    useradd_args+=("$username")
    
    log_info "Executing: useradd ${useradd_args[*]}"
    if ! useradd "${useradd_args[@]}"; then
        log_error "Failed to create user '$username' using useradd."
        exit 1
    fi
    log_success "User '$username' created successfully."
    
    # Step C: Home directory permission check
    if [[ "$ssh_enabled" == "true" ]]; then
        log_info "Securing home directory permissions to 700..."
        chmod 700 "$home_dir"
        chown "$username:$groupname" "$home_dir"
    fi
    
    # Step D: Password setup
    if [[ -n "$password" ]]; then
        log_info "Setting password..."
        if ! echo "$username:$password" | chpasswd; then
            log_error "Failed to set password."
            exit 1
        fi
        log_success "Password set successfully."
    else
        log_info "Locking password for SSH-key only login..."
        passwd -l "$username" >/dev/null 2>&1
    fi
    
    # Step E: SSH Setup
    if [[ "$ssh_enabled" == "true" ]] && [[ -n "$ssh_key" ]]; then
        local ssh_dir="$home_dir/.ssh"
        log_info "Creating SSH configuration..."
        mkdir -p "$ssh_dir"
        chmod 700 "$ssh_dir"
        
        local key_entry="$ssh_key"
        if [[ -n "$ssh_restrictions" ]]; then
            key_entry="$ssh_restrictions $ssh_key"
        fi
        
        echo "$key_entry" > "$ssh_dir/authorized_keys"
        chmod 600 "$ssh_dir/authorized_keys"
        chown -R "$username:$groupname" "$ssh_dir"
        log_success "SSH authorized_keys configured."
    fi
    
    # Step F: Force key authentication in sshd
    setup_force_key_auth
    
    # Step G: Working Directory creation
    if [[ -n "$work_dir" ]]; then
        log_info "Creating working directory '$work_dir'..."
        mkdir -p "$work_dir"
        chown "$username:$groupname" "$work_dir"
        chmod 750 "$work_dir"
        
        if [[ -n "$subdirs" ]]; then
            for s in $subdirs; do
                local subdir_path="$work_dir/$s"
                log_info "Creating subdirectory '$subdir_path'..."
                mkdir -p "$subdir_path"
                chown "$username:$groupname" "$subdir_path"
                if [[ "$s" == "tmp" ]]; then
                    chmod 1770 "$subdir_path"
                else
                    chmod 750 "$subdir_path"
                fi
            done
        fi
        log_success "Working directory configured."
    fi
    
    # Step H: Chroot setup
    setup_chroot
    
    # Step I: Resource limits
    if [[ -n "$limits" ]]; then
        local max_files
        local max_procs
        max_files=$(echo "$limits" | cut -d: -f1)
        max_procs=$(echo "$limits" | cut -d: -f2)
        local limits_file="/etc/security/limits.d/$username.conf"
        
        log_info "Setting resource limits in '$limits_file'..."
        cat <<EOF > "$limits_file"
# Resource limits for $username
$username   soft    nofile    $max_files
$username   hard    nofile    $max_files
$username   soft    nproc     $max_procs
$username   hard    nproc     $max_procs
EOF
        chmod 644 "$limits_file"
        log_success "Resource limits written."
    fi
    
    # Step J: Sudo setup
    setup_sudo_rules
    
    # Step K: Root shell alias
    setup_switch_alias
    
    # 18. Show Post Creation Instructions
    show_post_creation
}

# Run the script
main "$@"
