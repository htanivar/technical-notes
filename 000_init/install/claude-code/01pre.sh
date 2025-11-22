#!/bin/bash

# Claude Code System Requirements Checker
# For MX Linux and other Linux distributions

echo "========================================="
echo "  Claude Code System Requirements Check"
echo "========================================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    local status=$1
    local message=$2
    case $status in
        "PASS")
            echo -e "${GREEN}✓ PASS${NC}: $message"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠ WARN${NC}: $message"
            ;;
        "FAIL")
            echo -e "${RED}✗ FAIL${NC}: $message"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ INFO${NC}: $message"
            ;;
    esac
}

echo "1. SYSTEM INFORMATION"
echo "====================="
print_status "INFO" "OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo "$(uname -s) $(uname -r)")"
print_status "INFO" "Architecture: $(uname -m)"
print_status "INFO" "Kernel: $(uname -r)"
echo

echo "2. CPU CHECK"
echo "============"
cpu_cores=$(nproc)
cpu_model=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
print_status "INFO" "CPU: $cpu_model"
print_status "INFO" "CPU Cores: $cpu_cores"

if [ "$cpu_cores" -ge 4 ]; then
    print_status "PASS" "CPU cores ($cpu_cores) meet recommended requirement (4+)"
elif [ "$cpu_cores" -ge 2 ]; then
    print_status "WARN" "CPU cores ($cpu_cores) meet minimum but recommend 4+ for better performance"
else
    print_status "FAIL" "CPU cores ($cpu_cores) below minimum requirement (2+)"
fi
echo

echo "3. MEMORY (RAM) CHECK"
echo "===================="
total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
total_ram_gb=$((total_ram_kb / 1024 / 1024))
available_ram_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
available_ram_gb=$((available_ram_kb / 1024 / 1024))

print_status "INFO" "Total RAM: ${total_ram_gb} GB"
print_status "INFO" "Available RAM: ${available_ram_gb} GB"

if [ "$total_ram_gb" -ge 16 ]; then
    print_status "PASS" "RAM (${total_ram_gb} GB) excellent for local LLMs and heavy development"
elif [ "$total_ram_gb" -ge 8 ]; then
    print_status "PASS" "RAM (${total_ram_gb} GB) good for cloud-based Claude Code"
elif [ "$total_ram_gb" -ge 4 ]; then
    print_status "WARN" "RAM (${total_ram_gb} GB) meets minimum but recommend 8+ GB"
else
    print_status "FAIL" "RAM (${total_ram_gb} GB) below minimum requirement (4+ GB)"
fi
echo

echo "4. DISK SPACE CHECK"
echo "=================="
root_usage=$(df -h / | awk 'NR==2 {print $4}')
root_usage_gb=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
print_status "INFO" "Available disk space: $root_usage ($root_usage_gb GB)"

if [ "$root_usage_gb" -ge 50 ]; then
    print_status "PASS" "Disk space (${root_usage_gb} GB) excellent for local models"
elif [ "$root_usage_gb" -ge 20 ]; then
    print_status "PASS" "Disk space (${root_usage_gb} GB) sufficient for cloud-based usage"
elif [ "$root_usage_gb" -ge 10 ]; then
    print_status "WARN" "Disk space (${root_usage_gb} GB) limited, recommend 20+ GB free"
else
    print_status "FAIL" "Disk space (${root_usage_gb} GB) insufficient, need at least 10+ GB"
fi
echo

echo "5. INTERNET CONNECTIVITY CHECK"
echo "=============================="
if ping -c 1 google.com &> /dev/null; then
    print_status "PASS" "Internet connectivity working"
    
    # Check internet speed (basic)
    if command -v curl &> /dev/null; then
        print_status "INFO" "Testing download speed..."
        speed_test=$(curl -o /dev/null -s -w '%{speed_download}' http://speedtest.wdc01.softlayer.com/downloads/test10.zip --max-time 10 2>/dev/null)
        if [ ! -z "$speed_test" ] && [ "$speed_test" != "0.000" ]; then
            speed_mbps=$(echo "scale=2; $speed_test / 1024 / 1024 * 8" | bc 2>/dev/null || echo "N/A")
            print_status "INFO" "Approximate download speed: ${speed_mbps} Mbps"
        fi
    fi
else
    print_status "FAIL" "No internet connectivity detected"
fi
echo

echo "6. BROWSER CHECK"
echo "==============="
browsers=("firefox" "google-chrome" "chromium" "brave-browser" "opera")
browser_found=false

for browser in "${browsers[@]}"; do
    if command -v "$browser" &> /dev/null; then
        version=$($browser --version 2>/dev/null | head -n1)
        print_status "PASS" "Found: $version"
        browser_found=true
    fi
done

if [ "$browser_found" = false ]; then
    print_status "FAIL" "No modern browser found. Install Firefox, Chrome, or Chromium"
fi
echo

echo "7. PYTHON CHECK"
echo "==============="
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version 2>&1)
    python_major=$(python3 -c "import sys; print(sys.version_info.major)" 2>/dev/null)
    python_minor=$(python3 -c "import sys; print(sys.version_info.minor)" 2>/dev/null)
    
    print_status "INFO" "$python_version"
    
    if [ "$python_major" -eq 3 ] && [ "$python_minor" -ge 8 ]; then
        print_status "PASS" "Python version meets requirements (3.8+)"
    elif [ "$python_major" -eq 3 ] && [ "$python_minor" -ge 6 ]; then
        print_status "WARN" "Python version works but recommend 3.8+ for best compatibility"
    else
        print_status "FAIL" "Python version too old, recommend 3.8+"
    fi
    
    # Check pip
    if command -v pip3 &> /dev/null; then
        print_status "PASS" "pip3 available for package installation"
    else
        print_status "WARN" "pip3 not found, may need for local tools"
    fi
else
    print_status "FAIL" "Python3 not found. Install with: sudo apt install python3 python3-pip"
fi
echo

echo "8. GPU CHECK (Optional for Local LLMs)"
echo "====================================="
if command -v nvidia-smi &> /dev/null; then
    gpu_info=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits 2>/dev/null | head -n1)
    if [ ! -z "$gpu_info" ]; then
        gpu_name=$(echo "$gpu_info" | cut -d',' -f1 | xargs)
        gpu_memory=$(echo "$gpu_info" | cut -d',' -f2 | xargs)
        print_status "PASS" "NVIDIA GPU detected: $gpu_name (${gpu_memory} MB VRAM)"
        
        if [ "$gpu_memory" -ge 6000 ]; then
            print_status "PASS" "GPU memory sufficient for local LLMs"
        else
            print_status "WARN" "GPU memory limited for larger local models"
        fi
    else
        print_status "INFO" "NVIDIA drivers installed but no GPU detected"
    fi
else
    print_status "INFO" "No NVIDIA GPU detected (not required for cloud-based Claude Code)"
fi
echo

echo "9. DEVELOPMENT TOOLS CHECK"
echo "=========================="
tools=("git" "curl" "wget" "nano" "vim" "code")
for tool in "${tools[@]}"; do
    if command -v "$tool" &> /dev/null; then
        if [ "$tool" = "code" ]; then
            print_status "PASS" "VS Code found (excellent for Claude Code integration)"
        else
            print_status "PASS" "$tool available"
        fi
    else
        if [ "$tool" = "git" ]; then
            print_status "WARN" "$tool not found (recommended for development)"
        else
            print_status "INFO" "$tool not found (optional)"
        fi
    fi
done
echo

echo "========================================="
echo "           SUMMARY & RECOMMENDATIONS"
echo "========================================="

# Overall assessment
if [ "$total_ram_gb" -ge 8 ] && [ "$cpu_cores" -ge 4 ] && [ "$root_usage_gb" -ge 20 ] && [ "$browser_found" = true ]; then
    print_status "PASS" "Your system is well-suited for Claude Code!"
    echo -e "${GREEN}✓${NC} You can use cloud-based Claude Code without issues"
    if [ "$total_ram_gb" -ge 16 ]; then
        echo -e "${GREEN}✓${NC} You could also experiment with local LLMs"
    fi
elif [ "$total_ram_gb" -ge 4 ] && [ "$cpu_cores" -ge 2 ] && [ "$root_usage_gb" -ge 10 ] && [ "$browser_found" = true ]; then
    print_status "WARN" "Your system meets minimum requirements"
    echo -e "${YELLOW}⚠${NC} Cloud-based Claude Code should work, but consider upgrading RAM"
else
    print_status "FAIL" "Your system may struggle with Claude Code"
    echo -e "${RED}✗${NC} Consider upgrading hardware or using a lighter setup"
fi

echo
echo "Next steps:"
echo "1. For cloud Claude Code: Just open your browser and go to the Claude website"
echo "2. For VS Code integration: Install VS Code and Claude extensions"
echo "3. For local experiments: Consider installing Ollama or similar tools"
echo
echo "========================================="
