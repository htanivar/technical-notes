# Bash Helpers Library

A comprehensive collection of organized bash helper functions extracted from your existing scripts, designed to simplify and standardize bash script development.

## Overview

This library provides a structured approach to common bash scripting tasks, including:

- **Logging and Error Handling**: Consistent logging with timestamps and error management
- **Package Management**: Cross-platform package installation and management
- **Service Management**: Unified service control across different init systems
- **Web Domain Setup**: Apache/Nginx configuration with SSL support
- **System Management**: User management, system configuration, and security setup

## Quick Start

### Basic Usage

```bash
#!/bin/bash
# Load the helper library
source "$(dirname "$0")/helpers/bash_helpers.sh"

# Use any helper function
log_info "Starting my script"
require_root
install_packages git curl wget
```

### Generate Script Template

```bash
# Navigate to your project directory
cd /your/project

# Generate a new script template
source helpers/bash_helpers.sh
generate_script_template "my_new_script" "Description of script" "true"
```

## Library Structure

```
helpers/
├── bash_helpers.sh       # Main entry point - loads all modules
├── core_utils.sh         # Core utilities (logging, validation, etc.)
├── package_manager.sh    # Package installation and management
├── service_manager.sh    # Service control and management
├── web_domain.sh         # Web server and SSL certificate management
├── system_manager.sh     # System and user management
└── README.md            # This documentation
```

## Core Features

### 1. Logging System

```bash
# Initialize logging (optional - auto-initialized by default)
init_logging "my_script" "/var/log/custom"

# Different log levels
log_info "Information message"
log_warn "Warning message"
log_error "Error message"
log_debug "Debug message (only shown when DEBUG=1)"
log_step "STEP_NAME" "Step description"

# Command logging
log_command "apt update" "install.log"
```

### 2. Error Handling

```bash
# Enable strict error handling
set_strict_mode

# Exit with error message
error_exit "Something went wrong" 1

# Require specific conditions
require_root                    # Must run as root
require_non_root               # Must NOT run as root
require_command "docker"       # Command must be available
require_file "/path/to/file"   # File must exist
```

### 3. User Input

```bash
# Prompt for input with validation
prompt_input "Enter username" "USERNAME" "" "true" "false"
prompt_input "Enter password" "PASSWORD" "" "true" "true"  # Secret input

# Confirm actions
if confirm_action "Continue with installation?" "y"; then
    echo "User confirmed"
fi
```

### 4. Package Management

```bash
# Cross-platform package management
detect_package_manager          # Returns: apt, yum, dnf, pacman, etc.
update_package_repo            # Update package repositories
install_packages git curl wget # Install multiple packages
install_if_missing docker      # Install only if not present

# Specialized installations
install_nodejs "18.x"          # Install specific Node.js version
install_npm_global "@angular/cli" "typescript"
install_build_tools            # Install compiler and build tools
```

### 5. Service Management

```bash
# Universal service management
start_service "apache2"
stop_service "nginx" 
restart_service "docker"
enable_service "postgresql"    # Enable on boot
wait_for_service "mysql" 30    # Wait up to 30 seconds

# Web server specific
enable_apache_site "example.com"
reload_nginx
test_nginx_config
```

### 6. Web Domain Setup

```bash
# Quick domain setup
setup_apache_domain "example.com"
setup_nginx_domain "api.example.com"
setup_subdomain "blog" "example.com" "nginx"

# SSL certificate management
create_self_signed_cert "example.com"
setup_apache_ssl "example.com" "/path/to/cert.crt" "/path/to/private.key"
```

### 7. System Management

```bash
# User management
create_user "john" "password123" "/home/john" "/bin/bash" "sudo"
create_admin_user "admin" "securepass"
generate_ssh_key "john" "rsa" "4096"

# System configuration
set_hostname "webserver01"
set_fqdn "webserver01.example.com"
add_swap_memory "4G"
update_system true             # Update and upgrade

# Security
configure_firewall "enable" "22,80,443,8080"
setup_fail2ban "ssh,apache-auth"
```

## High-Level Functions

### Quick Development Setup

```bash
# Sets up a complete development environment
quick_dev_setup true           # Install packages and setup user env
quick_dev_setup false          # Setup user env only
```

### Full Web Server Setup

```bash
# Complete web server setup with domain and SSL
full_web_server_setup "mysite.com" "apache" "true"
full_web_server_setup "api.example.com" "nginx" "false"
```

## Examples

### Example 1: Simple Installation Script

```bash
#!/bin/bash
source "$(dirname "$0")/helpers/bash_helpers.sh"

main() {
    log_step "INSTALL" "Installing Docker"
    
    require_root
    update_package_repo
    install_packages docker.io docker-compose
    
    enable_service docker
    start_service docker
    
    # Add current user to docker group
    local current_user=$(get_current_user)
    add_user_to_group "$current_user" "docker"
    
    log_info "Docker installation completed"
}

main "$@"
```

### Example 2: Web Server Setup Script

```bash
#!/bin/bash
source "$(dirname "$0")/helpers/bash_helpers.sh"

main() {
    require_root
    
    local domain
    prompt_input "Enter domain name" "domain" "" "true"
    
    log_step "SETUP" "Setting up web server for $domain"
    
    # Install and configure Apache
    install_packages apache2
    setup_apache_domain "$domain"
    
    # Setup SSL
    create_self_signed_cert "$domain"
    setup_apache_ssl "$domain" "/etc/ssl/certs/${domain}.crt" "/etc/ssl/private/${domain}.key"
    
    # Configure firewall
    configure_firewall "enable" "22,80,443"
    
    log_info "Web server setup completed for $domain"
}

main "$@"
```

### Example 3: User Management Script

```bash
#!/bin/bash
source "$(dirname "$0")/helpers/bash_helpers.sh"

main() {
    require_root
    
    local username password
    prompt_input "Enter username" "username" "" "true"
    prompt_input "Enter password" "password" "" "true" "true"
    
    # Create admin user
    create_admin_user "$username" "$password"
    
    # Setup SSH key
    generate_ssh_key "$username"
    
    # Setup development environment
    setup_dev_environment "$username"
    
    log_info "User $username created and configured"
}

main "$@"
```

## Advanced Usage

### Custom Logging

```bash
# Initialize custom logging
init_logging "my_app" "/opt/my_app/logs"

# Set debug mode
export DEBUG=1

# Setup cleanup on exit
cleanup() {
    log_info "Cleaning up temporary files"
    rm -rf /tmp/my_app_*
}
setup_cleanup_trap cleanup
```

### Error Handling

```bash
# Enable strict mode
set_strict_mode

# Custom error handling
handle_error() {
    log_error "An error occurred on line $1"
    cleanup
    exit 1
}
trap 'handle_error $LINENO' ERR
```

### Conditional Operations

```bash
# Check system compatibility
check_distribution "ubuntu debian centos"

# Conditional package installation
if command -v docker &> /dev/null; then
    log_info "Docker already installed"
else
    install_docker_packages "/opt/docker-packages"
fi
```

## Best Practices

1. **Always source the main library**:
   ```bash
   source "$(dirname "$0")/helpers/bash_helpers.sh"
   ```

2. **Use strict mode for production scripts**:
   ```bash
   set_strict_mode
   ```

3. **Implement proper cleanup**:
   ```bash
   setup_cleanup_trap my_cleanup_function
   ```

4. **Use structured logging**:
   ```bash
   log_step "PHASE" "What you're doing"
   log_info "Success messages"
   log_warn "Non-fatal issues"
   log_error "Problems that need attention"
   ```

5. **Validate inputs and requirements**:
   ```bash
   require_root
   require_command "git"
   require_var "REQUIRED_ENV_VAR"
   ```

## Function Reference

Use `show_available_functions` to see all available functions organized by category.

## Migration from Existing Scripts

To migrate your existing scripts:

1. **Replace common patterns**:
   - `echo "message"` → `log_info "message"`
   - Manual root checks → `require_root`
   - Package installation loops → `install_packages pkg1 pkg2 pkg3`
   - Service management → Use service_manager functions

2. **Add error handling**:
   ```bash
   set_strict_mode
   setup_cleanup_trap cleanup_function
   ```

3. **Standardize logging**:
   ```bash
   log_step "PHASE" "Description"
   log_info "Success message"
   ```

## Troubleshooting

### Common Issues

1. **"Command not found" errors**: Ensure you've sourced the main library file
2. **Permission denied**: Some functions require root privileges
3. **Package manager not supported**: Check `detect_package_manager` output

### Debug Mode

Enable debug logging:
```bash
export DEBUG=1
./your_script.sh
```

### Log Files

Default log location: `/var/log/script_logs/` or `/tmp/` as fallback.

## Contributing

When adding new functions:

1. Add to the appropriate module file
2. Export the function at the end of the module
3. Update the main `bash_helpers.sh` file if needed
4. Update this README with examples

## Version History

- **v1.0.0**: Initial release with core functionality extracted from existing scripts