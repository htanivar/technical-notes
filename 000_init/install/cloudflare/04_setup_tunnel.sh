#!/bin/bash

# 04_setup_tunnel.sh - Complete Cloudflare Tunnel Setup
# Performs steps 2, 3, and 4 of the tunnel setup process
# 1. Run cloudflared-setup to create tunnel and configuration
# 2. Edit /etc/cloudflared/config.yml to configure services
# 3. Start and enable the cloudflared service

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
SETUP_LOG="/tmp/cloudflare_tunnel_setup.log"

echo -e "${BLUE}=== Cloudflare Tunnel Complete Setup ===${NC}" | tee "$SETUP_LOG"
echo "Date: $(date)" | tee -a "$SETUP_LOG"
echo "" | tee -a "$SETUP_LOG"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    echo "Usage: sudo $0"
    exit 1
fi

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo -e "${RED}Error: cloudflared is not installed${NC}"
    echo "Please run the installation script first"
    exit 1
fi

# Check if cloudflared-setup exists
if [ ! -f "/usr/local/bin/cloudflared-setup" ]; then
    echo -e "${RED}Error: cloudflared-setup helper script not found${NC}"
    echo "Please run the installation script first"
    exit 1
fi

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
    
    echo "Detected init system: $INIT_SYSTEM" | tee -a "$SETUP_LOG"
}

# Function to check environment variables
check_environment() {
    echo -e "${BLUE}Step 0: Checking environment variables...${NC}" | tee -a "$SETUP_LOG"
    
    if [ -z "$CLOUDFLARE_API_TOKEN" ] || [ -z "$CLOUDFLARE_ACCOUNT_ID" ]; then
        echo -e "${RED}Error: Required environment variables not set${NC}"
        echo "Please set the following environment variables:"
        echo "  export CLOUDFLARE_API_TOKEN='your_api_token'"
        echo "  export CLOUDFLARE_ACCOUNT_ID='your_account_id'"
        echo ""
        echo "You can get these from your Cloudflare dashboard:"
        echo "  API Token: https://dash.cloudflare.com/profile/api-tokens"
        echo "  Account ID: https://dash.cloudflare.com/ (right sidebar)"
        echo ""
        echo "Or run access_check.sh to verify your credentials"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Environment variables are set${NC}" | tee -a "$SETUP_LOG"
}

# Function to run cloudflared-setup (Step 2)
run_cloudflared_setup() {
    echo "" | tee -a "$SETUP_LOG"
    echo -e "${BLUE}Step 2: Running cloudflared-setup to create tunnel...${NC}" | tee -a "$SETUP_LOG"
    
    # Check if tunnel already exists
    if [ -f "/etc/cloudflared/config.yml" ]; then
        echo -e "${YELLOW}Warning: Configuration file already exists at /etc/cloudflared/config.yml${NC}"
        read -p "Do you want to recreate the tunnel? This will backup the existing config. (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Backup existing config
            BACKUP_FILE="/etc/cloudflared/config.yml.backup.$(date +%Y%m%d_%H%M%S)"
            cp /etc/cloudflared/config.yml "$BACKUP_FILE"
            echo "Existing config backed up to: $BACKUP_FILE" | tee -a "$SETUP_LOG"
        else
            echo "Skipping tunnel creation. Using existing configuration." | tee -a "$SETUP_LOG"
            return 0
        fi
    fi
    
    echo "Running cloudflared-setup..." | tee -a "$SETUP_LOG"
    
    # Run the setup helper
    if ! /usr/local/bin/cloudflared-setup; then
        echo -e "${RED}Error: cloudflared-setup failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Tunnel created successfully${NC}" | tee -a "$SETUP_LOG"
}

# Function to configure services (Step 3)
configure_services() {
    echo "" | tee -a "$SETUP_LOG"
    echo -e "${BLUE}Step 3: Configuring services in /etc/cloudflared/config.yml...${NC}" | tee -a "$SETUP_LOG"
    
    if [ ! -f "/etc/cloudflared/config.yml" ]; then
        echo -e "${RED}Error: Configuration file not found at /etc/cloudflared/config.yml${NC}"
        echo "Please run cloudflared-setup first"
        exit 1
    fi
    
    echo "Current configuration:" | tee -a "$SETUP_LOG"
    echo "----------------------------------------"
    cat /etc/cloudflared/config.yml
    echo "----------------------------------------"
    echo ""
    
    echo -e "${YELLOW}The configuration file needs to be customized for your services.${NC}"
    echo "You need to:"
    echo "1. Replace 'app.yourdomain.com' with your actual domain"
    echo "2. Configure the local services you want to expose"
    echo "3. Set up proper ingress rules"
    echo ""
    
    read -p "Do you want to edit the configuration now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Try different editors
        if command -v nano >/dev/null 2>&1; then
            nano /etc/cloudflared/config.yml
        elif command -v vi >/dev/null 2>&1; then
            vi /etc/cloudflared/config.yml
        elif command -v vim >/dev/null 2>&1; then
            vim /etc/cloudflared/config.yml
        else
            echo -e "${YELLOW}No text editor found. Please edit /etc/cloudflared/config.yml manually${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Remember to edit /etc/cloudflared/config.yml before starting the service${NC}"
    fi
    
    # Validate configuration
    echo "Validating configuration..." | tee -a "$SETUP_LOG"
    if cloudflared tunnel ingress validate; then
        echo -e "${GREEN}✓ Configuration is valid${NC}" | tee -a "$SETUP_LOG"
    else
        echo -e "${RED}⚠ Configuration validation failed${NC}" | tee -a "$SETUP_LOG"
        echo "Please check your configuration file"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Setup cancelled. Please fix the configuration and run this script again."
            exit 1
        fi
    fi
}

# Function to create DNS records
setup_dns_records() {
    echo "" | tee -a "$SETUP_LOG"
    echo -e "${BLUE}Setting up DNS records...${NC}" | tee -a "$SETUP_LOG"
    
    # Extract tunnel name from config
    TUNNEL_ID=$(grep "^tunnel:" /etc/cloudflared/config.yml | awk '{print $2}' | tr -d '"' || echo "")
    
    if [ -z "$TUNNEL_ID" ]; then
        echo -e "${YELLOW}Warning: Could not extract tunnel ID from config${NC}"
        echo "You'll need to set up DNS records manually"
        return 0
    fi
    
    # Get tunnel name
    TUNNEL_NAME=$(cloudflared tunnel list | grep "$TUNNEL_ID" | awk '{print $2}' || echo "")
    
    if [ -z "$TUNNEL_NAME" ]; then
        echo -e "${YELLOW}Warning: Could not get tunnel name${NC}"
        echo "You'll need to set up DNS records manually"
        return 0
    fi
    
    echo "Found tunnel: $TUNNEL_NAME (ID: $TUNNEL_ID)" | tee -a "$SETUP_LOG"
    
    # Extract hostnames from config
    HOSTNAMES=$(grep "hostname:" /etc/cloudflared/config.yml | awk '{print $3}' | tr -d '"' || echo "")
    
    if [ -z "$HOSTNAMES" ]; then
        echo -e "${YELLOW}No hostnames found in configuration${NC}"
        echo "Please add DNS records manually after configuring your services"
        return 0
    fi
    
    echo "Found hostnames in configuration:"
    echo "$HOSTNAMES"
    echo ""
    
    read -p "Do you want to create DNS records for these hostnames? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for hostname in $HOSTNAMES; do
            if [[ "$hostname" != *"yourdomain.com"* ]]; then
                echo "Creating DNS record for $hostname..." | tee -a "$SETUP_LOG"
                if cloudflared tunnel route dns "$TUNNEL_NAME" "$hostname"; then
                    echo -e "${GREEN}✓ DNS record created for $hostname${NC}" | tee -a "$SETUP_LOG"
                else
                    echo -e "${RED}✗ Failed to create DNS record for $hostname${NC}" | tee -a "$SETUP_LOG"
                fi
            else
                echo -e "${YELLOW}Skipping example hostname: $hostname${NC}"
            fi
        done
    else
        echo "Skipping DNS record creation. You can create them manually later with:"
        for hostname in $HOSTNAMES; do
            if [[ "$hostname" != *"yourdomain.com"* ]]; then
                echo "  cloudflared tunnel route dns $TUNNEL_NAME $hostname"
            fi
        done
    fi
}

# Function to start and enable service (Step 4)
start_service() {
    echo "" | tee -a "$SETUP_LOG"
    echo -e "${BLUE}Step 4: Starting and enabling cloudflared service...${NC}" | tee -a "$SETUP_LOG"
    
    case $INIT_SYSTEM in
    systemd)
        echo "Using systemd..." | tee -a "$SETUP_LOG"
        
        # Enable and start service
        if systemctl enable cloudflared; then
            echo -e "${GREEN}✓ Service enabled${NC}" | tee -a "$SETUP_LOG"
        else
            echo -e "${RED}✗ Failed to enable service${NC}" | tee -a "$SETUP_LOG"
        fi
        
        if systemctl start cloudflared; then
            echo -e "${GREEN}✓ Service started${NC}" | tee -a "$SETUP_LOG"
        else
            echo -e "${RED}✗ Failed to start service${NC}" | tee -a "$SETUP_LOG"
            echo "Check logs with: sudo journalctl -u cloudflared -f"
            return 1
        fi
        
        # Check status
        sleep 2
        if systemctl is-active --quiet cloudflared; then
            echo -e "${GREEN}✓ Service is running${NC}" | tee -a "$SETUP_LOG"
            systemctl status cloudflared --no-pager -l
        else
            echo -e "${RED}✗ Service is not running${NC}" | tee -a "$SETUP_LOG"
            echo "Check logs with: sudo journalctl -u cloudflared -f"
            return 1
        fi
        ;;
        
    openrc)
        echo "Using OpenRC..." | tee -a "$SETUP_LOG"
        
        # Add to default runlevel and start
        if rc-update add cloudflared; then
            echo -e "${GREEN}✓ Service enabled${NC}" | tee -a "$SETUP_LOG"
        else
            echo -e "${RED}✗ Failed to enable service${NC}" | tee -a "$SETUP_LOG"
        fi
        
        if rc-service cloudflared start; then
            echo -e "${GREEN}✓ Service started${NC}" | tee -a "$SETUP_LOG"
        else
            echo -e "${RED}✗ Failed to start service${NC}" | tee -a "$SETUP_LOG"
            return 1
        fi
        
        # Check status
        sleep 2
        rc-service cloudflared status
        ;;
        
    sysvinit|service)
        echo "Using SysV Init..." | tee -a "$SETUP_LOG"
        
        if service cloudflared start; then
            echo -e "${GREEN}✓ Service started${NC}" | tee -a "$SETUP_LOG"
        else
            echo -e "${RED}✗ Failed to start service${NC}" | tee -a "$SETUP_LOG"
            return 1
        fi
        
        # Check status
        sleep 2
        service cloudflared status
        ;;
        
    *)
        echo -e "${RED}Error: Unknown init system '$INIT_SYSTEM'${NC}"
        echo "Please start the service manually"
        return 1
        ;;
    esac
}

# Function to display final status and instructions
display_final_status() {
    echo "" | tee -a "$SETUP_LOG"
    echo -e "${GREEN}=== Setup Complete! ===${NC}" | tee -a "$SETUP_LOG"
    echo "" | tee -a "$SETUP_LOG"
    
    # Show tunnel status
    echo "Tunnel Status:" | tee -a "$SETUP_LOG"
    cloudflared tunnel list 2>/dev/null || echo "Could not list tunnels"
    echo ""
    
    # Show service status
    echo "Service Status:" | tee -a "$SETUP_LOG"
    case $INIT_SYSTEM in
    systemd)
        systemctl status cloudflared --no-pager -l || true
        echo ""
        echo "Useful commands:" | tee -a "$SETUP_LOG"
        echo "• Check status: sudo systemctl status cloudflared" | tee -a "$SETUP_LOG"
        echo "• View logs: sudo journalctl -u cloudflared -f" | tee -a "$SETUP_LOG"
        echo "• Restart: sudo systemctl restart cloudflared" | tee -a "$SETUP_LOG"
        echo "• Stop: sudo systemctl stop cloudflared" | tee -a "$SETUP_LOG"
        ;;
    openrc)
        rc-service cloudflared status || true
        echo ""
        echo "Useful commands:" | tee -a "$SETUP_LOG"
        echo "• Check status: sudo rc-service cloudflared status" | tee -a "$SETUP_LOG"
        echo "• Restart: sudo rc-service cloudflared restart" | tee -a "$SETUP_LOG"
        echo "• Stop: sudo rc-service cloudflared stop" | tee -a "$SETUP_LOG"
        ;;
    sysvinit|service)
        service cloudflared status || true
        echo ""
        echo "Useful commands:" | tee -a "$SETUP_LOG"
        echo "• Check status: sudo service cloudflared status" | tee -a "$SETUP_LOG"
        echo "• Restart: sudo service cloudflared restart" | tee -a "$SETUP_LOG"
        echo "• Stop: sudo service cloudflared stop" | tee -a "$SETUP_LOG"
        ;;
    esac
    
    echo "" | tee -a "$SETUP_LOG"
    echo "Configuration files:" | tee -a "$SETUP_LOG"
    echo "• Main config: /etc/cloudflared/config.yml" | tee -a "$SETUP_LOG"
    echo "• Credentials: /etc/cloudflared/*.json" | tee -a "$SETUP_LOG"
    echo "• Logs: /var/log/cloudflared/" | tee -a "$SETUP_LOG"
    echo "" | tee -a "$SETUP_LOG"
    
    echo -e "${BLUE}Next steps:${NC}" | tee -a "$SETUP_LOG"
    echo "1. Verify your services are accessible through the tunnel" | tee -a "$SETUP_LOG"
    echo "2. Monitor the logs for any issues" | tee -a "$SETUP_LOG"
    echo "3. Add more services to /etc/cloudflared/config.yml as needed" | tee -a "$SETUP_LOG"
    echo "" | tee -a "$SETUP_LOG"
    echo "Setup log saved to: $SETUP_LOG" | tee -a "$SETUP_LOG"
}

# Main execution
main() {
    detect_init_system
    check_environment
    run_cloudflared_setup
    configure_services
    setup_dns_records
    start_service
    display_final_status
}

# Run main function
main "$@"
