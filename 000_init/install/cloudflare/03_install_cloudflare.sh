#!/bin/bash

# install_cloudflare.sh - Install Cloudflare Tunnel (cloudflared) on Linux
# Enhanced version supporting multiple distributions and init systems
# Supports: Debian, Ubuntu, Armbian, CentOS, RHEL, Fedora, Arch, Alpine, OpenSUSE

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)"
    echo "Usage: sudo $0"
    exit 1
fi

INSTALL_LOG="/tmp/cloudflare_install.log"
BACKUP_DIR="/tmp/cloudflare_backup"

echo "=== Cloudflare Tunnel Installation ===" | tee "$INSTALL_LOG"
echo "Date: $(date)" | tee -a "$INSTALL_LOG"
echo "System: $(uname -a)" | tee -a "$INSTALL_LOG"
echo "" | tee -a "$INSTALL_LOG"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to log installations
log_install() {
    echo "INSTALL:$1" >> "$INSTALL_LOG"
}

# Function to log file changes
log_file() {
    echo "FILE:$1" >> "$INSTALL_LOG"
}

# Function to detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
        DISTRO_NAME=$NAME
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
        VERSION=$(cat /etc/debian_version)
        DISTRO_NAME="Debian"
    elif [ -f /etc/redhat-release ]; then
        DISTRO="rhel"
        VERSION=$(grep -oE '[0-9]+\.[0-9]+' /etc/redhat-release | head -1)
        DISTRO_NAME=$(cat /etc/redhat-release)
    else
        DISTRO="unknown"
        VERSION="unknown"
        DISTRO_NAME="Unknown"
    fi
    
    echo "Detected distribution: $DISTRO_NAME ($DISTRO $VERSION)" | tee -a "$INSTALL_LOG"
}

# Function to detect init system
detect_init_system() {
    if [ -d /run/systemd/system ]; then
        INIT_SYSTEM="systemd"
    elif [ -f /sbin/openrc ]; then
        INIT_SYSTEM="openrc"
    elif [ -f /etc/init.d/rcS ]; then
        INIT_SYSTEM="sysvinit"
    elif command -v service >/dev/null 2>&1; then
        INIT_SYSTEM="service"
    else
        INIT_SYSTEM="unknown"
    fi
    
    echo "Detected init system: $INIT_SYSTEM" | tee -a "$INSTALL_LOG"
}

# Function to check if cloudflared is already installed
check_existing_installation() {
    if command -v cloudflared &> /dev/null; then
        CURRENT_VERSION=$(cloudflared version 2>/dev/null | head -n1 || echo "unknown")
        echo "Cloudflared is already installed: $CURRENT_VERSION" | tee -a "$INSTALL_LOG"
        
        # Check if it's running
        if pgrep -f cloudflared >/dev/null 2>&1; then
            echo "Warning: Cloudflared is currently running" | tee -a "$INSTALL_LOG"
        fi
        
        read -p "Do you want to reinstall/update? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            exit 0
        fi
        
        # Stop service if running
        stop_cloudflared_service
    fi
}

# Function to stop cloudflared service
stop_cloudflared_service() {
    echo "Stopping cloudflared service if running..." | tee -a "$INSTALL_LOG"
    
    case $INIT_SYSTEM in
        systemd)
            if systemctl is-active --quiet cloudflared 2>/dev/null; then
                systemctl stop cloudflared || true
            fi
            ;;
        openrc)
            if rc-service cloudflared status >/dev/null 2>&1; then
                rc-service cloudflared stop || true
            fi
            ;;
        sysvinit|service)
            if service cloudflared status >/dev/null 2>&1; then
                service cloudflared stop || true
            fi
            ;;
    esac
}

# Function to install dependencies based on distribution
install_dependencies() {
    echo "Installing dependencies..." | tee -a "$INSTALL_LOG"
    
    case $DISTRO in
        debian|ubuntu|armbian)
            apt-get update
            apt-get install -y curl wget ca-certificates
            log_install "DEPS:curl,wget,ca-certificates"
            ;;
        centos|rhel|fedora|rocky|almalinux)
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y curl wget ca-certificates
            else
                yum install -y curl wget ca-certificates
            fi
            log_install "DEPS:curl,wget,ca-certificates"
            ;;
        arch|manjaro)
            pacman -Sy --noconfirm curl wget ca-certificates
            log_install "DEPS:curl,wget,ca-certificates"
            ;;
        alpine)
            apk update
            apk add curl wget ca-certificates
            log_install "DEPS:curl,wget,ca-certificates"
            ;;
        opensuse*|sles)
            zypper install -y curl wget ca-certificates
            log_install "DEPS:curl,wget,ca-certificates"
            ;;
        *)
            echo "Warning: Unknown distribution '$DISTRO'. Please ensure curl, wget, and ca-certificates are installed."
            echo "If you encounter issues, please update this script with the appropriate package manager commands for your distribution."
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Installation cancelled. Please install dependencies manually and update the script."
                exit 1
            fi
            ;;
    esac
}

# Detect architecture
detect_architecture() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            CF_ARCH="amd64"
            ;;
        aarch64|arm64)
            CF_ARCH="arm64"
            ;;
        armv7l|armhf)
            CF_ARCH="armhf"
            ;;
        armv6l)
            CF_ARCH="arm"
            ;;
        *)
            echo "Error: Unsupported architecture: $ARCH"
            echo "Supported architectures: x86_64, aarch64, armv7l, armv6l"
            exit 1
            ;;
    esac
    
    echo "Detected architecture: $ARCH -> cloudflared $CF_ARCH" | tee -a "$INSTALL_LOG"
}

# Function to download and install cloudflared
install_cloudflared_binary() {
    echo "Downloading cloudflared for $CF_ARCH..." | tee -a "$INSTALL_LOG"
    DOWNLOAD_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$CF_ARCH"
    
    # Download to temporary location
    TEMP_FILE="/tmp/cloudflared-$CF_ARCH"
    if ! curl -L -o "$TEMP_FILE" "$DOWNLOAD_URL"; then
        echo "Error: Failed to download cloudflared"
        echo "URL: $DOWNLOAD_URL"
        exit 1
    fi
    
    # Verify download
    if [ ! -f "$TEMP_FILE" ] || [ ! -s "$TEMP_FILE" ]; then
        echo "Error: Downloaded file is empty or missing"
        exit 1
    fi
    
    echo "Download completed successfully" | tee -a "$INSTALL_LOG"
    
    # Backup existing installation if it exists
    if [ -f "/usr/local/bin/cloudflared" ]; then
        echo "Backing up existing cloudflared..." | tee -a "$INSTALL_LOG"
        cp /usr/local/bin/cloudflared "$BACKUP_DIR/cloudflared.backup.$(date +%Y%m%d_%H%M%S)"
        log_file "BACKUP:/usr/local/bin/cloudflared"
    fi
    
    # Install cloudflared
    echo "Installing cloudflared..." | tee -a "$INSTALL_LOG"
    chmod +x "$TEMP_FILE"
    mv "$TEMP_FILE" /usr/local/bin/cloudflared
    chown root:root /usr/local/bin/cloudflared
    log_install "/usr/local/bin/cloudflared"
    
    # Verify installation
    if ! command -v cloudflared &> /dev/null; then
        echo "Error: cloudflared installation failed"
        exit 1
    fi
    
    INSTALLED_VERSION=$(cloudflared version 2>/dev/null | head -n1 || echo "unknown")
    echo "Cloudflared installed successfully: $INSTALLED_VERSION" | tee -a "$INSTALL_LOG"
}

# Function to create cloudflared user
create_cloudflared_user() {
    if ! id "cloudflared" &>/dev/null; then
        echo "Creating cloudflared user..." | tee -a "$INSTALL_LOG"
        
        case $DISTRO in
            alpine)
                adduser -r -s /bin/false -D -H cloudflared
                ;;
            *)
                useradd -r -s /bin/false -d /nonexistent cloudflared 2>/dev/null || \
                useradd -r -s /bin/false cloudflared
                ;;
        esac
        
        log_install "USER:cloudflared"
    else
        echo "User 'cloudflared' already exists" | tee -a "$INSTALL_LOG"
    fi
}

# Function to setup directories and permissions
setup_directories() {
    echo "Setting up directories and permissions..." | tee -a "$INSTALL_LOG"
    
    mkdir -p /etc/cloudflared
    mkdir -p /var/log/cloudflared
    
    chown cloudflared:cloudflared /etc/cloudflared 2>/dev/null || \
    chown cloudflared /etc/cloudflared
    
    chown cloudflared:cloudflared /var/log/cloudflared 2>/dev/null || \
    chown cloudflared /var/log/cloudflared
    
    chmod 750 /etc/cloudflared
    chmod 750 /var/log/cloudflared
    
    log_file "/etc/cloudflared"
    log_file "/var/log/cloudflared"
}

# Function to create service files based on init system
create_service_files() {
    echo "Creating service configuration for $INIT_SYSTEM..." | tee -a "$INSTALL_LOG"
    
    case $INIT_SYSTEM in
        systemd)
            create_systemd_service
            ;;
        openrc)
            create_openrc_service
            ;;
        sysvinit|service)
            create_sysvinit_service
            ;;
        *)
            echo "Warning: Unknown init system '$INIT_SYSTEM'"
            echo "You will need to manually create a service configuration."
            echo "Please update this script with the appropriate service configuration for your init system."
            ;;
    esac
}

# Function to create systemd service
create_systemd_service() {
    cat > /etc/systemd/system/cloudflared.service << 'EOF'
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
Type=notify
User=cloudflared
Group=cloudflared
ExecStart=/usr/local/bin/cloudflared tunnel --no-autoupdate run
Restart=on-failure
RestartSec=5s
TimeoutStartSec=30s
TimeoutStopSec=30s
StandardOutput=journal
StandardError=journal
SyslogIdentifier=cloudflared
KillMode=mixed

[Install]
WantedBy=multi-user.target
EOF
    
    log_file "/etc/systemd/system/cloudflared.service"
    
    # Reload systemd
    systemctl daemon-reload
    log_install "SYSTEMD_RELOAD"
}

# Function to create OpenRC service
create_openrc_service() {
    cat > /etc/init.d/cloudflared << 'EOF'
#!/sbin/openrc-run

name="cloudflared"
description="Cloudflare Tunnel"
command="/usr/local/bin/cloudflared"
command_args="tunnel --no-autoupdate run"
command_user="cloudflared"
command_background="yes"
pidfile="/run/${RC_SVCNAME}.pid"
start_stop_daemon_args="--stdout /var/log/cloudflared/cloudflared.log --stderr /var/log/cloudflared/cloudflared.log"

depend() {
    need net
    after firewall
}

start_pre() {
    checkpath --directory --owner cloudflared:cloudflared --mode 0755 /var/log/cloudflared
    checkpath --directory --owner cloudflared:cloudflared --mode 0755 /etc/cloudflared
}
EOF
    
    chmod +x /etc/init.d/cloudflared
    log_file "/etc/init.d/cloudflared"
}

# Function to create SysV init service
create_sysvinit_service() {
    cat > /etc/init.d/cloudflared << 'EOF'
#!/bin/bash
#
# cloudflared        Cloudflare Tunnel
#
# chkconfig: 35 80 20
# description: Cloudflare Tunnel daemon
#

. /etc/rc.d/init.d/functions 2>/dev/null || . /lib/lsb/init-functions 2>/dev/null || true

USER="cloudflared"
DAEMON="cloudflared"
ROOT_DIR="/var/lib/cloudflared"

SERVER="$ROOT_DIR/$DAEMON"
LOCK_FILE="/var/lock/subsys/cloudflared"

start() {
    echo -n $"Starting $DAEMON: "
    daemon --user "$USER" --pidfile="$LOCK_FILE" \
           /usr/local/bin/cloudflared tunnel --no-autoupdate run
    RETVAL=$?
    echo
    [ $RETVAL -eq 0 ] && touch $LOCK_FILE
    return $RETVAL
}

stop() {
    echo -n $"Shutting down $DAEMON: "
    pid=`ps -aefw | grep "$DAEMON" | grep -v " grep " | awk '{print $2}'`
    kill -9 $pid > /dev/null 2>&1
    [ $? -eq 0 ] && echo_success || echo_failure
    echo
    [ $? -eq 0 ] && rm -f $LOCK_FILE
}

restart() {
    stop
    start
}

status() {
    if [ -f $LOCK_FILE ]; then
        echo "$DAEMON is running."
    else
        echo "$DAEMON is stopped."
    fi
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    restart)
        restart
        ;;
    *)
        echo "Usage: {start|stop|status|restart}"
        exit 1
        ;;
esac

exit $?
EOF
    
    chmod +x /etc/init.d/cloudflared
    log_file "/etc/init.d/cloudflared"
    
    # Enable service on boot (distribution-specific)
    case $DISTRO in
        debian|ubuntu|armbian)
            update-rc.d cloudflared defaults 2>/dev/null || true
            ;;
        centos|rhel|fedora|rocky|almalinux)
            chkconfig cloudflared on 2>/dev/null || true
            ;;
    esac
}

# Function to create sample configuration
create_sample_config() {
    echo "Creating sample configuration..." | tee -a "$INSTALL_LOG"
    
    cat > /etc/cloudflared/config.yml.sample << 'EOF'
# Cloudflare Tunnel Configuration Sample
# Copy this to config.yml and customize for your setup

# Tunnel UUID (get this after creating a tunnel)
tunnel: YOUR_TUNNEL_ID

# Credentials file (generated when you create a tunnel)
credentials-file: /etc/cloudflared/YOUR_TUNNEL_ID.json

# Ingress rules - customize these for your services
ingress:
  # Example: Route subdomain to local service
  - hostname: app.yourdomain.com
    service: http://localhost:3000
  
  # Example: Route another subdomain to different service
  - hostname: api.yourdomain.com
    service: http://localhost:8080
  
  # Catch-all rule (required as last rule)
  - service: http_status:404

# Optional: Logging configuration
# loglevel: info
# logfile: /var/log/cloudflared/cloudflared.log

# Optional: Metrics server
# metrics: localhost:8080
EOF
    
    chown cloudflared:cloudflared /etc/cloudflared/config.yml.sample 2>/dev/null || \
    chown cloudflared /etc/cloudflared/config.yml.sample
    
    log_file "/etc/cloudflared/config.yml.sample"
}

# Function to create setup helper script
create_setup_helper() {
    echo "Creating setup helper script..." | tee -a "$INSTALL_LOG"
    
    cat > /usr/local/bin/cloudflared-setup << 'EOF'
#!/bin/bash

# cloudflared-setup - Helper script for Cloudflare Tunnel setup

set -e

echo "=== Cloudflare Tunnel Setup Helper ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)"
    echo "Usage: sudo $0"
    exit 1
fi

# Check environment variables
if [ -z "$CLOUDFLARE_API_TOKEN" ] || [ -z "$CLOUDFLARE_ACCOUNT_ID" ]; then
    echo "Error: Required environment variables not set"
    echo "Please run access_check.sh first to verify your credentials"
    exit 1
fi

echo "This script will help you:"
echo "1. Create a new Cloudflare Tunnel"
echo "2. Generate the credentials file"
echo "3. Create a basic configuration"
echo ""

read -p "Enter a name for your tunnel: " TUNNEL_NAME
if [ -z "$TUNNEL_NAME" ]; then
    echo "Error: Tunnel name cannot be empty"
    exit 1
fi

echo ""
echo "Creating tunnel '$TUNNEL_NAME'..."

# Create tunnel and capture output
TUNNEL_OUTPUT=$(cloudflared tunnel create "$TUNNEL_NAME" 2>&1)
echo "$TUNNEL_OUTPUT"

# Extract tunnel ID from output
TUNNEL_ID=$(echo "$TUNNEL_OUTPUT" | grep -oP 'Created tunnel \K[a-f0-9-]+' | head -1)

if [ -z "$TUNNEL_ID" ]; then
    echo "Error: Could not extract tunnel ID from output"
    exit 1
fi

echo ""
echo "Tunnel created successfully!"
echo "Tunnel ID: $TUNNEL_ID"

# Move credentials file to proper location
CRED_FILE="/root/.cloudflared/$TUNNEL_ID.json"
if [ -f "$CRED_FILE" ]; then
    cp "$CRED_FILE" "/etc/cloudflared/$TUNNEL_ID.json"
    chown cloudflared:cloudflared "/etc/cloudflared/$TUNNEL_ID.json" 2>/dev/null || \
    chown cloudflared "/etc/cloudflared/$TUNNEL_ID.json"
    chmod 600 "/etc/cloudflared/$TUNNEL_ID.json"
    echo "Credentials file copied to /etc/cloudflared/$TUNNEL_ID.json"
fi

# Create configuration file from sample
if [ -f "/etc/cloudflared/config.yml.sample" ]; then
    sed "s/YOUR_TUNNEL_ID/$TUNNEL_ID/g" /etc/cloudflared/config.yml.sample > /etc/cloudflared/config.yml
    chown cloudflared:cloudflared /etc/cloudflared/config.yml 2>/dev/null || \
    chown cloudflared /etc/cloudflared/config.yml
    chmod 600 /etc/cloudflared/config.yml
    echo "Configuration file created at /etc/cloudflared/config.yml"
    echo ""
    echo "⚠ IMPORTANT: Edit /etc/cloudflared/config.yml to configure your ingress rules"
fi

echo ""
echo "Next steps:"
echo "1. Edit /etc/cloudflared/config.yml to configure your services"
echo "2. Create DNS records: cloudflared tunnel route dns $TUNNEL_NAME subdomain.yourdomain.com"

# Detect init system for service commands
if [ -d /run/systemd/system ]; then
    echo "3. Start the service: sudo systemctl enable --now cloudflared"
    echo "4. Check status: sudo systemctl status cloudflared"
elif [ -f /sbin/openrc ]; then
    echo "3. Start the service: sudo rc-update add cloudflared && sudo rc-service cloudflared start"
    echo "4. Check status: sudo rc-service cloudflared status"
else
    echo "3. Start the service: sudo service cloudflared start"
    echo "4. Check status: sudo service cloudflared status"
fi
EOF
    
    chmod +x /usr/local/bin/cloudflared-setup
    log_install "/usr/local/bin/cloudflared-setup"
}

# Function to display final instructions
display_final_instructions() {
    echo "" | tee -a "$INSTALL_LOG"
    echo "✅ Cloudflare Tunnel installation completed successfully!" | tee -a "$INSTALL_LOG"
    echo "" | tee -a "$INSTALL_LOG"
    echo "Installation details:" | tee -a "$INSTALL_LOG"
    echo "• Distribution: $DISTRO_NAME ($DISTRO $VERSION)" | tee -a "$INSTALL_LOG"
    echo "• Init system: $INIT_SYSTEM" | tee -a "$INSTALL_LOG"
    echo "• Architecture: $ARCH ($CF_ARCH)" | tee -a "$INSTALL_LOG"
    echo "• Cloudflared binary: /usr/local/bin/cloudflared" | tee -a "$INSTALL_LOG"
    echo "• Configuration directory: /etc/cloudflared" | tee -a "$INSTALL_LOG"
    echo "• Log directory: /var/log/cloudflared" | tee -a "$INSTALL_LOG"
    echo "• Setup helper: /usr/local/bin/cloudflared-setup" | tee -a "$INSTALL_LOG"
    echo "" | tee -a "$INSTALL_LOG"
    
    case $INIT_SYSTEM in
        systemd)
            echo "• Service: cloudflared.service (systemd)" | tee -a "$INSTALL_LOG"
            echo "" | tee -a "$INSTALL_LOG"
            echo "Service commands:" | tee -a "$INSTALL_LOG"
            echo "• Start: sudo systemctl start cloudflared" | tee -a "$INSTALL_LOG"
            echo "• Enable: sudo systemctl enable cloudflared" | tee -a "$INSTALL_LOG"
            echo "• Status: sudo systemctl status cloudflared" | tee -a "$INSTALL_LOG"
            echo "• Logs: sudo journalctl -u cloudflared -f" | tee -a "$INSTALL_LOG"
            ;;
        openrc)
            echo "• Service: cloudflared (OpenRC)" | tee -a "$INSTALL_LOG"
            echo "" | tee -a "$INSTALL_LOG"
            echo "Service commands:" | tee -a "$INSTALL_LOG"
            echo "• Start: sudo rc-service cloudflared start" | tee -a "$INSTALL_LOG"
            echo "• Enable: sudo rc-update add cloudflared" | tee -a "$INSTALL_LOG"
            echo "• Status: sudo rc-service cloudflared status" | tee -a "$INSTALL_LOG"
            ;;
        sysvinit|service)
            echo "• Service: cloudflared (SysV Init)" | tee -a "$INSTALL_LOG"
            echo "" | tee -a "$INSTALL_LOG"
            echo "Service commands:" | tee -a "$INSTALL_LOG"
            echo "• Start: sudo service cloudflared start" | tee -a "$INSTALL_LOG"
            echo "• Status: sudo service cloudflared status" | tee -a "$INSTALL_LOG"
            ;;
        *)
            echo "• Service: Manual configuration required" | tee -a "$INSTALL_LOG"
            echo "" | tee -a "$INSTALL_LOG"
            echo "⚠ Warning: Unknown init system. You'll need to manually configure the service." | tee -a "$INSTALL_LOG"
            ;;
    esac
    
    echo "" | tee -a "$INSTALL_LOG"
    echo "Next steps:" | tee -a "$INSTALL_LOG"
    echo "1. Ensure your environment variables are set (run access_check.sh)" | tee -a "$INSTALL_LOG"
    echo "2. Run: sudo cloudflared-setup (to create tunnel and configuration)" | tee -a "$INSTALL_LOG"
    echo "3. Edit /etc/cloudflared/config.yml to configure your services" | tee -a "$INSTALL_LOG"
    
    case $INIT_SYSTEM in
        systemd)
            echo "4. Start the service: sudo systemctl enable --now cloudflared" | tee -a "$INSTALL_LOG"
            ;;
        openrc)
            echo "4. Start the service: sudo rc-update add cloudflared && sudo rc-service cloudflared start" | tee -a "$INSTALL_LOG"
            ;;
        sysvinit|service)
            echo "4. Start the service: sudo service cloudflared start" | tee -a "$INSTALL_LOG"
            ;;
    esac
    
    echo "" | tee -a "$INSTALL_LOG"
    echo "Installation log saved to: $INSTALL_LOG" | tee -a "$INSTALL_LOG"
}

# Main installation process
main() {
    detect_distro
    detect_init_system
    detect_architecture
    check_existing_installation
    install_dependencies
    install_cloudflared_binary
    create_cloudflared_user
    setup_directories
    create_service_files
    create_sample_config
    create_setup_helper
    display_final_instructions
}

# Run main function
main "$@"
