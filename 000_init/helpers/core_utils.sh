#!/bin/bash
# core_utils.sh - Core utility functions for bash scripts
# Source this file at the beginning of your scripts: source "$(dirname "$0")/helpers/core_utils.sh"

# Global variables for logging
DEFAULT_LOG_DIR="/var/log/script_logs"
DEFAULT_LOG_FILE=""

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

# Initialize logging with optional custom log file
init_logging() {
    local script_name="${1:-$(basename "$0")}"
    local log_dir="${2:-$DEFAULT_LOG_DIR}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    DEFAULT_LOG_FILE="${log_dir}/${script_name%.sh}_${timestamp}.log"
    
    # Create log directory if it doesn't exist
    mkdir -p "$log_dir" 2>/dev/null || {
        # Fallback to /tmp if we can't create in the preferred location
        DEFAULT_LOG_FILE="/tmp/${script_name%.sh}_${timestamp}.log"
    }
    
    # Create log file and set permissions
    : > "$DEFAULT_LOG_FILE" || error_exit "Unable to create log file at $DEFAULT_LOG_FILE"
    
    log "Logging initialized - Log file: $DEFAULT_LOG_FILE"
}

# Log function with timestamp
log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] [$level] $message"
    
    # Output to both console and log file
    echo "$log_entry" >&2
    if [ -n "$DEFAULT_LOG_FILE" ]; then
        echo "$log_entry" >> "$DEFAULT_LOG_FILE"
    fi
}

# Specialized logging functions
log_info() {
    log "$1" "INFO"
}

log_warn() {
    log "$1" "WARN"
}

log_error() {
    log "$1" "ERROR"
}

log_debug() {
    if [ "${DEBUG:-0}" = "1" ]; then
        log "$1" "DEBUG"
    fi
}

log_step() {
    local step="$1"
    local message="$2"
    log "[$step] $message" "STEP"
}

# Log command execution
log_command() {
    local command="$1"
    local log_file="${2:-command_log.txt}"
    echo "$command" >> "$log_file"
    log "Command logged to $log_file: $command" "CMD"
}

# =============================================================================
# ERROR HANDLING
# =============================================================================

# Error exit function with logging
error_exit() {
    local message="${1:-Unknown error}"
    local exit_code="${2:-1}"
    log_error "$message"
    log_error "Script exiting with code $exit_code"
    exit "$exit_code"
}

# Warning function
warn() {
    local message="$1"
    log_warn "$message"
}

# Set strict error handling
set_strict_mode() {
    set -euo pipefail
    log_debug "Strict mode enabled (set -euo pipefail)"
}

# Trap function for cleanup on script exit
setup_cleanup_trap() {
    local cleanup_function="$1"
    trap "$cleanup_function" EXIT INT TERM
    log_debug "Cleanup trap set: $cleanup_function"
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

# Check if script is run as root
require_root() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "This script must be run as root. Use 'sudo $0' or run as root user."
    fi
    log_debug "Root privileges confirmed"
}

# Check if script is NOT run as root
require_non_root() {
    if [ "$EUID" -eq 0 ]; then
        error_exit "This script should not be run as root. Run as a regular user."
    fi
    log_debug "Non-root execution confirmed"
}

# Validate required variables
require_var() {
    local var_name="$1"
    local var_value="${!var_name:-}"
    if [ -z "$var_value" ]; then
        error_exit "Required variable '$var_name' is not set or empty"
    fi
    log_debug "Variable validation passed: $var_name"
}

# Check if command exists
require_command() {
    local command="$1"
    if ! command -v "$command" &> /dev/null; then
        error_exit "Required command '$command' is not available"
    fi
    log_debug "Command availability confirmed: $command"
}

# Check if file exists
require_file() {
    local file_path="$1"
    if [ ! -f "$file_path" ]; then
        error_exit "Required file does not exist: $file_path"
    fi
    log_debug "File existence confirmed: $file_path"
}

# Check if directory exists
require_directory() {
    local dir_path="$1"
    if [ ! -d "$dir_path" ]; then
        error_exit "Required directory does not exist: $dir_path"
    fi
    log_debug "Directory existence confirmed: $dir_path"
}

# Validate file permissions
check_file_permissions() {
    local file_path="$1"
    local required_perms="${2:-r}"  # r, w, x
    
    case "$required_perms" in
        *r*) [ -r "$file_path" ] || error_exit "File not readable: $file_path" ;;
        *w*) [ -w "$file_path" ] || error_exit "File not writable: $file_path" ;;
        *x*) [ -x "$file_path" ] || error_exit "File not executable: $file_path" ;;
    esac
    log_debug "File permissions validated: $file_path ($required_perms)"
}

# =============================================================================
# INPUT FUNCTIONS
# =============================================================================

# Prompt for user input with validation
prompt_input() {
    local prompt_text="$1"
    local var_name="$2"
    local default_value="${3:-}"
    local is_required="${4:-true}"
    local is_secret="${5:-false}"
    
    local input_value=""
    
    while true; do
        if [ "$is_secret" = "true" ]; then
            read -s -p "$prompt_text: " input_value
            echo  # New line after secret input
        else
            if [ -n "$default_value" ]; then
                read -p "$prompt_text [$default_value]: " input_value
                input_value="${input_value:-$default_value}"
            else
                read -p "$prompt_text: " input_value
            fi
        fi
        
        if [ -z "$input_value" ] && [ "$is_required" = "true" ]; then
            warn "Input is required. Please try again."
            continue
        fi
        
        break
    done
    
    # Set the variable dynamically
    eval "$var_name='$input_value'"
    log_debug "User input captured for: $var_name"
}

# Confirm action with user
confirm_action() {
    local message="$1"
    local default="${2:-n}"
    local response
    
    if [ "$default" = "y" ]; then
        read -p "$message (Y/n): " response
        response=${response:-y}
    else
        read -p "$message (y/N): " response
        response=${response:-n}
    fi
    
    case "$response" in
        [Yy]|[Yy][Ee][Ss]) 
            log_debug "User confirmed: $message"
            return 0 
            ;;
        *) 
            log_debug "User declined: $message"
            return 1 
            ;;
    esac
}

# =============================================================================
# SYSTEM INFORMATION FUNCTIONS
# =============================================================================

# Get current user (works with sudo)
get_current_user() {
    local user
    user=$(logname 2>/dev/null || whoami)
    
    if [ "$user" = "root" ] || [ -z "$user" ]; then
        user="${SUDO_USER:-$(ps -o user= -p "$PPID" | awk '{print $1}')}"
    fi
    
    if [ "$user" = "root" ] || [ -z "$user" ]; then
        error_exit "Cannot determine the non-root user"
    fi
    
    echo "$user"
}

# Get distribution information
get_distribution() {
    if command -v lsb_release &> /dev/null; then
        lsb_release -si | tr '[:upper:]' '[:lower:]'
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# Check if distribution is supported
check_distribution() {
    local supported_distros="$1"  # Space-separated list
    local current_distro
    current_distro=$(get_distribution)
    
    if [[ " $supported_distros " =~ " $current_distro " ]]; then
        log_debug "Distribution supported: $current_distro"
        return 0
    else
        error_exit "Unsupported distribution: $current_distro. Supported: $supported_distros"
    fi
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Create directory with proper ownership
create_directory() {
    local dir_path="$1"
    local owner="${2:-$(get_current_user)}"
    local group="${3:-$owner}"
    local permissions="${4:-755}"
    
    mkdir -p "$dir_path" || error_exit "Failed to create directory: $dir_path"
    
    if [ "$EUID" -eq 0 ]; then
        chown "$owner:$group" "$dir_path" || warn "Failed to set ownership for: $dir_path"
        chmod "$permissions" "$dir_path" || warn "Failed to set permissions for: $dir_path"
    fi
    
    log_debug "Directory created: $dir_path (owner: $owner:$group, perms: $permissions)"
}

# Backup file with timestamp
backup_file() {
    local file_path="$1"
    local backup_dir="${2:-$(dirname "$file_path")}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$backup_dir/$(basename "$file_path").backup.$timestamp"
    
    if [ -f "$file_path" ]; then
        cp "$file_path" "$backup_path" || error_exit "Failed to backup file: $file_path"
        log_info "File backed up: $file_path -> $backup_path"
        echo "$backup_path"
    else
        warn "File not found for backup: $file_path"
        return 1
    fi
}

# Generate random string
generate_random_string() {
    local length="${1:-16}"
    local charset="${2:-A-Za-z0-9}"
    
    tr -dc "$charset" < /dev/urandom | head -c "$length"
}

# Check if port is available
check_port() {
    local port="$1"
    local host="${2:-127.0.0.1}"
    
    if command -v nc &> /dev/null; then
        nc -z "$host" "$port" 2>/dev/null && return 1 || return 0
    elif command -v ss &> /dev/null; then
        ss -tuln | grep -q ":$port " && return 1 || return 0
    else
        warn "Cannot check port availability - neither nc nor ss available"
        return 0
    fi
}

# =============================================================================
# INITIALIZATION
# =============================================================================

# Auto-initialize logging if not already done
if [ -z "$DEFAULT_LOG_FILE" ]; then
    init_logging
fi

# Note: Functions are automatically available when this script is sourced
# No explicit export needed in zsh/bash for sourced functions
