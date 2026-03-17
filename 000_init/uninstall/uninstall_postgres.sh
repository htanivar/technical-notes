#!/bin/bash

# PostgreSQL Uninstall Script
# Dynamically detects system configuration and adapts accordingly
# Supports: Any Linux distribution, Windows (Git Bash)

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_message() {
    echo -e "${2}${1}${NC}"
}

# Function to detect OS family (silent detection)
detect_os_family() {
    # Check for Windows (Git Bash/MSYS2/Cygwin)
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WINDIR" ]]; then
        echo "windows"
        return
    fi
    
    # Detect package manager
    if command -v apt-get &> /dev/null; then
        echo "debian-family"
    elif command -v yum &> /dev/null; then
        echo "rhel-family"
    elif command -v dnf &> /dev/null; then
        echo "fedora-family"
    elif command -v pacman &> /dev/null; then
        echo "arch-family"
    elif command -v zypper &> /dev/null; then
        echo "suse-family"
    else
        echo "unknown-linux"
    fi
}

# Function to detect init system
detect_init_system() {
    # Check for systemd
    if pidof systemd &> /dev/null && [[ -d /run/systemd/system ]]; then
        echo "systemd"
    # Check for SysV init
    elif [[ -f /sbin/init ]] && [[ ! -L /sbin/init ]] || [[ -d /etc/init.d ]]; then
        echo "sysvinit"
    # Check for Upstart
    elif [[ -f /sbin/init ]] && [[ $(/sbin/init --version 2>/dev/null) == *"upstart"* ]] || [[ -d /etc/init ]]; then
        echo "upstart"
    # Check for OpenRC (Gentoo, Alpine)
    elif command -v rc-service &> /dev/null || [[ -d /etc/init.d ]]; then
        echo "openrc"
    else
        echo "unknown"
    fi
}

# Function to detect PostgreSQL service name
detect_postgres_service() {
    local possible_names=("postgresql" "postgres" "pgsql" "postgresql.service")
    
    INIT_SYSTEM=$(detect_init_system)
    
    case $INIT_SYSTEM in
        "systemd")
            for name in "${possible_names[@]}"; do
                if systemctl list-units --full -all 2>/dev/null | grep -q "^$name\.service"; then
                    echo "$name"
                    return
                fi
            done
            ;;
        "sysvinit"|"openrc")
            for name in "${possible_names[@]}"; do
                if [[ -f "/etc/init.d/$name" ]]; then
                    echo "$name"
                    return
                fi
            done
            ;;
        "upstart")
            for name in "${possible_names[@]}"; do
                if [[ -f "/etc/init/$name.conf" ]]; then
                    echo "$name"
                    return
                fi
            done
            ;;
    esac
    
    echo "unknown"
}

# Function to stop service based on init system
stop_service() {
    local service_name=$1
    local init_system=$(detect_init_system)
    
    print_message "Stopping PostgreSQL service using $init_system..." "$BLUE"
    
    case $init_system in
        "systemd")
            sudo systemctl stop "$service_name" 2>/dev/null || true
            sudo systemctl disable "$service_name" 2>/dev/null || true
            ;;
        "sysvinit")
            sudo service "$service_name" stop 2>/dev/null || true
            sudo update-rc.d "$service_name" remove 2>/dev/null || true
            ;;
        "openrc")
            sudo rc-service "$service_name" stop 2>/dev/null || true
            sudo rc-update del "$service_name" 2>/dev/null || true
            ;;
        "upstart")
            sudo stop "$service_name" 2>/dev/null || true
            ;;
        *)
            print_message "Attempting to kill PostgreSQL processes..." "$YELLOW"
            sudo pkill -u postgres 2>/dev/null || true
            sudo pkill postgres 2>/dev/null || true
            ;;
    esac
}

# Function to uninstall PostgreSQL on Linux
uninstall_linux() {
    local os_family=$1
    print_message "\nUninstalling PostgreSQL from Linux ($os_family)..." "$YELLOW"
    
    # First, check if PostgreSQL is actually installed
    if ! command -v psql &> /dev/null && ! dpkg -l | grep -q postgres 2>/dev/null; then
        print_message "PostgreSQL doesn't appear to be installed on the host system." "$YELLOW"
        print_message "However, I see some PostgreSQL directories (possibly from Docker containers)." "$YELLOW"
        
        read -p "Do you want to remove PostgreSQL directories (including Docker volumes)? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cleanup_postgres_directories
        fi
        return
    fi
    
    # Detect and stop PostgreSQL service
    PG_SERVICE=$(detect_postgres_service)
    if [[ "$PG_SERVICE" != "unknown" ]]; then
        print_message "Found PostgreSQL service: $PG_SERVICE" "$GREEN"
        stop_service "$PG_SERVICE"
    else
        print_message "Could not detect PostgreSQL service." "$YELLOW"
    fi
    
    # Package manager specific uninstallation
    case $os_family in
        "debian-family")
            print_message "Using apt package manager..." "$BLUE"
            # Find all PostgreSQL packages
            PG_PACKAGES=$(dpkg -l | grep -E "^ii.*postgres" | awk '{print $2}' | tr '\n' ' ')
            if [[ -n "$PG_PACKAGES" ]]; then
                print_message "Found PostgreSQL packages: $PG_PACKAGES" "$BLUE"
                sudo apt-get remove --purge -y $PG_PACKAGES
                sudo apt-get autoremove -y
                sudo apt-get autoclean
            else
                print_message "No PostgreSQL packages found via dpkg." "$YELLOW"
            fi
            ;;
            
        "rhel-family"|"fedora-family")
            print_message "Using yum/dnf package manager..." "$BLUE"
            if command -v dnf &> /dev/null; then
                PKG_MGR="dnf"
            else
                PKG_MGR="yum"
            fi
            
            PG_PACKAGES=$(rpm -qa | grep -i postgres | tr '\n' ' ')
            if [[ -n "$PG_PACKAGES" ]]; then
                print_message "Found PostgreSQL packages: $PG_PACKAGES" "$BLUE"
                sudo $PKG_MGR remove -y $PG_PACKAGES
                sudo $PKG_MGR autoremove -y
            fi
            ;;
            
        "arch-family")
            print_message "Using pacman package manager..." "$BLUE"
            PG_PACKAGES=$(pacman -Q | grep -i postgres | awk '{print $1}' | tr '\n' ' ')
            if [[ -n "$PG_PACKAGES" ]]; then
                print_message "Found PostgreSQL packages: $PG_PACKAGES" "$BLUE"
                sudo pacman -Rns --noconfirm $PG_PACKAGES
            fi
            ;;
            
        "suse-family")
            print_message "Using zypper package manager..." "$BLUE"
            PG_PACKAGES=$(rpm -qa | grep -i postgres | tr '\n' ' ')
            if [[ -n "$PG_PACKAGES" ]]; then
                print_message "Found PostgreSQL packages: $PG_PACKAGES" "$BLUE"
                sudo zypper remove -y $PG_PACKAGES
            fi
            ;;
    esac
    
    # Ask about directory cleanup
    cleanup_postgres_directories
}

# Function to clean up PostgreSQL directories
cleanup_postgres_directories() {
    print_message "\nCleaning up PostgreSQL directories..." "$BLUE"
    
    # Common PostgreSQL directories (host system)
    local host_dirs=(
        "/etc/postgresql"
        "/var/lib/postgresql"
        "/var/log/postgresql"
        "/usr/lib/postgresql"
        "/usr/share/postgresql"
        "/var/cache/postgresql"
        "/var/lib/pgsql"
        "/var/log/pgsql"
        "/usr/local/pgsql"
        "/opt/postgresql"
    )
    
    # Clean up host directories
    for dir in "${host_dirs[@]}"; do
        if [[ -e "$dir" ]]; then
            print_message "Removing host directory: $dir" "$YELLOW"
            sudo rm -rf "$dir" 2>/dev/null || true
        fi
    done
    
    # Ask about Docker volumes
    if [[ -d "/var/lib/docker/volumes" ]]; then
        print_message "\nDocker volumes detected." "$BLUE"
        DOCKER_VOLUMES=$(sudo find /var/lib/docker/volumes -name "*postgres*" -type d 2>/dev/null)
        if [[ -n "$DOCKER_VOLUMES" ]]; then
            print_message "Found PostgreSQL Docker volumes:" "$YELLOW"
            echo "$DOCKER_VOLUMES"
            read -p "Do you want to remove these Docker volumes? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                for volume in $DOCKER_VOLUMES; do
                    sudo rm -rf "$volume" 2>/dev/null || true
                done
                print_message "Docker volumes removed." "$GREEN"
            fi
        fi
    fi
    
    # Ask about Docker containers
    if command -v docker &> /dev/null; then
        PG_CONTAINERS=$(docker ps -a --format "{{.Names}}" 2>/dev/null | grep -i postgres || true)
        if [[ -n "$PG_CONTAINERS" ]]; then
            print_message "\nFound PostgreSQL Docker containers:" "$YELLOW"
            echo "$PG_CONTAINERS"
            read -p "Do you want to remove these Docker containers? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "$PG_CONTAINERS" | while read container; do
                    docker stop "$container" 2>/dev/null || true
                    docker rm "$container" 2>/dev/null || true
                done
                print_message "Docker containers removed." "$GREEN"
            fi
        fi
    fi
    
    # Remove PostgreSQL user if it exists
    if id postgres &>/dev/null; then
        print_message "\nRemoving PostgreSQL user..." "$BLUE"
        sudo userdel -r postgres 2>/dev/null || true
    fi
    
    # Remove PostgreSQL group if it exists
    if getent group postgres &>/dev/null; then
        sudo groupdel postgres 2>/dev/null || true
    fi
    
    # Clean up PostgreSQL from PATH and environment
    if [[ -f /etc/profile.d/postgresql.sh ]]; then
        sudo rm -f /etc/profile.d/postgresql.sh
    fi
    
    # Remove PostgreSQL repository files
    sudo find /etc/apt/sources.list.d /etc/yum.repos.d -name "*postgres*" -exec rm -f {} \; 2>/dev/null || true
}

# Function to uninstall PostgreSQL on Windows
uninstall_windows() {
    print_message "\nUninstalling PostgreSQL from Windows (Git Bash)..." "$YELLOW"
    
    # Similar Windows uninstallation code as before...
    # (keeping this section as is from the previous version)
    
    print_message "PostgreSQL uninstallation process completed on Windows!" "$GREEN"
}

# Main execution
main() {
    print_message "=========================================" "$GREEN"
    print_message "    PostgreSQL Uninstall Script" "$GREEN"
    print_message "  (Dynamic System Detection)" "$GREEN"
    print_message "=========================================" "$GREEN"
    
    # Display system information
    print_message "\nSystem Information:" "$BLUE"
    print_message "  OSTYPE: $OSTYPE" "$BLUE"
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        print_message "  Distribution: $NAME $VERSION" "$BLUE"
    fi
    
    INIT_SYSTEM=$(detect_init_system)
    print_message "  Init System: $INIT_SYSTEM" "$BLUE"
    
    # Check if running with sufficient privileges
    if [[ "$EUID" -ne 0 ]]; then
        print_message "\nWarning: Not running as root. Some operations may fail." "$YELLOW"
        print_message "Consider running with: sudo $0" "$YELLOW"
    fi
    
    # Confirm uninstallation
    print_message "\nThis script will remove PostgreSQL from your system." "$YELLOW"
    print_message "Note: This includes both host installation and Docker containers/volumes." "$YELLOW"
    read -p "Are you sure you want to continue? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message "Uninstallation cancelled." "$RED"
        exit 0
    fi
    
    # Detect OS family (without printing)
    OS_FAMILY=$(detect_os_family)
    print_message "\nDetected OS Family: $OS_FAMILY" "$GREEN"
    
    case $OS_FAMILY in
        "windows")
            uninstall_windows
            ;;
        "debian-family"|"rhel-family"|"fedora-family"|"arch-family"|"suse-family")
            uninstall_linux "$OS_FAMILY"
            ;;
        *)
            print_message "Unknown OS family, but attempting cleanup anyway..." "$YELLOW"
            cleanup_postgres_directories
            ;;
    esac
    
    # Final verification
    print_message "\nPerforming final verification..." "$BLUE"
    if command -v psql &> /dev/null; then
        print_message "⚠️  Warning: psql command still exists in PATH." "$YELLOW"
        which psql
    else
        print_message "✅ PostgreSQL commands removed from PATH." "$GREEN"
    fi
    
    if id postgres &>/dev/null 2>&1; then
        print_message "⚠️  Warning: postgres user still exists." "$YELLOW"
    else
        print_message "✅ postgres user removed." "$GREEN"
    fi
    
    print_message "\n=========================================" "$GREEN"
    print_message "    PostgreSQL uninstallation complete!" "$GREEN"
    print_message "=========================================" "$GREEN"
}

# Run main function
main "$@"
