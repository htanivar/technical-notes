#!/bin/bash
# service_manager.sh - Service management helper functions
# Source: source "$(dirname "$0")/helpers/service_manager.sh"

# Source core utilities
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIR/core_utils.sh"

# =============================================================================
# SERVICE DETECTION
# =============================================================================

# Detect service manager (systemd, upstart, sysv)
detect_service_manager() {
    if command -v systemctl &> /dev/null && systemctl --version &> /dev/null; then
        echo "systemd"
    elif command -v service &> /dev/null && [ -d /etc/init.d ]; then
        echo "sysv"
    elif command -v initctl &> /dev/null; then
        echo "upstart"
    else
        echo "unknown"
    fi
}

# =============================================================================
# SERVICE OPERATIONS
# =============================================================================

# Start service
start_service() {
    local service_name="$1"
    local sm=$(detect_service_manager)
    
    log_step "SERVICE" "Starting service: $service_name using $sm"
    
    case "$sm" in
        systemd)
            systemctl start "$service_name" || error_exit "Failed to start service: $service_name"
            ;;
        sysv)
            service "$service_name" start || error_exit "Failed to start service: $service_name"
            ;;
        upstart)
            initctl start "$service_name" || error_exit "Failed to start service: $service_name"
            ;;
        *)
            error_exit "Unsupported service manager: $sm"
            ;;
    esac
    
    log_info "Service started successfully: $service_name"
}

# Stop service
stop_service() {
    local service_name="$1"
    local sm=$(detect_service_manager)
    
    log_step "SERVICE" "Stopping service: $service_name using $sm"
    
    case "$sm" in
        systemd)
            systemctl stop "$service_name" || warn "Failed to stop service: $service_name"
            ;;
        sysv)
            service "$service_name" stop || warn "Failed to stop service: $service_name"
            ;;
        upstart)
            initctl stop "$service_name" || warn "Failed to stop service: $service_name"
            ;;
        *)
            error_exit "Unsupported service manager: $sm"
            ;;
    esac
    
    log_info "Service stopped: $service_name"
}

# Restart service
restart_service() {
    local service_name="$1"
    local sm=$(detect_service_manager)
    
    log_step "SERVICE" "Restarting service: $service_name using $sm"
    
    case "$sm" in
        systemd)
            systemctl restart "$service_name" || error_exit "Failed to restart service: $service_name"
            ;;
        sysv)
            service "$service_name" restart || error_exit "Failed to restart service: $service_name"
            ;;
        upstart)
            initctl restart "$service_name" || error_exit "Failed to restart service: $service_name"
            ;;
        *)
            error_exit "Unsupported service manager: $sm"
            ;;
    esac
    
    log_info "Service restarted successfully: $service_name"
}

# Reload service configuration
reload_service() {
    local service_name="$1"
    local sm=$(detect_service_manager)
    
    log_step "SERVICE" "Reloading service configuration: $service_name using $sm"
    
    case "$sm" in
        systemd)
            systemctl reload "$service_name" || warn "Failed to reload service: $service_name"
            ;;
        sysv)
            service "$service_name" reload || warn "Failed to reload service: $service_name"
            ;;
        upstart)
            initctl reload "$service_name" || warn "Failed to reload service: $service_name"
            ;;
        *)
            error_exit "Unsupported service manager: $sm"
            ;;
    esac
    
    log_info "Service configuration reloaded: $service_name"
}

# Enable service (start on boot)
enable_service() {
    local service_name="$1"
    local sm=$(detect_service_manager)
    
    log_step "SERVICE" "Enabling service: $service_name using $sm"
    
    case "$sm" in
        systemd)
            systemctl enable "$service_name" || error_exit "Failed to enable service: $service_name"
            ;;
        sysv)
            if command -v update-rc.d &> /dev/null; then
                update-rc.d "$service_name" defaults || warn "Failed to enable service: $service_name"
            elif command -v chkconfig &> /dev/null; then
                chkconfig "$service_name" on || warn "Failed to enable service: $service_name"
            else
                warn "Cannot enable service - no suitable tool found"
            fi
            ;;
        upstart)
            # Upstart services are enabled by default
            log_debug "Upstart services are enabled by default: $service_name"
            ;;
        *)
            error_exit "Unsupported service manager: $sm"
            ;;
    esac
    
    log_info "Service enabled: $service_name"
}

# Disable service (don't start on boot)
disable_service() {
    local service_name="$1"
    local sm=$(detect_service_manager)
    
    log_step "SERVICE" "Disabling service: $service_name using $sm"
    
    case "$sm" in
        systemd)
            systemctl disable "$service_name" || warn "Failed to disable service: $service_name"
            ;;
        sysv)
            if command -v update-rc.d &> /dev/null; then
                update-rc.d "$service_name" disable || warn "Failed to disable service: $service_name"
            elif command -v chkconfig &> /dev/null; then
                chkconfig "$service_name" off || warn "Failed to disable service: $service_name"
            else
                warn "Cannot disable service - no suitable tool found"
            fi
            ;;
        upstart)
            warn "Upstart service disabling not implemented: $service_name"
            ;;
        *)
            error_exit "Unsupported service manager: $sm"
            ;;
    esac
    
    log_info "Service disabled: $service_name"
}

# Check service status
check_service_status() {
    local service_name="$1"
    local sm=$(detect_service_manager)
    
    case "$sm" in
        systemd)
            systemctl is-active "$service_name" &> /dev/null && echo "active" || echo "inactive"
            ;;
        sysv)
            service "$service_name" status &> /dev/null && echo "active" || echo "inactive"
            ;;
        upstart)
            initctl status "$service_name" 2>/dev/null | grep -q "start/running" && echo "active" || echo "inactive"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Wait for service to be active
wait_for_service() {
    local service_name="$1"
    local timeout="${2:-30}"
    local check_interval="${3:-2}"
    
    log_step "SERVICE" "Waiting for service to be active: $service_name (timeout: ${timeout}s)"
    
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        if [ "$(check_service_status "$service_name")" = "active" ]; then
            log_info "Service is now active: $service_name"
            return 0
        fi
        
        sleep $check_interval
        elapsed=$((elapsed + check_interval))
    done
    
    error_exit "Service did not become active within ${timeout}s: $service_name"
}

# =============================================================================
# SYSTEMD SPECIFIC FUNCTIONS
# =============================================================================

# Reload systemd daemon
reload_systemd() {
    if [ "$(detect_service_manager)" = "systemd" ]; then
        log_step "SYSTEMD" "Reloading systemd daemon"
        systemctl daemon-reload || warn "Failed to reload systemd daemon"
    fi
}

# Create systemd service file
create_systemd_service() {
    local service_name="$1"
    local description="$2"
    local exec_start="$3"
    local user="${4:-root}"
    local working_dir="${5:-/}"
    local restart="${6:-on-failure}"
    
    require_root
    
    local service_file="/etc/systemd/system/${service_name}.service"
    
    log_step "SYSTEMD" "Creating systemd service: $service_name"
    
    cat > "$service_file" <<EOF
[Unit]
Description=$description
After=network.target

[Service]
Type=simple
User=$user
WorkingDirectory=$working_dir
ExecStart=$exec_start
Restart=$restart
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    chmod 644 "$service_file" || warn "Failed to set permissions on service file"
    
    # Reload systemd to recognize the new service
    reload_systemd
    
    log_info "Systemd service created: $service_name"
}

# =============================================================================
# APACHE/NGINX SPECIFIC FUNCTIONS
# =============================================================================

# Enable Apache site
enable_apache_site() {
    local site_name="$1"
    
    require_command "a2ensite"
    
    log_step "APACHE" "Enabling Apache site: $site_name"
    a2ensite "$site_name" || error_exit "Failed to enable Apache site: $site_name"
    
    # Test configuration
    apache2ctl configtest || warn "Apache configuration test failed"
    
    # Reload Apache
    reload_service apache2
    
    log_info "Apache site enabled: $site_name"
}

# Disable Apache site
disable_apache_site() {
    local site_name="$1"
    
    require_command "a2dissite"
    
    log_step "APACHE" "Disabling Apache site: $site_name"
    a2dissite "$site_name" || warn "Failed to disable Apache site: $site_name"
    
    # Reload Apache
    reload_service apache2
    
    log_info "Apache site disabled: $site_name"
}

# Enable Apache module
enable_apache_module() {
    local module_name="$1"
    
    require_command "a2enmod"
    
    log_step "APACHE" "Enabling Apache module: $module_name"
    a2enmod "$module_name" || error_exit "Failed to enable Apache module: $module_name"
    
    # Restart Apache to load the module
    restart_service apache2
    
    log_info "Apache module enabled: $module_name"
}

# Test Nginx configuration
test_nginx_config() {
    require_command "nginx"
    
    log_step "NGINX" "Testing Nginx configuration"
    nginx -t || error_exit "Nginx configuration test failed"
    
    log_info "Nginx configuration is valid"
}

# Reload Nginx configuration
reload_nginx() {
    test_nginx_config
    reload_service nginx
}

# =============================================================================
# DOCKER SERVICE FUNCTIONS
# =============================================================================

# Start Docker services
start_docker_services() {
    log_step "DOCKER" "Starting Docker services"
    
    # Reload systemd daemon
    reload_systemd
    
    # Enable and start services
    enable_service containerd.service
    enable_service docker.service
    
    start_service containerd.service
    start_service docker.service
    
    # Wait for Docker to be ready
    wait_for_service docker 30
    
    # Verify Docker installation
    if command -v docker &> /dev/null; then
        docker --version || warn "Docker version check failed"
        docker info &> /dev/null || warn "Docker info check failed"
    fi
    
    log_info "Docker services started and verified"
}

# =============================================================================
# CLOUDFLARE TUNNEL FUNCTIONS
# =============================================================================

# Install and start Cloudflare tunnel service
setup_cloudflared_service() {
    local tunnel_name="$1"
    local config_file="$2"
    
    require_command "cloudflared"
    require_file "$config_file"
    
    log_step "CLOUDFLARE" "Setting up cloudflared service for tunnel: $tunnel_name"
    
    # Install the service
    cloudflared service install || error_exit "Failed to install cloudflared service"
    
    # Start the service
    start_service cloudflared
    enable_service cloudflared
    
    log_info "Cloudflared service setup completed for tunnel: $tunnel_name"
}

# Export functions
export -f detect_service_manager start_service stop_service restart_service reload_service
export -f enable_service disable_service check_service_status wait_for_service
export -f reload_systemd create_systemd_service
export -f enable_apache_site disable_apache_site enable_apache_module
export -f test_nginx_config reload_nginx start_docker_services setup_cloudflared_service