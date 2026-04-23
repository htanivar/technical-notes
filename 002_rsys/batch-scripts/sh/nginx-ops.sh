#!/usr/bin/env bash

# nginx-ops.sh - Nginx operations script
# Usage: ./nginx-ops.sh status

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color="$1"
    local msg="$2"
    echo -e "${color}${msg}${NC}"
}

# Function to check if nginx is installed and get its location
check_nginx_installed() {
    local nginx_path
    # Try to find nginx using which, command, or common paths
    if command -v nginx &> /dev/null; then
        nginx_path=$(command -v nginx)
        print_color "${GREEN}" "✓ Nginx is installed."
        echo "  Location: $nginx_path"
        return 0
    elif [ -f /usr/sbin/nginx ]; then
        nginx_path="/usr/sbin/nginx"
        print_color "${GREEN}" "✓ Nginx is installed."
        echo "  Location: $nginx_path"
        return 0
    elif [ -f /usr/local/nginx/sbin/nginx ]; then
        nginx_path="/usr/local/nginx/sbin/nginx"
        print_color "${GREEN}" "✓ Nginx is installed."
        echo "  Location: $nginx_path"
        return 0
    else
        print_color "${RED}" "✗ Nginx does not appear to be installed."
        return 1
    fi
}

# Function to check nginx service status
check_nginx_status() {
    # Try systemctl first (most modern systems)
    if command -v systemctl &> /dev/null; then
        if systemctl is-active --quiet nginx 2>/dev/null; then
            print_color "${GREEN}" "✓ Nginx is running (systemctl)."
            # Get uptime from systemctl
            local uptime
            uptime=$(systemctl show nginx --property=ActiveEnterTimestamp 2>/dev/null | cut -d= -f2)
            if [ -n "$uptime" ]; then
                echo "  Started at: $uptime"
                # Convert to human readable relative time
                local start_sec
                start_sec=$(date -d "$uptime" +%s 2>/dev/null || date -j -f "%a %Y-%m-%d %H:%M:%S %Z" "$uptime" +%s 2>/dev/null || echo "")
                if [ -n "$start_sec" ]; then
                    local now_sec
                    now_sec=$(date +%s)
                    local diff_sec=$((now_sec - start_sec))
                    local days=$((diff_sec / 86400))
                    local hours=$(( (diff_sec % 86400) / 3600 ))
                    local minutes=$(( (diff_sec % 3600) / 60 ))
                    local seconds=$((diff_sec % 60))
                    echo "  Uptime: ${days}d ${hours}h ${minutes}m ${seconds}s"
                fi
            fi
            return 0
        else
            print_color "${YELLOW}" "○ Nginx is stopped (systemctl)."
            return 1
        fi
    # Fallback to checking processes
    elif pgrep nginx &> /dev/null; then
        print_color "${GREEN}" "✓ Nginx is running (process found)."
        # Try to get start time from ps
        local pid
        pid=$(pgrep nginx | head -1)
        if [ -n "$pid" ]; then
            local start_time
            # Try Linux style
            start_time=$(ps -p "$pid" -o lstart= 2>/dev/null || ps -p "$pid" -o stime= 2>/dev/null || echo "")
            if [ -n "$start_time" ]; then
                echo "  Process started: $start_time"
            fi
        fi
        return 0
    else
        print_color "${YELLOW}" "○ Nginx is not running."
        return 1
    fi
}

# Function to display version info
show_nginx_version() {
    if command -v nginx &> /dev/null; then
        local version
        version=$(nginx -v 2>&1 | head -1)
        echo "  Version: $version"
    fi
}

# Main function
main() {
    local command="${1:-}"
    
    if [ "$command" != "status" ]; then
        print_color "${BLUE}" "Usage: $0 status"
        echo "  status   - Check nginx installation and status"
        exit 1
    fi
    
    echo "========================================"
    echo "Nginx Status Check"
    echo "========================================"
    
    # Check installation
    if check_nginx_installed; then
        # Show version
        show_nginx_version
        echo "----------------------------------------"
        # Check running status
        check_nginx_status
    else
        echo "----------------------------------------"
        print_color "${YELLOW}" "No further status to check."
    fi
    
    echo "========================================"
}

# Run main with all arguments
main "$@"
