#!/bin/bash

# System Health Check Script
# Supports: Linux (various distros) and Windows (via WSL/Git Bash)
# Author: System Admin
# Version: 1.0

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
}

# Function to print info with colors
print_info() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Detect Operating System
detect_os() {
    print_header "SYSTEM INFORMATION"

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux detection
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS_NAME=$NAME
            OS_VERSION=$VERSION_ID
            echo -e "Operating System: ${GREEN}$OS_NAME $OS_VERSION${NC}"
        elif [ -f /etc/redhat-release ]; then
            OS_NAME=$(cat /etc/redhat-release)
            echo -e "Operating System: ${GREEN}$OS_NAME${NC}"
        else
            echo -e "Operating System: ${GREEN}Linux (Unknown Distro)${NC}"
        fi
        OS_TYPE="linux"

    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        OS_NAME="macOS"
        OS_VERSION=$(sw_vers -productVersion)
        echo -e "Operating System: ${GREEN}$OS_NAME $OS_VERSION${NC}"
        OS_TYPE="macos"

    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        # Windows (Cygwin, Git Bash, or WSL)
        OS_NAME="Windows"
        if [[ -n "$WSL_DISTRO_NAME" ]]; then
            OS_NAME="Windows (WSL: $WSL_DISTRO_NAME)"
        fi
        echo -e "Operating System: ${GREEN}$OS_NAME${NC}"
        OS_TYPE="windows"
    else
        echo -e "Operating System: ${YELLOW}Unknown${NC}"
        OS_TYPE="unknown"
    fi

    # Hostname and Kernel
    echo -e "Hostname: ${CYAN}$(hostname)${NC}"
    echo -e "Kernel: ${CYAN}$(uname -r)${NC}"
    echo -e "Architecture: ${CYAN}$(uname -m)${NC}"
}

# CPU Information
check_cpu() {
    print_header "CPU INFORMATION"

    if [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "macos" ]]; then
        # CPU Model
        if [[ "$OS_TYPE" == "linux" ]]; then
            CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | sed 's/^[ \t]*//')
            CPU_CORES=$(grep -c "^processor" /proc/cpuinfo)
            CPU_THREADS=$(grep "siblings" /proc/cpuinfo | head -1 | awk '{print $3}')
            CPU_PHYSICAL=$(grep "physical id" /proc/cpuinfo | sort -u | wc -l)
        elif [[ "$OS_TYPE" == "macos" ]]; then
            CPU_MODEL=$(sysctl -n machdep.cpu.brand_string)
            CPU_CORES=$(sysctl -n hw.physicalcpu)
            CPU_THREADS=$(sysctl -n hw.logicalcpu)
            CPU_PHYSICAL=$CPU_CORES
        fi

        echo -e "CPU Model: ${CYAN}$CPU_MODEL${NC}"
        echo -e "Physical CPUs: ${GREEN}$CPU_PHYSICAL${NC}"
        echo -e "Cores per CPU: ${GREEN}$((CPU_CORES / CPU_PHYSICAL))${NC}"
        echo -e "Total Cores: ${GREEN}$CPU_CORES${NC}"
        echo -e "Total Threads: ${GREEN}$CPU_THREADS${NC}"

        # CPU Usage
        if [[ "$OS_TYPE" == "linux" ]]; then
            CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
            CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d'%' -f1)
            CPU_LOAD=$(uptime | awk -F'load average:' '{print $2}')
        elif [[ "$OS_TYPE" == "macos" ]]; then
            CPU_USAGE=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | cut -d'%' -f1)
            CPU_IDLE=$(top -l 1 | grep "CPU usage" | awk '{print $7}' | cut -d'%' -f1)
            CPU_LOAD=$(uptime | awk -F'load averages:' '{print $2}')
        fi

        echo -e "\nCPU Usage: ${GREEN}$CPU_USAGE%${NC}"
        echo -e "CPU Idle: ${GREEN}$CPU_IDLE%${NC}"
        echo -e "Load Average: ${CYAN}$CPU_LOAD${NC}"

        # CPU Temperature (if available)
        if [[ "$OS_TYPE" == "linux" ]] && [ -f /sys/class/thermal/thermal_zone0/temp ]; then
            CPU_TEMP=$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))
            if [ $CPU_TEMP -gt 80 ]; then
                echo -e "CPU Temperature: ${RED}${CPU_TEMP}°C (High)${NC}"
            elif [ $CPU_TEMP -gt 60 ]; then
                echo -e "CPU Temperature: ${YELLOW}${CPU_TEMP}°C (Moderate)${NC}"
            else
                echo -e "CPU Temperature: ${GREEN}${CPU_TEMP}°C (Normal)${NC}"
            fi
        fi

    elif [[ "$OS_TYPE" == "windows" ]]; then
        # Windows CPU info (via WMI if available)
        if command -v wmic &> /dev/null; then
            CPU_MODEL=$(wmic cpu get name | sed -n '2p' | sed 's/^[ \t]*//')
            CPU_CORES=$(wmic cpu get NumberOfCores | sed -n '2p' | sed 's/^[ \t]*//')
            CPU_THREADS=$(wmic cpu get NumberOfLogicalProcessors | sed -n '2p' | sed 's/^[ \t]*//')
            CPU_LOAD=$(wmic cpu get LoadPercentage | sed -n '2p' | sed 's/^[ \t]*//')

            echo -e "CPU Model: ${CYAN}$CPU_MODEL${NC}"
            echo -e "Total Cores: ${GREEN}$CPU_CORES${NC}"
            echo -e "Total Threads: ${GREEN}$CPU_THREADS${NC}"
            echo -e "CPU Usage: ${GREEN}$CPU_LOAD%${NC}"
        else
            print_warning "Limited CPU info available (install wmic for more details)"
            echo -e "CPU: ${CYAN}$(uname -p)${NC}"
        fi
    fi
}

# Memory Information
check_memory() {
    print_header "MEMORY INFORMATION"

    if [[ "$OS_TYPE" == "linux" ]]; then
        # Linux memory
        MEM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
        MEM_USED=$(free -h | awk '/^Mem:/ {print $3}')
        MEM_FREE=$(free -h | awk '/^Mem:/ {print $4}')
        MEM_AVAILABLE=$(free -h | awk '/^Mem:/ {print $7}')
        MEM_PERCENT=$(free | awk '/^Mem:/ {printf "%.1f", $3/$2 * 100}')

        SWAP_TOTAL=$(free -h | awk '/^Swap:/ {print $2}')
        SWAP_USED=$(free -h | awk '/^Swap:/ {print $3}')
        SWAP_FREE=$(free -h | awk '/^Swap:/ {print $4}')

        echo -e "Memory Total: ${CYAN}$MEM_TOTAL${NC}"

        if [ $(echo "$MEM_PERCENT > 90" | bc) -eq 1 ]; then
            echo -e "Memory Used: ${RED}$MEM_USED ($MEM_PERCENT%)${NC}"
        elif [ $(echo "$MEM_PERCENT > 75" | bc) -eq 1 ]; then
            echo -e "Memory Used: ${YELLOW}$MEM_USED ($MEM_PERCENT%)${NC}"
        else
            echo -e "Memory Used: ${GREEN}$MEM_USED ($MEM_PERCENT%)${NC}"
        fi

        echo -e "Memory Free: ${GREEN}$MEM_FREE${NC}"
        echo -e "Memory Available: ${GREEN}$MEM_AVAILABLE${NC}"
        echo -e "\nSwap Total: ${CYAN}$SWAP_TOTAL${NC}"
        echo -e "Swap Used: ${YELLOW}$SWAP_USED${NC}"
        echo -e "Swap Free: ${GREEN}$SWAP_FREE${NC}"

        # Memory details
        echo -e "\n${PURPLE}Memory Details:${NC}"
        free -h | awk 'NR==1{printf "%-10s %-10s %-10s %-10s\n", $1, $2, $3, $4} NR>1{printf "%-10s %-10s %-10s %-10s\n", $1, $2, $3, $4}'

    elif [[ "$OS_TYPE" == "macos" ]]; then
        # macOS memory
        MEM_TOTAL=$(sysctl -n hw.memsize | awk '{print $0/1073741824 " GB"}')
        MEM_USED=$(vm_stat | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
        MEM_FREE=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
        PAGE_SIZE=$(vm_stat | grep "page size of" | awk '{print $8}')

        MEM_USED_GB=$(echo "scale=2; $MEM_USED * $PAGE_SIZE / 1073741824" | bc)
        MEM_FREE_GB=$(echo "scale=2; $MEM_FREE * $PAGE_SIZE / 1073741824" | bc)

        echo -e "Memory Total: ${CYAN}$MEM_TOTAL${NC}"
        echo -e "Memory Used: ${YELLOW}${MEM_USED_GB}GB${NC}"
        echo -e "Memory Free: ${GREEN}${MEM_FREE_GB}GB${NC}"

    elif [[ "$OS_TYPE" == "windows" ]]; then
        # Windows memory
        if command -v wmic &> /dev/null; then
            MEM_TOTAL=$(wmic computersystem get TotalPhysicalMemory | sed -n '2p' | sed 's/^[ \t]*//')
            MEM_FREE=$(wmic os get FreePhysicalMemory | sed -n '2p' | sed 's/^[ \t]*//')

            MEM_TOTAL_GB=$(echo "scale=2; $MEM_TOTAL / 1073741824" | bc)
            MEM_FREE_GB=$(echo "scale=2; $MEM_FREE * 1024 / 1073741824" | bc)
            MEM_USED_GB=$(echo "scale=2; $MEM_TOTAL_GB - $MEM_FREE_GB" | bc)
            MEM_PERCENT=$(echo "scale=1; $MEM_USED_GB * 100 / $MEM_TOTAL_GB" | bc)

            echo -e "Memory Total: ${CYAN}${MEM_TOTAL_GB}GB${NC}"

            if [ $(echo "$MEM_PERCENT > 90" | bc) -eq 1 ]; then
                echo -e "Memory Used: ${RED}${MEM_USED_GB}GB ($MEM_PERCENT%)${NC}"
            elif [ $(echo "$MEM_PERCENT > 75" | bc) -eq 1 ]; then
                echo -e "Memory Used: ${YELLOW}${MEM_USED_GB}GB ($MEM_PERCENT%)${NC}"
            else
                echo -e "Memory Used: ${GREEN}${MEM_USED_GB}GB ($MEM_PERCENT%)${NC}"
            fi

            echo -e "Memory Free: ${GREEN}${MEM_FREE_GB}GB${NC}"
        else
            print_warning "Limited memory info available (install wmic for more details)"
        fi
    fi
}

# Disk Information
check_disk() {
    print_header "DISK INFORMATION"

    if [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "macos" ]]; then
        echo -e "${PURPLE}Filesystem Usage:${NC}"
        df -h | grep -E '^/dev/' | while read line; do
            FILESYSTEM=$(echo $line | awk '{print $1}')
            SIZE=$(echo $line | awk '{print $2}')
            USED=$(echo $line | awk '{print $3}')
            AVAIL=$(echo $line | awk '{print $4}')
            USE_PERCENT=$(echo $line | awk '{print $5}' | sed 's/%//')
            MOUNT=$(echo $line | awk '{print $6}')

            if [ $USE_PERCENT -gt 90 ]; then
                echo -e "$MOUNT: ${RED}${USED}/${SIZE} (${USE_PERCENT}%)${NC}"
            elif [ $USE_PERCENT -gt 75 ]; then
                echo -e "$MOUNT: ${YELLOW}${USED}/${SIZE} (${USE_PERCENT}%)${NC}"
            else
                echo -e "$MOUNT: ${GREEN}${USED}/${SIZE} (${USE_PERCENT}%)${NC}"
            fi
        done

        # Inode usage (Linux only)
        if [[ "$OS_TYPE" == "linux" ]]; then
            echo -e "\n${PURPLE}Inode Usage:${NC}"
            df -i | grep -E '^/dev/' | while read line; do
                MOUNT=$(echo $line | awk '{print $6}')
                IUSED=$(echo $line | awk '{print $5}' | sed 's/%//')

                if [ $IUSED -gt 90 ]; then
                    echo -e "$MOUNT: ${RED}Inodes: ${IUSED}%${NC}"
                elif [ $IUSED -gt 75 ]; then
                    echo -e "$MOUNT: ${YELLOW}Inodes: ${IUSED}%${NC}"
                else
                    echo -e "$MOUNT: ${GREEN}Inodes: ${IUSED}%${NC}"
                fi
            done
        fi

    elif [[ "$OS_TYPE" == "windows" ]]; then
        if command -v wmic &> /dev/null; then
            echo -e "${PURPLE}Disk Usage:${NC}"
            wmic logicaldisk get deviceid,size,freespace | tail -n +2 | while read line; do
                if [ ! -z "$line" ]; then
                    DRIVE=$(echo $line | awk '{print $1}')
                    FREE=$(echo $line | awk '{print $2}')
                    TOTAL=$(echo $line | awk '{print $3}')

                    if [[ $TOTAL =~ ^[0-9]+$ ]] && [[ $FREE =~ ^[0-9]+$ ]]; then
                        TOTAL_GB=$(echo "scale=2; $TOTAL / 1073741824" | bc)
                        FREE_GB=$(echo "scale=2; $FREE / 1073741824" | bc)
                        USED_GB=$(echo "scale=2; $TOTAL_GB - $FREE_GB" | bc)
                        USE_PERCENT=$(echo "scale=1; $USED_GB * 100 / $TOTAL_GB" | bc)

                        if [ $(echo "$USE_PERCENT > 90" | bc) -eq 1 ]; then
                            echo -e "$DRIVE: ${RED}${USED_GB}GB/${TOTAL_GB}GB (${USE_PERCENT}%)${NC}"
                        elif [ $(echo "$USE_PERCENT > 75" | bc) -eq 1 ]; then
                            echo -e "$DRIVE: ${YELLOW}${USED_GB}GB/${TOTAL_GB}GB (${USE_PERCENT}%)${NC}"
                        else
                            echo -e "$DRIVE: ${GREEN}${USED_GB}GB/${TOTAL_GB}GB (${USE_PERCENT}%)${NC}"
                        fi
                    fi
                fi
            done
        else
            print_warning "Limited disk info available (install wmic for more details)"
            df -h 2>/dev/null || print_error "No disk information available"
        fi
    fi
}

# Network Information
check_network() {
    print_header "NETWORK INFORMATION"

    if [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "macos" ]]; then
        # Network interfaces
        echo -e "${PURPLE}Network Interfaces:${NC}"
        if [[ "$OS_TYPE" == "linux" ]]; then
            ip -br addr show 2>/dev/null | while read line; do
                INTERFACE=$(echo $line | awk '{print $1}')
                IP=$(echo $line | awk '{print $3}')
                if [ ! -z "$IP" ]; then
                    echo -e "$INTERFACE: ${CYAN}$IP${NC}"
                fi
            done
        elif [[ "$OS_TYPE" == "macos" ]]; then
            ifconfig | grep -E '^[a-z]' | while read line; do
                INTERFACE=$(echo $line | cut -d':' -f1)
                IP=$(ifconfig $INTERFACE 2>/dev/null | grep 'inet ' | awk '{print $2}')
                if [ ! -z "$IP" ]; then
                    echo -e "$INTERFACE: ${CYAN}$IP${NC}"
                fi
            done
        fi

        # Connection test
        echo -e "\n${PURPLE}Connectivity:${NC}"
        if ping -c 1 8.8.8.8 &> /dev/null; then
            print_info "Internet connection: Available"
        else
            print_warning "Internet connection: Unavailable"
        fi

    elif [[ "$OS_TYPE" == "windows" ]]; then
        if command -v ipconfig &> /dev/null; then
            echo -e "${PURPLE}Network Interfaces:${NC}"
            ipconfig | grep -A 10 "Ethernet adapter" | grep -E "IPv4 Address|Subnet Mask" | sed 's/^[ \t]*//'
        fi

        echo -e "\n${PURPLE}Connectivity:${NC}"
        if ping -n 1 8.8.8.8 &> /dev/null; then
            print_info "Internet connection: Available"
        else
            print_warning "Internet connection: Unavailable"
        fi
    fi
}

# Process Information
check_processes() {
    print_header "PROCESS INFORMATION"

    if [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "macos" ]]; then
        TOTAL_PROCESSES=$(ps aux | wc -l)
        RUNNING_PROCESSES=$(ps aux | grep -c "R")
        SLEEPING_PROCESSES=$(ps aux | grep -c "S")
        ZOMBIE_PROCESSES=$(ps aux | grep -c "Z")

        echo -e "Total Processes: ${CYAN}$TOTAL_PROCESSES${NC}"
        echo -e "Running: ${GREEN}$RUNNING_PROCESSES${NC}"
        echo -e "Sleeping: ${GREEN}$SLEEPING_PROCESSES${NC}"

        if [ $ZOMBIE_PROCESSES -gt 0 ]; then
            echo -e "Zombie: ${RED}$ZOMBIE_PROCESSES${NC}"
        else
            echo -e "Zombie: ${GREEN}$ZOMBIE_PROCESSES${NC}"
        fi

        # Top 5 CPU consuming processes
        echo -e "\n${PURPLE}Top 5 CPU Consuming Processes:${NC}"
        ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "%-10s %-10s %-10s %s\n", $1, $2, $3, $11}'

        # Top 5 Memory consuming processes
        echo -e "\n${PURPLE}Top 5 Memory Consuming Processes:${NC}"
        ps aux --sort=-%mem | head -6 | tail -5 | awk '{printf "%-10s %-10s %-10s %s\n", $1, $2, $4, $11}'

    elif [[ "$OS_TYPE" == "windows" ]]; then
        if command -v tasklist &> /dev/null; then
            TOTAL_PROCESSES=$(tasklist | wc -l)
            echo -e "Total Processes: ${CYAN}$((TOTAL_PROCESSES - 2))${NC}"

            echo -e "\n${PURPLE}Top 5 Memory Consuming Processes:${NC}"
            tasklist | sort -r -k 5 | head -5 | awk '{print $1, $5}'
        fi
    fi
}

# System Uptime and Users
check_system_info() {
    print_header "SYSTEM HEALTH SUMMARY"

    # Uptime
    UPTIME=$(uptime | sed 's/.*up \([^,]*\),.*/\1/')
    echo -e "System Uptime: ${CYAN}$UPTIME${NC}"

    # Logged in users
    if [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "macos" ]]; then
        USERS=$(who | wc -l)
        echo -e "Logged in Users: ${CYAN}$USERS${NC}"

        # Last login
        echo -e "\n${PURPLE}Last 3 Logins:${NC}"
        last -3 2>/dev/null | head -3
    fi

    # System date
    echo -e "\nSystem Date/Time: ${CYAN}$(date)${NC}"
}

# Main execution
main() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                SYSTEM HEALTH CHECK REPORT                       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "Generated on: ${CYAN}$(date)${NC}\n"

    # Run all checks
    detect_os
    check_cpu
    check_memory
    check_disk
    check_network
    check_processes
    check_system_info

    # Summary
    print_header "HEALTH SUMMARY"

    # Overall health assessment (simple version)
    HEALTHY=true

    # Check if any critical issues were found (simplified)
    if [[ "$OS_TYPE" == "linux" ]]; then
        # Check memory usage
        MEM_PERCENT=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')
        if [ $MEM_PERCENT -gt 90 ]; then
            HEALTHY=false
            print_error "High memory usage detected: $MEM_PERCENT%"
        fi

        # Check disk usage
        df -h | grep -E '^/dev/' | awk '{print $5}' | sed 's/%//' | while read percent; do
            if [ $percent -gt 90 ]; then
                HEALTHY=false
                print_error "High disk usage detected on some partitions"
            fi
        done

        # Check for zombie processes
        ZOMBIES=$(ps aux | grep -c "Z")
        if [ $ZOMBIES -gt 0 ]; then
            HEALTHY=false
            print_error "Zombie processes found: $ZOMBIES"
        fi
    fi

    if [ "$HEALTHY" = true ]; then
        print_info "System health: ${GREEN}GOOD${NC}"
    else
        print_warning "System health: ${YELLOW}ISSUES DETECTED${NC}"
    fi

    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Report completed at: $(date)${NC}"
}

# Run the main function
main