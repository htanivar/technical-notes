#!/bin/bash
# bash_helpers.sh - Main helper library for bash scripts
# This is the primary entry point for all bash script utilities
#
# Usage:
#   source "$(dirname "$0")/helpers/bash_helpers.sh"
#   
#   # Or if helpers directory is in a different location:
#   source "/path/to/helpers/bash_helpers.sh"
#
# Available Functions:
#   - All core utility functions (logging, error handling, validation)
#   - Package management functions
#   - Service management functions
#   - Web domain and SSL certificate management
#   - System and user management functions

# =============================================================================
# HELPER LIBRARY INFORMATION
# =============================================================================

BASH_HELPERS_VERSION="1.0.0"
BASH_HELPERS_DIR="$(dirname "${BASH_SOURCE[0]}")"

# =============================================================================
# LOAD ALL HELPER MODULES
# =============================================================================

# Core utilities (must be loaded first)
if [ -f "$BASH_HELPERS_DIR/core_utils.sh" ]; then
    source "$BASH_HELPERS_DIR/core_utils.sh"
else
    echo "ERROR: core_utils.sh not found in $BASH_HELPERS_DIR" >&2
    exit 1
fi

# Package management
if [ -f "$BASH_HELPERS_DIR/package_manager.sh" ]; then
    source "$BASH_HELPERS_DIR/package_manager.sh"
else
    log_warn "package_manager.sh not found - package management functions unavailable"
fi

# Service management
if [ -f "$BASH_HELPERS_DIR/service_manager.sh" ]; then
    source "$BASH_HELPERS_DIR/service_manager.sh"
else
    log_warn "service_manager.sh not found - service management functions unavailable"
fi

# Web domain management
if [ -f "$BASH_HELPERS_DIR/web_domain.sh" ]; then
    source "$BASH_HELPERS_DIR/web_domain.sh"
else
    log_warn "web_domain.sh not found - web domain functions unavailable"
fi

# System management
if [ -f "$BASH_HELPERS_DIR/system_manager.sh" ]; then
    source "$BASH_HELPERS_DIR/system_manager.sh"
else
    log_warn "system_manager.sh not found - system management functions unavailable"
fi

# =============================================================================
# HELPER LIBRARY FUNCTIONS
# =============================================================================

# Show available functions organized by category
show_available_functions() {
    cat <<EOF
Bash Helper Library v$BASH_HELPERS_VERSION

=== CORE UTILITIES ===
Logging:
  - log, log_info, log_warn, log_error, log_debug, log_step
  - log_command, init_logging

Error Handling:
  - error_exit, warn, set_strict_mode, setup_cleanup_trap

Validation:
  - require_root, require_non_root, require_var, require_command
  - require_file, require_directory, check_file_permissions

Input:
  - prompt_input, confirm_action

System Info:
  - get_current_user, get_distribution, check_distribution

Utilities:
  - create_directory, backup_file, generate_random_string, check_port

=== PACKAGE MANAGEMENT ===
  - detect_package_manager, update_package_repo
  - install_packages, install_if_missing, remove_packages
  - install_nodejs, install_npm_global
  - install_docker_packages, install_postgresql, install_redis
  - install_build_tools

=== SERVICE MANAGEMENT ===
  - detect_service_manager
  - start_service, stop_service, restart_service, reload_service
  - enable_service, disable_service, check_service_status, wait_for_service
  - create_systemd_service, reload_systemd
  - enable_apache_site, disable_apache_site, enable_apache_module
  - test_nginx_config, reload_nginx, start_docker_services

=== WEB DOMAIN MANAGEMENT ===
Domain Setup:
  - setup_apache_domain, setup_nginx_domain, remove_domain
  - setup_subdomain

Hosts Management:
  - update_hosts_file, remove_from_hosts_file

SSL Certificates:
  - create_self_signed_cert, create_cert_request, sign_certificate
  - setup_apache_ssl, setup_nginx_ssl, create_ca

=== SYSTEM MANAGEMENT ===
User Management:
  - create_user, create_admin_user, delete_user
  - add_user_to_group, remove_user_from_group
  - setup_ssh_key, generate_ssh_key

System Configuration:
  - set_hostname, set_fqdn, add_swap_memory, remove_swap_memory
  - update_system, clean_system

Security:
  - configure_firewall, setup_fail2ban

Environment:
  - add_to_path, create_path_link, setup_dev_environment

EOF
}

# Quick setup function for common development environment
quick_dev_setup() {
    local install_packages="${1:-true}"
    
    log_step "SETUP" "Quick development environment setup"
    
    if [ "$install_packages" = "true" ] && [ "$EUID" -eq 0 ]; then
        # Update system
        update_system
        
        # Install essential development tools
        install_build_tools
        install_if_missing curl
        install_if_missing wget
        install_if_missing git
        install_if_missing vim
        
        # Install Node.js
        install_nodejs "20.x"
        install_npm_global "@medusajs/cli" "ts-node"
        
        log_info "Development packages installed"
    fi
    
    # Setup user environment
    local current_user
    current_user=$(get_current_user)
    setup_dev_environment "$current_user"
    
    log_info "Quick development setup completed"
}

# Full system setup for web server
full_web_server_setup() {
    local domain="$1"
    local web_server="${2:-apache}"  # apache or nginx
    local ssl="${3:-false}"
    
    require_root
    
    if [ -z "$domain" ]; then
        error_exit "Domain name is required for web server setup"
    fi
    
    log_step "WEB_SETUP" "Full web server setup for domain: $domain"
    
    # Update system
    update_system
    
    # Install web server
    case "$web_server" in
        apache)
            install_packages apache2
            enable_service apache2
            start_service apache2
            setup_apache_domain "$domain"
            ;;
        nginx)
            install_packages nginx
            enable_service nginx
            start_service nginx
            setup_nginx_domain "$domain"
            ;;
        *)
            error_exit "Unsupported web server: $web_server"
            ;;
    esac
    
    # Setup SSL if requested
    if [ "$ssl" = "true" ]; then
        log_info "Setting up SSL certificate..."
        create_self_signed_cert "$domain"
        
        case "$web_server" in
            apache)
                setup_apache_ssl "$domain" "/etc/ssl/certs/${domain}.crt" "/etc/ssl/private/${domain}.key"
                ;;
            nginx)
                setup_nginx_ssl "$domain" "/etc/ssl/certs/${domain}.crt" "/etc/ssl/private/${domain}.key"
                ;;
        esac
    fi
    
    # Basic security setup
    configure_firewall "enable" "22,80,443"
    
    log_info "Full web server setup completed for: $domain"
    log_info "You can now access your site at: http://$domain"
    if [ "$ssl" = "true" ]; then
        log_info "HTTPS is also available at: https://$domain"
    fi
}

# Initialize helper library
init_bash_helpers() {
    local debug_mode="${1:-false}"
    local log_level="${2:-INFO}"
    
    if [ "$debug_mode" = "true" ]; then
        export DEBUG=1
        set_strict_mode
    fi
    
    log_info "Bash Helper Library v$BASH_HELPERS_VERSION loaded"
    log_debug "Helper directory: $BASH_HELPERS_DIR"
    log_debug "Available modules: core_utils, package_manager, service_manager, web_domain, system_manager"
}

# =============================================================================
# COMMON SCRIPT TEMPLATES
# =============================================================================

# Generate a basic script template
generate_script_template() {
    local script_name="$1"
    local description="${2:-Basic bash script using helpers}"
    local requires_root="${3:-false}"
    
    if [ -z "$script_name" ]; then
        error_exit "Script name is required"
    fi
    
    local script_file="$script_name"
    if [[ ! "$script_name" == *.sh ]]; then
        script_file="${script_name}.sh"
    fi
    
    cat > "$script_file" <<EOF
#!/bin/bash
# $script_file - $description
# Generated by Bash Helper Library v$BASH_HELPERS_VERSION

# Load helper library
SCRIPT_DIR="\$(dirname "\${BASH_SOURCE[0]}")"
source "\$SCRIPT_DIR/helpers/bash_helpers.sh"

# Initialize helpers with debug mode
init_bash_helpers "\${DEBUG:-false}"

# Enable strict mode for better error handling
set_strict_mode

# Main function
main() {
    log_step "START" "Starting $script_file"
    
EOF

    if [ "$requires_root" = "true" ]; then
        echo "    require_root" >> "$script_file"
        echo "" >> "$script_file"
    fi

    cat >> "$script_file" <<EOF
    # Your script logic here
    log_info "Script execution completed successfully"
}

# Cleanup function
cleanup() {
    log_debug "Performing cleanup..."
    # Add any cleanup logic here
}

# Set up cleanup trap
setup_cleanup_trap cleanup

# Run main function
main "\$@"
EOF

    chmod +x "$script_file"
    
    log_info "Script template generated: $script_file"
}

# =============================================================================
# EXPORT COMMON FUNCTIONS
# =============================================================================

# Export main helper functions
export -f show_available_functions quick_dev_setup full_web_server_setup
export -f init_bash_helpers generate_script_template

# =============================================================================
# INITIALIZATION
# =============================================================================

# Auto-initialize with default settings
init_bash_helpers

log_debug "Bash Helper Library v$BASH_HELPERS_VERSION ready"
log_debug "Use 'show_available_functions' to see all available functions"