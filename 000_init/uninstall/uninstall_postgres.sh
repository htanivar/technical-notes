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

# Function to detect OS (minimal detection, mostly for package manager)
detect_os_family() {
    print_message "Detecting system configuration..." "$BLUE"
    
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
    local possible_names=("postgresql" "postgresql-*" "postgres" "pgsql" "postgresql.service" "postgresql@*")
    
    INIT_SYSTEM=$(detect_init_system)
    
    case $INIT_SYSTEM in
        "systemd")
            for name in "${possible_names[@]}"; do
                # Check for exact service name first
                if systemctl list-units --full -all 2>/dev/null | grep -q "^$name\.service"; then
                    echo "$name"
                    return
                fi
                # Check for pattern matching
                if systemctl list-units --full -all 2>/dev/null | grep -q "$name"; then
                    systemctl list-units --full -all 2>/dev/null | grep "$name" | head -1 | awk '{print $1}' | sed 's/\.service//'
                    return
                fi
            done
            ;;
        "sysvinit"|"openrc")
            for name in "${possible_names[@]}"; do
                if [[ -f "/etc/init.d/$name" ]] || [[ -f "/etc/init.d/${name%\*}" ]]; then
                    echo "$name" | sed 's/\*//'
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
            sudo systemctl mask "$service_name" 2>/dev/null || true
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
            sudo initctl stop "$service_name" 2>/dev/null || true
            echo "manual" | sudo tee "/etc/init/$service_name.override" >/dev/null 2>&1 || true
            ;;
        *)
            print_message "Unknown init system. Attempting to kill PostgreSQL processes..." "$YELLOW"
            sudo pkill -u postgres 2>/dev/null || true
            sudo pkill postgres 2>/dev/null || true
            ;;
    esac
}

# Function to find PostgreSQL files and directories
find_postgres_files() {
    print_message "Locating PostgreSQL files and directories..." "$BLUE"
    
    # Common PostgreSQL locations
    local locations=(
        "/etc/postgresql"
        "/var/lib/postgresql"
        "/var/lib/pgsql"
        "/var/log/postgresql"
        "/var/log/pgsql"
        "/usr/lib/postgresql"
        "/usr/pgsql-*"
        "/usr/local/pgsql"
        "/opt/postgresql"
        "/home/*/.psql*"
        "/root/.psql*"
    )
    
    for location in "${locations[@]}"; do
        if ls $location 2>/dev/null; then
            echo "$location"
        fi
    done
    
    # Find PostgreSQL configuration files
    find /etc -name "postgresql.conf" -o -name "pg_hba.conf" 2>/dev/null || true
}

# Function to uninstall PostgreSQL on Linux (dynamic approach)
uninstall_linux() {
    local os_family=$1
    print_message "\nUninstalling PostgreSQL from Linux ($os_family)..." "$YELLOW"
    
    # Detect and stop PostgreSQL service
    PG_SERVICE=$(detect_postgres_service)
    if [[ "$PG_SERVICE" != "unknown" ]]; then
        print_message "Found PostgreSQL service: $PG_SERVICE" "$GREEN"
        stop_service "$PG_SERVICE"
    else
        print_message "Could not detect PostgreSQL service. Attempting to stop any PostgreSQL processes..." "$YELLOW"
        sudo pkill -u postgres 2>/dev/null || true
        sudo pkill postgres 2>/dev/null || true
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
            else
                # Try common patterns
                sudo apt-get remove --purge -y postgresql postgresql-* postgresql-client-* postgresql-common postgresql-contrib* 2>/dev/null || true
            fi
            sudo apt-get autoremove -y
            sudo apt-get autoclean
            ;;
            
        "rhel-family"|"fedora-family")
            print_message "Using yum/dnf package manager..." "$BLUE"
            if command -v dnf &> /dev/null; then
                PKG_MGR="dnf"
            else
                PKG_MGR="yum"
            fi
            
            # Find all PostgreSQL packages
            PG_PACKAGES=$(rpm -qa | grep -i postgres | tr '\n' ' ')
            if [[ -n "$PG_PACKAGES" ]]; then
                print_message "Found PostgreSQL packages: $PG_PACKAGES" "$BLUE"
                sudo $PKG_MGR remove -y $PG_PACKAGES
            else
                sudo $PKG_MGR remove -y postgresql* postgresql-server* 2>/dev/null || true
            fi
            sudo $PKG_MGR autoremove -y
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
    
    # Remove PostgreSQL directories
    print_message "Removing PostgreSQL directories..." "$BLUE"
    POSTGRES_DIRS=$(find_postgres_files)
    for dir in $POSTGRES_DIRS; do
        if [[ -e "$dir" ]]; then
            print_message "Removing: $dir" "$YELLOW"
            sudo rm -rf "$dir" 2>/dev/null || true
        fi
    done
    
    # Remove PostgreSQL user and group
    print_message "Removing PostgreSQL user and group..." "$BLUE"
    if id postgres &>/dev/null; then
        sudo userdel -r postgres 2>/dev/null || true
    fi
    if getent group postgres &>/dev/null; then
        sudo groupdel postgres 2>/dev/null || true
    fi
    
    # Clean up PostgreSQL from PATH and environment
    print_message "Cleaning up environment..." "$BLUE"
    if [[ -f /etc/profile.d/postgresql.sh ]]; then
        sudo rm -f /etc/profile.d/postgresql.sh
    fi
    
    # Remove PostgreSQL repository files
    find /etc/apt/sources.list.d /etc/yum.repos.d -name "*postgres*" -exec sudo rm -f {} \; 2>/dev/null || true
    
    print_message "PostgreSQL has been completely removed from Linux!" "$GREEN"
}

# Function to uninstall PostgreSQL on Windows (Git Bash)
uninstall_windows() {
    print_message "\nUninstalling PostgreSQL from Windows (Git Bash)..." "$YELLOW"
    
    # Check if PostgreSQL is installed via Chocolatey
    if command -v choco &> /dev/null; then
        if choco list --local-only | grep -i postgres &> /dev/null; then
            print_message "PostgreSQL installation detected via Chocolatey..." "$BLUE"
            read -p "Do you want to uninstall PostgreSQL via Chocolatey? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                choco uninstall postgresql -y
                print_message "PostgreSQL uninstalled via Chocolatey!" "$GREEN"
            fi
        fi
    fi
    
    # Check common PostgreSQL installation paths
    POSTGRES_PATHS=(
        "/c/Program Files/PostgreSQL"
        "/c/Program Files (x86)/PostgreSQL"
        "/c/PostgreSQL"
    )
    
    for path in "${POSTGRES_PATHS[@]}"; do
        if [[ -d "$path" ]]; then
            print_message "Found PostgreSQL installation at: $path" "$BLUE"
            read -p "Do you want to remove this directory? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                # Use Windows commands for better permission handling
                if command -v cmd &> /dev/null; then
                    cmd //c "rmdir /s /q \"${path//\//\\}\"" 2>/dev/null || true
                else
                    rm -rf "$path"
                fi
                print_message "Removed: $path" "$GREEN"
            fi
        fi
    done
    
    # Check for PostgreSQL in PATH
    if command -v psql &> /dev/null; then
        print_message "PostgreSQL commands are still in PATH." "$YELLOW"
        print_message "You may need to manually remove PostgreSQL from your system PATH." "$YELLOW"
    fi
    
    # Check for PostgreSQL service using various methods
    if command -v sc &> /dev/null; then
        for service in "postgresql" "postgresql-*" "pgsql"; do
            if sc query "$service" &> /dev/null 2>&1; then
                print_message "PostgreSQL Windows service '$service' detected." "$YELLOW"
                read -p "Do you want to remove this service? (y/n): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    sc stop "$service" || true
                    sc delete "$service" || true
                    print_message "PostgreSQL service '$service' removed!" "$GREEN"
                fi
            fi
        done
    fi
    
    # Check for PostgreSQL in registry
    if command -v reg &> /dev/null; then
        if reg query "HKLM\SOFTWARE\PostgreSQL" &> /dev/null 2>&1; then
            print_message "PostgreSQL registry entries found." "$YELLOW"
            read -p "Do you want to remove PostgreSQL registry entries? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                reg delete "HKLM\SOFTWARE\PostgreSQL" /f || true
                print_message "PostgreSQL registry entries removed!" "$GREEN"
            fi
        fi
    fi
    
    # Check for PostgreSQL in Windows Features
    if command -v dism &> /dev/null; then
        if dism /online /get-features | grep -i postgres &> /dev/null; then
            print_message "PostgreSQL might be installed as a Windows Feature." "$YELLOW"
            print_message "Please check Windows Features in Control Panel." "$YELLOW"
        fi
    fi
    
    print_message "PostgreSQL uninstallation process completed on Windows!" "$GREEN"
    print_message "Note: Some components may need to be removed manually from Control Panel." "$YELLOW"
}

# Function to handle unknown systems
handle_unknown() {
    print_message "\nUnknown system configuration detected!" "$RED"
    print_message "This script attempts to be distribution-agnostic but couldn't detect your system." "$YELLOW"
    
    # Try to find PostgreSQL manually
    print_message "\nSearching for PostgreSQL installations..." "$BLUE"
    
    # Find PostgreSQL binaries
    PG_BINS=$(which psql 2>/dev/null || find /usr /opt /usr/local -name psql -type f 2>/dev/null | head -5)
    if [[ -n "$PG_BINS" ]]; then
        print_message "Found PostgreSQL binaries at:" "$GREEN"
        echo "$PG_BINS"
    fi
    
    # Find PostgreSQL directories
    PG_DIRS=$(find /etc /var/lib /usr /opt -name "*postgres*" -type d 2>/dev/null | head -10)
    if [[ -n "$PG_DIRS" ]]; then
        print_message "Found PostgreSQL directories at:" "$GREEN"
        echo "$PG_DIRS"
    fi
    
    print_message "\nWould you like to attempt force removal?" "$YELLOW"
    read -p "Force remove any PostgreSQL components found? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Kill PostgreSQL processes
        sudo pkill -f postgres 2>/dev/null || true
        sudo pkill -f psql 2>/dev/null || true
        
        # Remove common PostgreSQL directories
        sudo rm -rf /etc/postgresql /var/lib/postgresql /var/log/postgresql /usr/lib/postgresql 2>/dev/null || true
        
        # Remove user if exists
        sudo userdel -r postgres 2>/dev/null || true
        
        print_message "Force removal completed. Some components may remain." "$GREEN"
    else
        exit 1
    fi
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
    print_message "\nThis script will completely remove PostgreSQL from your system." "$YELLOW"
    read -p "Are you sure you want to continue? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message "Uninstallation cancelled." "$RED"
        exit 0
    fi
    
    # Detect and handle OS family
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
            handle_unknown
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
    
    if id postgres &>/dev/null; then
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
