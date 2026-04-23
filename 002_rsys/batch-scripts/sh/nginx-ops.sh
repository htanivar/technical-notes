#!/usr/bin/env bash

# nginx-ops.sh - Nginx operations script
# Usage: sudo ./nginx-ops.sh [status|start|stop|restart|help]

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color="$1"
    local msg="$2"
    echo -e "${color}${msg}${NC}"
}

# Function to display help
show_help() {
    cat << EOF
$(print_color "${CYAN}" "nginx-ops.sh - Nginx Operations Script")
$(print_color "${BLUE}" "Usage: sudo $0 [command]")

Commands:
  status    Check if nginx is installed, its location, and running status
  start     Start nginx service (requires sudo)
  stop      Stop nginx service (requires sudo)
  restart   Restart nginx service (requires sudo)
  help      Show this help message

Examples:
  $0 status
  sudo $0 start
  sudo $0 restart
EOF
}

# Function to check if running with sufficient privileges
check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        print_color "${RED}" "This operation requires sudo privileges."
        print_color "${YELLOW}" "Please run with: sudo $0 $1"
        exit 1
    fi
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

# Function to start nginx
start_nginx() {
    print_color "${BLUE}" "Starting nginx..."
    if command -v systemctl &> /dev/null; then
        if systemctl start nginx; then
            print_color "${GREEN}" "✓ Nginx started successfully via systemctl."
        else
            print_color "${RED}" "✗ Failed to start nginx via systemctl."
            exit 1
        fi
    elif command -v service &> /dev/null; then
        if service nginx start; then
            print_color "${GREEN}" "✓ Nginx started successfully via service."
        else
            print_color "${RED}" "✗ Failed to start nginx via service."
            exit 1
        fi
    else
        # Try direct nginx binary
        if nginx &> /dev/null; then
            print_color "${GREEN}" "✓ Nginx started via direct binary."
        else
            print_color "${RED}" "✗ Failed to start nginx directly."
            exit 1
        fi
    fi
}

# Function to stop nginx
stop_nginx() {
    print_color "${BLUE}" "Stopping nginx..."
    if command -v systemctl &> /dev/null; then
        if systemctl stop nginx; then
            print_color "${GREEN}" "✓ Nginx stopped successfully via systemctl."
        else
            print_color "${RED}" "✗ Failed to stop nginx via systemctl."
            exit 1
        fi
    elif command -v service &> /dev/null; then
        if service nginx stop; then
            print_color "${GREEN}" "✓ Nginx stopped successfully via service."
        else
            print_color "${RED}" "✗ Failed to stop nginx via service."
            exit 1
        fi
    else
        # Try to kill nginx processes
        if pkill nginx; then
            print_color "${GREEN}" "✓ Nginx processes terminated."
        else
            print_color "${RED}" "✗ No nginx processes found or failed to kill."
            exit 1
        fi
    fi
}

# Function to restart nginx
restart_nginx() {
    print_color "${BLUE}" "Restarting nginx..."
    if command -v systemctl &> /dev/null; then
        if systemctl restart nginx; then
            print_color "${GREEN}" "✓ Nginx restarted successfully via systemctl."
        else
            print_color "${RED}" "✗ Failed to restart nginx via systemctl."
            exit 1
        fi
    elif command -v service &> /dev/null; then
        if service nginx restart; then
            print_color "${GREEN}" "✓ Nginx restarted successfully via service."
        else
            print_color "${RED}" "✗ Failed to restart nginx via service."
            exit 1
        fi
    else
        # Try to stop and start
        stop_nginx
        sleep 2
        start_nginx
    fi
}

# Main function
main() {
    local command="${1:-help}"
    
    case "$command" in
        status)
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
            ;;
        start)
            check_privileges "start"
            if ! check_nginx_installed; then
                exit 1
            fi
            start_nginx
            ;;
        stop)
            check_privileges "stop"
            if ! check_nginx_installed; then
                exit 1
            fi
            stop_nginx
            ;;
        restart)
            check_privileges "restart"
            if ! check_nginx_installed; then
                exit 1
            fi
            restart_nginx
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_color "${RED}" "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main with all arguments
main "$@"
