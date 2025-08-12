#!/bin/bash

# Cloudflare Tunnel Setup Verification and Fix Script
# This script checks and fixes all configuration, permissions, and dependencies
# Supports: systemd, SysV init, OpenRC, and major Linux distributions
# Run with: sudo ./verify_cloudflare_setup.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CLOUDFLARED_USER="cloudflared"
CLOUDFLARED_GROUP="cloudflared"
CONFIG_DIR="/etc/cloudflared"
LOG_FILE="/var/log/cloudflared_setup_verification.log"

# Distribution and init system detection
DISTRO=""
INIT_SYSTEM=""
PACKAGE_MANAGER=""
SERVICE_DIR=""
SERVICE_FILE=""
ENV_FILE=""

# Logging function
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_success() {
    log "${GREEN}✓ $1${NC}"
}

print_warning() {
    log "${YELLOW}⚠ $1${NC}"
}

print_error() {
    log "${RED}✗ $1${NC}"
}

print_info() {
    log "${BLUE}ℹ $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Initialize log file
init_log() {
    echo "Cloudflare Tunnel Setup Verification - $(date)" > "$LOG_FILE"
    echo "=========================================" >> "$LOG_FILE"
}

# Detect Linux distribution
detect_distribution() {
    print_header "Detecting Linux Distribution"
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO="$ID"
        print_info "Distribution: $PRETTY_NAME"
    elif [[ -f /etc/redhat-release ]]; then
        DISTRO="rhel"
        print_info "Distribution: $(cat /etc/redhat-release)"
    elif [[ -f /etc/debian_version ]]; then
        DISTRO="debian"
        print_info "Distribution: Debian $(cat /etc/debian_version)"
    else
        DISTRO="unknown"
        print_warning "Unknown distribution"
    fi
    
    # Set package manager based on distribution
    case "$DISTRO" in
        ubuntu|debian|raspbian)
            PACKAGE_MANAGER="apt"
            ;;
        centos|rhel|fedora|rocky|almalinux)
            PACKAGE_MANAGER="yum"
            if command -v dnf >/dev/null 2>&1; then
                PACKAGE_MANAGER="dnf"
            fi
            ;;
        opensuse*|sles)
            PACKAGE_MANAGER="zypper"
            ;;
        arch|manjaro)
            PACKAGE_MANAGER="pacman"
            ;;
        alpine)
            PACKAGE_MANAGER="apk"
            ;;
        *)
            PACKAGE_MANAGER="unknown"
            ;;
    esac
    
    print_info "Package manager: $PACKAGE_MANAGER"
}

# Detect init system
detect_init_system() {
    print_header "Detecting Init System"
    
    if [[ -d /run/systemd/system ]] && command -v systemctl >/dev/null 2>&1; then
        INIT_SYSTEM="systemd"
        SERVICE_DIR="/etc/systemd/system"
        SERVICE_FILE="$SERVICE_DIR/cloudflared.service"
        ENV_FILE="/etc/default/cloudflared"
        print_success "Init system: systemd"
    elif [[ -d /etc/init.d ]] && command -v service >/dev/null 2>&1; then
        INIT_SYSTEM="sysv"
        SERVICE_DIR="/etc/init.d"
        SERVICE_FILE="$SERVICE_DIR/cloudflared"
        ENV_FILE="/etc/default/cloudflared"
        print_success "Init system: SysV init"
    elif [[ -d /etc/init.d ]] && command -v rc-service >/dev/null 2>&1; then
        INIT_SYSTEM="openrc"
        SERVICE_DIR="/etc/init.d"
        SERVICE_FILE="$SERVICE_DIR/cloudflared"
        ENV_FILE="/etc/conf.d/cloudflared"
        print_success "Init system: OpenRC"
    else
        INIT_SYSTEM="unknown"
        print_warning "Unknown or unsupported init system"
        print_info "Falling back to manual service management"
    fi
}

# Install required packages
install_dependencies() {
    print_header "Checking Dependencies"
    
    local deps=("curl" "jq")
    local missing_deps=()
    
    # Check which dependencies are missing
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -eq 0 ]]; then
        print_success "All dependencies are installed"
        return 0
    fi
    
    print_warning "Missing dependencies: ${missing_deps[*]}"
    print_info "Installing missing dependencies..."
    
    case "$PACKAGE_MANAGER" in
        apt)
            apt-get update -qq
            apt-get install -y "${missing_deps[@]}"
            ;;
        yum|dnf)
            $PACKAGE_MANAGER install -y "${missing_deps[@]}"
            ;;
        zypper)
            zypper install -y "${missing_deps[@]}"
            ;;
        pacman)
            pacman -S --noconfirm "${missing_deps[@]}"
            ;;
        apk)
            apk add "${missing_deps[@]}"
            ;;
        *)
            print_error "Cannot install dependencies automatically"
            print_info "Please install manually: ${missing_deps[*]}"
            return 1
            ;;
    esac
    
    print_success "Dependencies installed"
}

# Check if cloudflared binary exists and is executable
check_binary() {
    print_header "Checking Cloudflared Binary"
    
    local binary_paths=("/usr/bin/cloudflared" "/usr/local/bin/cloudflared" "/opt/cloudflared/bin/cloudflared")
    local found_binary=""
    
    for path in "${binary_paths[@]}"; do
        if [[ -x "$path" ]]; then
            found_binary="$path"
            break
        fi
    done
    
    if [[ -n "$found_binary" ]]; then
        print_success "Binary found at: $found_binary"
        CLOUDFLARED_BINARY="$found_binary"
        
        # Check version
        local version=$($found_binary --version 2>/dev/null || echo "unknown")
        print_info "Version: $version"
        
        # Check if binary is in PATH
        if command -v cloudflared >/dev/null 2>&1; then
            print_success "Binary is in PATH"
        else
            print_warning "Binary not in PATH, creating symlink"
            ln -sf "$found_binary" /usr/local/bin/cloudflared
        fi
    else
        print_error "Cloudflared binary not found in common locations"
        print_info "Please install cloudflared first using install_cloudflare.sh"
        return 1
    fi
}

# Check and create user/group
check_user_group() {
    print_header "Checking User and Group"
    
    # Check if group exists
    if getent group "$CLOUDFLARED_GROUP" >/dev/null 2>&1; then
        print_success "Group '$CLOUDFLARED_GROUP' exists"
    else
        print_warning "Creating group '$CLOUDFLARED_GROUP'"
        if command -v groupadd >/dev/null 2>&1; then
            groupadd --system "$CLOUDFLARED_GROUP" 2>/dev/null || groupadd "$CLOUDFLARED_GROUP"
        else
            # Fallback for systems without groupadd
            echo "$CLOUDFLARED_GROUP:x:$(awk -F: '{print $3}' /etc/group | sort -n | tail -1 | awk '{print $1+1}'):" >> /etc/group
        fi
    fi
    
    # Check if user exists
    if id "$CLOUDFLARED_USER" >/dev/null 2>&1; then
        print_success "User '$CLOUDFLARED_USER' exists"
        
        # Check if user is in correct group
        if groups "$CLOUDFLARED_USER" | grep -q "$CLOUDFLARED_GROUP"; then
            print_success "User is in correct group"
        else
            print_warning "Adding user to group '$CLOUDFLARED_GROUP'"
            usermod -a -G "$CLOUDFLARED_GROUP" "$CLOUDFLARED_USER" 2>/dev/null || {
                # Fallback for systems without usermod
                sed -i "s/^$CLOUDFLARED_GROUP:x:\([0-9]*\):.*/&$CLOUDFLARED_USER/" /etc/group
            }
        fi
    else
        print_warning "Creating user '$CLOUDFLARED_USER'"
        if command -v useradd >/dev/null 2>&1; then
            useradd --system --gid "$CLOUDFLARED_GROUP" --create-home \
                    --home-dir /var/lib/cloudflared --shell /usr/sbin/nologin \
                    --comment "Cloudflare Tunnel" "$CLOUDFLARED_USER" 2>/dev/null || \
            useradd --system -g "$CLOUDFLARED_GROUP" -d /var/lib/cloudflared \
                    -s /usr/sbin/nologin "$CLOUDFLARED_USER"
        else
            # Manual user creation fallback
            local uid=$(awk -F: '{print $3}' /etc/passwd | sort -n | tail -1 | awk '{print $1+1}')
            local gid=$(getent group "$CLOUDFLARED_GROUP" | cut -d: -f3)
            echo "$CLOUDFLARED_USER:x:$uid:$gid:Cloudflare Tunnel:/var/lib/cloudflared:/usr/sbin/nologin" >> /etc/passwd
            mkdir -p /var/lib/cloudflared
            chown "$uid:$gid" /var/lib/cloudflared
        fi
    fi
}

# Check and create configuration directory
check_config_directory() {
    print_header "Checking Configuration Directory"
    
    if [[ -d "$CONFIG_DIR" ]]; then
        print_success "Configuration directory exists: $CONFIG_DIR"
    else
        print_warning "Creating configuration directory: $CONFIG_DIR"
        mkdir -p "$CONFIG_DIR"
    fi
    
    # Set correct ownership and permissions
    chown "$CLOUDFLARED_USER:$CLOUDFLARED_GROUP" "$CONFIG_DIR"
    chmod 750 "$CONFIG_DIR"
    print_success "Set directory permissions: 750 $CLOUDFLARED_USER:$CLOUDFLARED_GROUP"
}

# Check configuration file
check_config_file() {
    print_header "Checking Configuration File"
    
    local config_file="$CONFIG_DIR/config.yml"
    
    if [[ -f "$config_file" ]]; then
        print_success "Configuration file exists: $config_file"
        
        # Check if it has required fields
        if grep -q "^tunnel:" "$config_file" && grep -q "^credentials-file:" "$config_file"; then
            print_success "Configuration file has required fields"
        else
            print_warning "Configuration file missing required fields"
            print_info "Required fields: tunnel, credentials-file, ingress"
        fi
        
        # Set correct permissions
        chown "$CLOUDFLARED_USER:$CLOUDFLARED_GROUP" "$config_file"
        chmod 640 "$config_file"
        print_success "Set config file permissions: 640"
    else
        print_warning "Configuration file not found: $config_file"
        print_info "Creating template configuration file"
        
        cat > "$config_file" << 'EOF'
# Cloudflare Tunnel Configuration
# Replace <YOUR-TUNNEL-NAME-OR-ID> and <TUNNEL-ID> with actual values
tunnel: <YOUR-TUNNEL-NAME-OR-ID>
credentials-file: /etc/cloudflared/<TUNNEL-ID>.json

ingress:
  # Example: Route subdomain to local service
  # - hostname: app.yourdomain.com
  #   service: http://127.0.0.1:8080
  
  # Catch-all rule (required)
  - service: http_status:404
EOF
        
        chown "$CLOUDFLARED_USER:$CLOUDFLARED_GROUP" "$config_file"
        chmod 640 "$config_file"
        print_warning "Template created. Please edit $config_file with your tunnel details"
    fi
}

# Check credentials files
check_credentials() {
    print_header "Checking Credentials Files"
    
    local cred_files=($(find "$CONFIG_DIR" -name "*.json" 2>/dev/null || true))
    
    if [[ ${#cred_files[@]} -eq 0 ]]; then
        print_warning "No credentials files found in $CONFIG_DIR"
        print_info "You need to create a tunnel and place the credentials file here"
    else
        for cred_file in "${cred_files[@]}"; do
            print_success "Found credentials file: $(basename "$cred_file")"
            
            # Set correct permissions
            chown "$CLOUDFLARED_USER:$CLOUDFLARED_GROUP" "$cred_file"
            chmod 600 "$cred_file"
            print_success "Set credentials permissions: 600"
            
            # Validate JSON if jq is available
            if command -v jq >/dev/null 2>&1; then
                if jq empty "$cred_file" 2>/dev/null; then
                    print_success "Credentials file is valid JSON"
                else
                    print_error "Credentials file is not valid JSON: $cred_file"
                fi
            fi
        done
    fi
}

# Create systemd service
create_systemd_service() {
    print_info "Creating systemd service file"
    
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Cloudflare Tunnel
After=network-online.target
Wants=network-online.target

[Service]
User=$CLOUDFLARED_USER
Group=$CLOUDFLARED_GROUP
EnvironmentFile=-$ENV_FILE
ExecStart=$CLOUDFLARED_BINARY --no-autoupdate tunnel run
Restart=on-failure
RestartSec=5s
TimeoutStopSec=5s

[Install]
WantedBy=multi-user.target
EOF
    
    print_success "Created systemd service file"
    
    # Reload systemd and enable service
    if systemctl daemon-reload 2>/dev/null; then
        print_success "Reloaded systemd daemon"
    else
        print_warning "Could not reload systemd daemon"
    fi
    
    if systemctl enable cloudflared 2>/dev/null; then
        print_success "Service enabled"
    else
        print_warning "Could not enable service"
    fi
}

# Create SysV init script
create_sysv_service() {
    print_info "Creating SysV init script"
    
    cat > "$SERVICE_FILE" << EOF
#!/bin/bash
# cloudflared        Cloudflare Tunnel daemon
# chkconfig: 35 80 20
# description: Cloudflare Tunnel daemon
#

. /etc/rc.d/init.d/functions 2>/dev/null || {
    # Fallback functions for systems without /etc/rc.d/init.d/functions
    success() { echo -n "[ OK ]"; }
    failure() { echo -n "[FAILED]"; }
    warning() { echo -n "[WARNING]"; }
}

USER="$CLOUDFLARED_USER"
DAEMON="cloudflared"
ROOT_DIR="/var/lib/cloudflared"

SERVER="\$ROOT_DIR/\$DAEMON"
LOCK_FILE="/var/lock/subsys/cloudflared"

# Source environment file
[ -f "$ENV_FILE" ] && . "$ENV_FILE"

do_start() {
    if [ ! -f "\$LOCK_FILE" ] ; then
        echo -n "Starting \$DAEMON: "
        runuser -l "\$USER" -c "\$DAEMON --no-autoupdate tunnel run" && echo_success || echo_failure
        RETVAL=\$?
        echo
        [ \$RETVAL -eq 0 ] && touch \$LOCK_FILE
    else
        echo "\$DAEMON is locked."
    fi
}
do_stop() {
    echo -n "Shutting down \$DAEMON: "
    pid=\$(ps -aefw | grep "\$DAEMON" | grep -v " grep " | awk '{print \$2}')
    kill -9 \$pid > /dev/null 2>&1
    [ \$? -eq 0 ] && echo_success || echo_failure
    RETVAL=\$?
    echo
    [ \$RETVAL -eq 0 ] && rm -f \$LOCK_FILE
}

case "\$1" in
    start)
        do_start
        ;;
    stop)
        do_stop
        ;;
    restart)
        do_stop
        do_start
        ;;
    *)
        echo "Usage: \$0 {start|stop|restart}"
        RETVAL=1
esac

exit \$RETVAL
EOF
    
    chmod +x "$SERVICE_FILE"
    print_success "Created SysV init script"
    
    # Enable service
    if command -v chkconfig >/dev/null 2>&1; then
        chkconfig --add cloudflared
        chkconfig cloudflared on
        print_success "Service enabled with chkconfig"
    elif command -v update-rc.d >/dev/null 2>&1; then
        update-rc.d cloudflared defaults
        print_success "Service enabled with update-rc.d"
    fi
}

# Create OpenRC service
create_openrc_service() {
    print_info "Creating OpenRC service script"
    
    cat > "$SERVICE_FILE" << EOF
#!/sbin/openrc-run
# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

description="Cloudflare Tunnel daemon"
command="$CLOUDFLARED_BINARY"
command_args="--no-autoupdate tunnel run"
command_user="$CLOUDFLARED_USER:$CLOUDFLARED_GROUP"
pidfile="/run/cloudflared.pid"
command_background="yes"

depend() {
    need net
    after logger
}

start_pre() {
    checkpath --directory --owner \$command_user --mode 0755 /run
}
EOF
    
    chmod +x "$SERVICE_FILE"
    print_success "Created OpenRC service script"
    
    # Enable service
    if command -v rc-update >/dev/null 2>&1; then
        rc-update add cloudflared default
        print_success "Service enabled with rc-update"
    fi
}

# Check and create service based on init system
check_service() {
    print_header "Checking Service Configuration"
    
    case "$INIT_SYSTEM" in
        systemd)
            if [[ -f "$SERVICE_FILE" ]]; then
                print_success "Systemd service file exists: $SERVICE_FILE"
                
                # Check if ExecStart uses correct binary path
                if grep -q "ExecStart=$CLOUDFLARED_BINARY" "$SERVICE_FILE"; then
                    print_success "Service uses correct binary path"
                else
                    print_warning "Service may be using incorrect binary path"
                    print_info "Expected: ExecStart=$CLOUDFLARED_BINARY"
                    print_info "Current: $(grep "ExecStart=" "$SERVICE_FILE" || echo "Not found")"
                fi
            else
                create_systemd_service
            fi
            ;;
        sysv)
            if [[ -f "$SERVICE_FILE" ]]; then
                print_success "SysV init script exists: $SERVICE_FILE"
            else
                create_sysv_service
            fi
            ;;
        openrc)
            if [[ -f "$SERVICE_FILE" ]]; then
                print_success "OpenRC service script exists: $SERVICE_FILE"
            else
                create_openrc_service
            fi
            ;;
        *)
            print_warning "Unknown init system - service management will be manual"
            print_info "You can start cloudflared manually with:"
            print_info "sudo -u $CLOUDFLARED_USER $CLOUDFLARED_BINARY --no-autoupdate tunnel run"
            ;;
    esac
}

# Check environment file
check_environment_file() {
    print_header "Checking Environment File"
    
    if [[ -f "$ENV_FILE" ]]; then
        print_success "Environment file exists: $ENV_FILE"
    else
        print_info "Creating environment file template"
        
        mkdir -p "$(dirname "$ENV_FILE")"
        
        case "$INIT_SYSTEM" in
            openrc)
                cat > "$ENV_FILE" << 'EOF'
# Cloudflare Tunnel Environment Variables for OpenRC
# Uncomment and set as needed

# export TUNNEL_TOKEN="your-tunnel-token-here"
# command_args="--no-autoupdate tunnel run --loglevel debug"
EOF
                ;;
            *)
                cat > "$ENV_FILE" << 'EOF'
# Cloudflare Tunnel Environment Variables
# Uncomment and set as needed

# TUNNEL_TOKEN=your-tunnel-token-here
# CLOUDFLARED_OPTS=--loglevel debug
EOF
                ;;
        esac
        
        chmod 644 "$ENV_FILE"
        print_success "Created environment file template"
    fi
}

# Check network connectivity
check_connectivity() {
    print_header "Checking Network Connectivity"
    
    # Check internet connectivity
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        print_success "Internet connectivity OK"
    else
        print_error "No internet connectivity"
        return 1
    fi
    
    # Check Cloudflare connectivity
    if ping -c 1 one.one.one.one >/dev/null 2>&1; then
        print_success "Cloudflare DNS reachable"
    else
        print_warning "Cannot reach Cloudflare DNS"
    fi
    
    # Check if we can resolve Cloudflare API
    if nslookup api.cloudflare.com >/dev/null 2>&1; then
        print_success "Can resolve Cloudflare API"
    else
        print_warning "Cannot resolve Cloudflare API"
    fi
}

# Test tunnel authentication
test_tunnel_auth() {
    print_header "Testing Tunnel Authentication"
    
    # Try to list tunnels as cloudflared user
    if sudo -u "$CLOUDFLARED_USER" "$CLOUDFLARED_BINARY" tunnel list >/dev/null 2>&1; then
        print_success "Can authenticate and list tunnels"
        
        # Show available tunnels
        print_info "Available tunnels:"
        sudo -u "$CLOUDFLARED_USER" "$CLOUDFLARED_BINARY" tunnel list 2>/dev/null | tail -n +2 || true
    else
        print_warning "Cannot list tunnels - may need authentication"
        print_info "Run: sudo -u $CLOUDFLARED_USER $CLOUDFLARED_BINARY tunnel login"
    fi
}

# Check service status
check_service_status() {
    print_header "Checking Service Status"
    
    case "$INIT_SYSTEM" in
        systemd)
            local status=$(systemctl is-active cloudflared 2>/dev/null || echo "unknown")
            local enabled=$(systemctl is-enabled cloudflared 2>/dev/null || echo "unknown")
            
            print_info "Service status: $status"
            print_info "Service enabled: $enabled"
            
            if [[ "$status" == "active" ]]; then
                print_success "Service is running"
            else
                print_warning "Service is not running"
                
                # Show recent logs
                print_info "Recent logs:"
                journalctl -u cloudflared -n 10 --no-pager 2>/dev/null || true
            fi
            ;;
        sysv)
            if service cloudflared status >/dev/null 2>&1; then
                print_success "Service is running"
            else
                print_warning "Service is not running"
                print_info "Start with: service cloudflared start"
            fi
            ;;
        openrc)
            if rc-service cloudflared status >/dev/null 2>&1; then
                print_success "Service is running"
            else
                print_warning "Service is not running"
                print_info "Start with: rc-service cloudflared start"
            fi
            ;;
        *)
            print_info "Manual service management required"
            if pgrep -f "cloudflared.*tunnel.*run" >/dev/null; then
                print_success "Cloudflared process is running"
            else
                print_warning "Cloudflared process is not running"
            fi
            ;;
    esac
}

# Fix common issues
fix_common_issues() {
    print_header "Fixing Common Issues"
    
    # Ensure all files have correct ownership
    find "$CONFIG_DIR" -type f -exec chown "$CLOUDFLARED_USER:$CLOUDFLARED_GROUP" {} \;
    find "$CONFIG_DIR" -name "*.json" -exec chmod 600 {} \;
    find "$CONFIG_DIR" -name "*.yml" -exec chmod 640 {} \;
    print_success "Fixed file permissions in $CONFIG_DIR"
    
    # Create log directory if it doesn't exist
    local log_dir="/var/log/cloudflared"
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir"
        chown "$CLOUDFLARED_USER:$CLOUDFLARED_GROUP" "$log_dir"
        chmod 755 "$log_dir"
        print_success "Created log directory: $log_dir"
    fi
    
    # Ensure cloudflared user can write to its home directory
    local home_dir="/var/lib/cloudflared"
    if [[ -d "$home_dir" ]]; then
        chown -R "$CLOUDFLARED_USER:$CLOUDFLARED_GROUP" "$home_dir"
        chmod 750 "$home_dir"
        print_success "Fixed home directory permissions: $home_dir"
    fi
}

# Generate summary report
generate_summary() {
    print_header "Summary Report"
    
    echo -e "\n${BLUE}System Information:${NC}"
    echo "- Distribution: $DISTRO"
    echo "- Init System: $INIT_SYSTEM"
    echo "- Package Manager: $PACKAGE_MANAGER"
    
    echo -e "\n${BLUE}Configuration Summary:${NC}"
    echo "- Binary: $CLOUDFLARED_BINARY"
    echo "- User: $CLOUDFLARED_USER"
    echo "- Group: $CLOUDFLARED_GROUP"
    echo "- Config Dir: $CONFIG_DIR"
    echo "- Service File: $SERVICE_FILE"
    echo "- Environment File: $ENV_FILE"
    echo "- Log File: $LOG_FILE"
    
    echo -e "\n${BLUE}Next Steps:${NC}"
    
    if [[ ! -f "$CONFIG_DIR/config.yml" ]] || grep -q "<YOUR-TUNNEL" "$CONFIG_DIR/config.yml"; then
        echo "1. Edit $CONFIG_DIR/config.yml with your tunnel details"
    fi
    
    local cred_files=($(find "$CONFIG_DIR" -name "*.json" 2>/dev/null || true))
    if [[ ${#cred_files[@]} -eq 0 ]]; then
        echo "2. Create a tunnel and place credentials in $CONFIG_DIR/"
        echo "   sudo -u $CLOUDFLARED_USER $CLOUDFLARED_BINARY tunnel login"
        echo "   sudo -u $CLOUDFLARED_USER $CLOUDFLARED_BINARY tunnel create <name>"
    fi
    
    echo "3. Start the service:"
    case "$INIT_SYSTEM" in
        systemd)
            echo "   sudo systemctl start cloudflared"
            echo "   sudo systemctl status cloudflared"
            ;;
        sysv)
            echo "   sudo service cloudflared start"
            echo "   sudo service cloudflared status"
            ;;
        openrc)
            echo "   sudo rc-service cloudflared start"
            echo "   sudo rc-service cloudflared status"
            ;;
        *)
            echo "   sudo -u $CLOUDFLARED_USER $CLOUDFLARED_BINARY --no-autoupdate tunnel run"
            ;;
    esac
    
    echo -e "\n${GREEN}Verification complete! Check $LOG_FILE for detailed logs.${NC}"
}

# Main execution
main() {
    print_header "Cloudflare Tunnel Setup Verification"
    
    check_root
    init_log
    
    # Detect system
    detect_distribution
    detect_init_system
    
    # Run all checks
    install_dependencies
    check_binary || exit 1
    check_user_group
    check_config_directory
    check_config_file
    check_credentials
    check_service
    check_environment_file
    check_connectivity
    test_tunnel_auth
    check_service_status
    fix_common_issues
    
    generate_summary
}

# Run main function
main "$@"
