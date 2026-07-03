#!/usr/bin/env bash

# ==============================================================================
# Script Name:  delete-sysuser.sh
# Description:  Interactive, secure Linux system user deletion and cleanup script.
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
# Global Variables
# ------------------------------------------------------------------------------
FORCE_YES=false

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------
prompt_yes_no() {
    local prompt_text="$1"
    local default_val="$2" # "y" or "n"
    
    if [[ "$FORCE_YES" == "true" ]]; then
        return 0
    fi
    
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

show_usage() {
    echo "Usage: $0 [options] [username]"
    echo
    echo "Options:"
    echo "  -y, --yes, -f, --force    Non-interactive mode, automatically answer yes to all prompts"
    echo "  -h, --help                Show this help message and exit"
    echo
    echo "If username is not provided, you will be prompted for it interactively."
}

kill_user_processes() {
    local username="$1"
    
    # Clean up crontab before killing processes to prevent any scheduled cron from spawning new ones
    if crontab -l -u "$username" >/dev/null 2>&1; then
        log_info "Removing crontab for '$username'..."
        if crontab -r -u "$username"; then
            log_success "Crontab removed."
        else
            log_warning "Failed to remove crontab."
        fi
    fi

    if pgrep -u "$username" >/dev/null; then
        log_warning "User '$username' has running processes:"
        ps -u "$username" -o pid,ppid,cmd
        
        if prompt_yes_no "Terminate all running processes for '$username'?" "n"; then
            log_info "Sending SIGTERM to user processes..."
            pkill -15 -u "$username"
            sleep 2
            if pgrep -u "$username" >/dev/null; then
                log_warning "Some processes did not exit. Sending SIGKILL..."
                pkill -9 -u "$username"
                sleep 1
            fi
            if pgrep -u "$username" >/dev/null; then
                log_error "Failed to terminate some processes. User deletion may fail if files are locked."
            else
                log_success "All processes terminated."
            fi
        else
            log_warning "Proceeding without killing processes. Deletion might fail if files are in use."
        fi
    fi
}

# ------------------------------------------------------------------------------
# Main Script Flow
# ------------------------------------------------------------------------------
main() {
    # 1. Root check
    check_root
    
    local username=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y|--yes|-f|--force)
                FORCE_YES=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [[ -n "$username" ]]; then
                    log_error "Multiple usernames specified. Only one user can be deleted at a time."
                    show_usage
                    exit 1
                fi
                username="$1"
                shift
                ;;
        esac
    done

    # 2. Welcome Banner
    log_heading "Linux Interactive System User Deletion & Cleanup"
    log_info "This script will revoke access, clean up configurations, and delete a system user."
    
    # 3. Gather username if not provided
    if [[ -z "$username" ]]; then
        if [[ "$FORCE_YES" == "true" ]]; then
            log_error "Username must be specified on the command line when running in non-interactive mode."
            exit 1
        fi
        
        while true; do
            read -r -p "Enter username to delete: " username
            if [[ -z "$username" ]]; then
                log_error "Username cannot be empty."
                continue
            fi
            break
        done
    fi

    # Validate username format
    if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]{1,31}$ ]]; then
        log_error "Invalid username format: '$username'"
        exit 1
    fi

    # Check if user exists
    if ! getent passwd "$username" >/dev/null 2>&1; then
        log_error "User '$username' does not exist on this system."
        exit 1
    fi

    # 4. Gather User details
    log_heading "Information Gathering"
    
    local user_uid
    local primary_gid
    local primary_group
    local home_dir
    local shell
    
    user_uid=$(id -u "$username")
    primary_gid=$(id -g "$username")
    primary_group=$(id -gn "$username")
    home_dir=$(getent passwd "$username" | cut -d: -f6)
    shell=$(getent passwd "$username" | cut -d: -f7)
    
    log_info "User '$username' found with UID: $user_uid"
    log_info "Primary Group: $primary_group (GID: $primary_gid)"
    log_info "Home Directory: $home_dir"
    log_info "Shell: $shell"
    
    # Look for SSH config file override
    local ssh_override_file="/etc/ssh/sshd_config.d/99-sysuser-$username.conf"
    local chroot_dir=""
    if [[ -f "$ssh_override_file" ]]; then
        log_info "Found SSH override config: $ssh_override_file"
        # Parse ChrootDirectory if present
        chroot_dir=$(grep -i "ChrootDirectory" "$ssh_override_file" | awk '{print $2}')
        if [[ -n "$chroot_dir" ]]; then
            # Substitute %u if present
            chroot_dir="${chroot_dir//%u/$username}"
            log_info "Detected Chroot Directory: $chroot_dir"
        fi
    fi
    
    # Look for Sudoers rule file
    local sudoers_file="/etc/sudoers.d/$username"
    local has_sudoers=false
    if [[ -f "$sudoers_file" ]]; then
        log_info "Found Sudoers file: $sudoers_file"
        has_sudoers=true
    fi
    
    # Look for limits configuration
    local limits_file="/etc/security/limits.d/$username.conf"
    local has_limits=false
    if [[ -f "$limits_file" ]]; then
        log_info "Found limits configuration file: $limits_file"
        has_limits=true
    fi
    
    # Check for working directory (standard /var/www/$username)
    local work_dir="/var/www/$username"
    local has_work_dir=false
    if [[ -d "$work_dir" ]]; then
        log_info "Found working directory: $work_dir"
        has_work_dir=true
    fi
    
    # 5. Show Summary & Confirm
    log_heading "Revocation and Cleanup Plan"
    echo "The following actions will be performed:"
    echo "  1. Terminate all active processes and cron jobs for user '$username'"
    
    if [[ "$has_sudoers" == "true" ]]; then
        echo "  2. Revoke sudo access (remove $sudoers_file)"
    fi
    if [[ -f "$ssh_override_file" ]]; then
        echo "  3. Revoke custom SSH daemon configuration (remove $ssh_override_file)"
    fi
    if [[ -n "$chroot_dir" && -d "$chroot_dir" ]]; then
        echo "  4. Delete Chroot Jail directory ($chroot_dir)"
    fi
    if [[ "$has_limits" == "true" ]]; then
        echo "  5. Remove custom resource limits (remove $limits_file)"
    fi
    echo "  6. Remove root shell helper alias 'to-$username' from bash profiles"
    if [[ "$has_work_dir" == "true" ]]; then
        echo "  7. Delete application working directory ($work_dir)"
    fi
    echo "  8. Delete user '$username' (home directory: $home_dir)"
    echo "  9. Delete primary group '$primary_group' if it becomes empty"
    echo
    
    if ! prompt_yes_no "Do you want to proceed with this user deletion plan?" "n"; then
        log_warning "Deletion cancelled. No changes were made."
        exit 0
    fi

    # 6. Execute Deletion and Revocation tasks
    log_heading "Executing Cleanup and Deletion"

    # Step 1: Kill user processes and crontabs
    kill_user_processes "$username"

    # Step 2: Revoke sudo rules
    if [[ "$has_sudoers" == "true" ]]; then
        log_info "Revoking sudo access..."
        if rm -f "$sudoers_file"; then
            log_success "Sudo access revoked."
        else
            log_error "Failed to remove sudoers file at '$sudoers_file'."
        fi
    fi

    # Step 3: SSH Daemon Config override cleanup
    local ssh_reload_required=false
    if [[ -f "$ssh_override_file" ]]; then
        log_info "Removing SSH override configuration..."
        if rm -f "$ssh_override_file"; then
            log_success "SSH override configuration removed."
            ssh_reload_required=true
        else
            log_error "Failed to remove SSH override configuration at '$ssh_override_file'."
        fi
    fi

    # Step 4: Chroot jail directory cleanup
    if [[ -n "$chroot_dir" && -d "$chroot_dir" ]]; then
        # Safety checks to prevent deleting system roots
        if [[ "$chroot_dir" == "/" || "$chroot_dir" == "/home" || "$chroot_dir" == "/var" || "$chroot_dir" == "/etc" || "$chroot_dir" == "/usr" ]]; then
            log_warning "Skipping deletion of chroot directory '$chroot_dir' as it is a critical system path."
        else
            if prompt_yes_no "Delete Chroot Jail directory '$chroot_dir'?" "n"; then
                log_info "Deleting Chroot Jail directory '$chroot_dir'..."
                if rm -rf "$chroot_dir"; then
                    log_success "Chroot Jail directory deleted."
                else
                    log_error "Failed to delete Chroot Jail directory '$chroot_dir'."
                fi
            fi
        fi
    fi

    # Step 5: Resource limits cleanup
    if [[ "$has_limits" == "true" ]]; then
        log_info "Removing custom resource limits..."
        if rm -f "$limits_file"; then
            log_success "Resource limits removed."
        else
            log_error "Failed to remove resource limits file at '$limits_file'."
        fi
    fi

    # Step 6: Root bash helper alias cleanup
    log_info "Removing root shell helper alias 'to-$username'..."
    local alias_removed=false
    if [[ -f "/root/.bash_aliases" ]]; then
        if sed -i "/alias to-$username=/d" /root/.bash_aliases; then
            alias_removed=true
        fi
    fi
    if [[ -f "/root/.bashrc" ]]; then
        if sed -i "/alias to-$username=/d" /root/.bashrc; then
            alias_removed=true
        fi
    fi
    if [[ "$alias_removed" == "true" ]]; then
        log_success "Helper alias removed from profile configs."
    else
        log_info "No helper alias found/removed."
    fi

    # Step 7: Working directory cleanup
    if [[ "$has_work_dir" == "true" ]]; then
        if prompt_yes_no "Delete application working directory '$work_dir'?" "n"; then
            log_info "Deleting working directory '$work_dir'..."
            if rm -rf "$work_dir"; then
                log_success "Working directory deleted."
            else
                log_error "Failed to delete working directory '$work_dir'."
            fi
        fi
    fi
    
    # Prompt for other custom directories if interactive
    if [[ "$FORCE_YES" != "true" ]]; then
        if prompt_yes_no "Do you want to delete any other custom application/working directory for this user?" "n"; then
            local custom_dir=""
            read -r -p "Enter absolute path to the directory: " custom_dir
            if [[ -n "$custom_dir" ]]; then
                if [[ ! "$custom_dir" =~ ^/ ]]; then
                    log_error "Path must be absolute, starting with /."
                elif [[ "$custom_dir" == "/" || "$custom_dir" == "/home" || "$custom_dir" == "/var" || "$custom_dir" == "/etc" || "$custom_dir" == "/usr" ]]; then
                    log_error "Cannot delete critical system directory: '$custom_dir'"
                elif [[ -d "$custom_dir" ]]; then
                    if prompt_yes_no "Are you absolutely sure you want to delete '$custom_dir'?" "n"; then
                        log_info "Deleting '$custom_dir'..."
                        if rm -rf "$custom_dir"; then
                            log_success "Directory deleted."
                        else
                            log_error "Failed to delete directory '$custom_dir'."
                        fi
                    fi
                else
                    log_warning "Directory '$custom_dir' does not exist."
                fi
            fi
        fi
    fi

    # Step 8: User deletion (home directory prompt)
    local delete_home=false
    # If the user home is a system default or non-standard directory, check if it's set to /nonexistent or /
    if [[ "$home_dir" == "/nonexistent" || "$home_dir" == "/" ]]; then
        log_info "User has no custom home directory (set to '$home_dir'). Home directory deletion skipped."
    else
        if prompt_yes_no "Delete home directory '$home_dir' and mail spool?" "n"; then
            delete_home=true
        fi
    fi
    
    log_info "Deleting user '$username'..."
    if [[ "$delete_home" == "true" ]]; then
        log_info "Running: userdel -r $username"
        if userdel -r "$username"; then
            log_success "User '$username' and home directory deleted."
        else
            log_error "Failed to delete user '$username'."
            exit 1
        fi
    else
        log_info "Running: userdel $username"
        if userdel "$username"; then
            log_success "User '$username' deleted (home directory preserved)."
        else
            log_error "Failed to delete user '$username'."
            exit 1
        fi
    fi

    # Step 9: Primary group cleanup
    if getent group "$primary_group" >/dev/null 2>&1; then
        # Check if group is empty (no members in members list and no passwd entry uses it as primary GID)
        local group_members
        group_members=$(getent group "$primary_group" | cut -d: -f4)
        local primary_users
        primary_users=$(getent passwd | cut -d: -f4 | grep -x "$primary_gid" | wc -l)
        
        if [[ -z "$group_members" && "$primary_users" -eq 0 ]]; then
            if prompt_yes_no "Primary group '$primary_group' is now empty. Delete group?" "n"; then
                log_info "Deleting group '$primary_group'..."
                if groupdel "$primary_group"; then
                    log_success "Group '$primary_group' deleted."
                else
                    log_error "Failed to delete group '$primary_group'."
                fi
            fi
        else
            log_info "Primary group '$primary_group' is still in use by other users or has members: '$group_members'. Skipping group deletion."
        fi
    fi

    # 7. Apply configurations (Reload SSH daemon if needed)
    if [[ "$ssh_reload_required" == "true" ]]; then
        log_heading "Applying SSH Configurations"
        if systemctl is-active --quiet sshd 2>/dev/null; then
            log_info "Reloading SSH daemon..."
            if systemctl reload sshd; then
                log_success "SSH daemon reloaded successfully."
            else
                log_warning "Failed to reload sshd via systemctl. Please reload it manually."
            fi
        elif systemctl is-active --quiet ssh 2>/dev/null; then
            log_info "Reloading SSH service..."
            if systemctl reload ssh; then
                log_success "SSH service reloaded successfully."
            else
                log_warning "Failed to reload ssh via systemctl. Please reload it manually."
            fi
        else
            log_warning "SSH service does not appear to be running or systemd service not found."
            log_warning "Please reload your SSH daemon manually if it is active."
        fi
    fi

    log_heading "Cleanup Complete!"
    log_success "All requested cleanup tasks for '$username' completed successfully."
}

# Run the script
main "$@"
