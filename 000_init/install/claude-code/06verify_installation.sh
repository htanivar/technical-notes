#!/bin/bash

echo "========================================="
echo "   POST-INSTALLATION VERIFICATION"
echo "   Claude Code Setup Validation"
echo "========================================="
echo

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Counters
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
TOTAL_CHECKS=0

# Function to print status and count
print_status() {
    local status=$1
    local message=$2
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    case $status in
        "PASS")
            echo -e "${GREEN}✓ PASS${NC}: $message"
            PASS_COUNT=$((PASS_COUNT + 1))
            ;;
        "WARN")
            echo -e "${YELLOW}⚠ WARN${NC}: $message"
            WARN_COUNT=$((WARN_COUNT + 1))
            ;;
        "FAIL")
            echo -e "${RED}✗ FAIL${NC}: $message"
            FAIL_COUNT=$((FAIL_COUNT + 1))
            ;;
        "INFO")
            echo -e "${BLUE}ℹ INFO${NC}: $message"
            ;;
        "HEADER")
            echo -e "${PURPLE}$message${NC}"
            TOTAL_CHECKS=$((TOTAL_CHECKS - 1))
            ;;
    esac
}

print_status "HEADER" "1. PIP3 INSTALLATION VERIFICATION"
echo "=================================="
if command -v pip3 &> /dev/null; then
    pip_version=$(pip3 --version 2>/dev/null)
    print_status "PASS" "pip3 installed: $pip_version"
    
    # Check if Python packages are available (both user and system-wide)
    python_packages=("requests" "bs4" "numpy" "pandas")
    for package in "${python_packages[@]}"; do
        # Use Python import to check if package is available (works for both user and system installs)
        if python3 -c "import $package" &> /dev/null; then
            # Get version if possible
            version=$(python3 -c "import $package; print(getattr($package, '__version__', 'installed'))" 2>/dev/null || echo "installed")
            print_status "PASS" "Python package '$package' available (version: $version)"
        else
            print_status "WARN" "Python package '$package' not found (optional)"
        fi
    done
else
    print_status "FAIL" "pip3 not found - installation may have failed"
fi
echo

print_status "HEADER" "2. DEVELOPMENT TOOLS VERIFICATION"
echo "=================================="
dev_tools=("git" "curl" "wget" "nano" "vim" "build-essential")
for tool in "${dev_tools[@]}"; do
    if [ "$tool" = "build-essential" ]; then
        if dpkg -l | grep -q "build-essential"; then
            print_status "PASS" "build-essential package installed"
        else
            print_status "WARN" "build-essential not installed"
        fi
    else
        if command -v "$tool" &> /dev/null; then
            if [ "$tool" = "git" ]; then
                git_version=$(git --version 2>/dev/null)
                print_status "PASS" "$git_version"
            else
                print_status "PASS" "$tool available"
            fi
        else
            print_status "WARN" "$tool not found"
        fi
    fi
done

# Check VS Code specifically
if command -v code &> /dev/null; then
    vscode_version=$(code --version 2>/dev/null | head -n1)
    print_status "PASS" "VS Code installed: $vscode_version"
else
    print_status "INFO" "VS Code not installed (optional)"
fi
echo

print_status "HEADER" "3. BROWSER VERIFICATION"
echo "======================="
browsers=("firefox" "google-chrome" "chromium" "brave-browser" "opera")
browser_found=false

for browser in "${browsers[@]}"; do
    if command -v "$browser" &> /dev/null; then
        version=$($browser --version 2>/dev/null | head -n1)
        print_status "PASS" "$version"
        browser_found=true
    fi
done

if [ "$browser_found" = false ]; then
    print_status "FAIL" "No modern browser found"
else
    print_status "PASS" "At least one modern browser available"
fi
echo

print_status "HEADER" "4. SYSTEM OPTIMIZATION VERIFICATION"
echo "===================================="

# Check swappiness
current_swappiness=$(cat /proc/sys/vm/swappiness 2>/dev/null)
if [ "$current_swappiness" -le 10 ]; then
    print_status "PASS" "Swappiness optimized: $current_swappiness (≤10 is good)"
else
    print_status "WARN" "Swappiness not optimized: $current_swappiness (consider lowering to 10)"
fi

# Check if swappiness is persistent
if grep -q "vm.swappiness" /etc/sysctl.conf 2>/dev/null; then
    print_status "PASS" "Swappiness setting will persist after reboot"
else
    print_status "WARN" "Swappiness setting may not persist after reboot"
fi

# Check zram tools
if command -v zramctl &> /dev/null; then
    print_status "PASS" "zram tools available for memory compression"
else
    print_status "WARN" "zram tools not installed"
fi

# Check system cleanliness
cache_size=$(du -sh /var/cache/apt/archives 2>/dev/null | cut -f1)
print_status "INFO" "APT cache size: $cache_size"
echo

print_status "HEADER" "5. CLAUDE CODE READINESS CHECK"
echo "==============================="

# Re-check system specs
cpu_cores=$(nproc)
total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
total_ram_gb=$((total_ram_kb / 1024 / 1024))
root_usage_gb=$(df / | awk 'NR==2 {print int($4/1024/1024)}')

print_status "INFO" "CPU Cores: $cpu_cores"
print_status "INFO" "Total RAM: ${total_ram_gb} GB"
print_status "INFO" "Free Disk Space: ${root_usage_gb} GB"

# Internet connectivity
if ping -c 1 google.com &> /dev/null; then
    print_status "PASS" "Internet connectivity working"
else
    print_status "FAIL" "No internet connectivity"
fi

# Python check
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version 2>&1)
    print_status "PASS" "$python_version available"
else
    print_status "FAIL" "Python3 not found"
fi
echo

print_status "HEADER" "6. CLAUDE CODE INTEGRATION SUGGESTIONS"
echo "======================================"

# Check for popular code editors
editors_found=()
if command -v code &> /dev/null; then
    editors_found+=("VS Code")
fi
if command -v nano &> /dev/null; then
    editors_found+=("nano")
fi
if command -v vim &> /dev/null; then
    editors_found+=("vim")
fi

if [ ${#editors_found[@]} -gt 0 ]; then
    print_status "PASS" "Code editors available: ${editors_found[*]}"
    if [[ " ${editors_found[*]} " =~ " VS Code " ]]; then
        print_status "INFO" "Recommended: Install Claude extensions in VS Code"
    fi
else
    print_status "WARN" "No code editors found"
fi

# Check for terminal multiplexer
if command -v tmux &> /dev/null; then
    print_status "PASS" "tmux available for terminal management"
elif command -v screen &> /dev/null; then
    print_status "PASS" "screen available for terminal management"
else
    print_status "INFO" "Consider installing tmux for better terminal management"
fi
echo

print_status "HEADER" "7. FINAL ASSESSMENT"
echo "==================="

# Calculate success rate
if [ $TOTAL_CHECKS -gt 0 ]; then
    success_rate=$(( (PASS_COUNT * 100) / TOTAL_CHECKS ))
    print_status "INFO" "Overall Success Rate: ${success_rate}% (${PASS_COUNT}/${TOTAL_CHECKS} checks passed)"
else
    success_rate=0
fi

# Overall recommendation
if [ $success_rate -ge 80 ] && [ $FAIL_COUNT -eq 0 ]; then
    print_status "PASS" "🎉 EXCELLENT! Your system is fully ready for Claude Code"
    echo -e "${GREEN}✓${NC} All critical components installed successfully"
    echo -e "${GREEN}✓${NC} You can start using Claude Code immediately"
elif [ $success_rate -ge 70 ] && [ $FAIL_COUNT -le 2 ]; then
    print_status "PASS" "✅ GOOD! Your system is ready for Claude Code"
    echo -e "${YELLOW}⚠${NC} Minor issues detected but won't block usage"
elif [ $success_rate -ge 50 ]; then
    print_status "WARN" "⚠️  PARTIAL! Your system can run Claude Code with limitations"
    echo -e "${YELLOW}⚠${NC} Consider addressing the failed checks for better experience"
else
    print_status "FAIL" "❌ ISSUES DETECTED! Some critical components missing"
    echo -e "${RED}✗${NC} Please review and fix the failed checks before proceeding"
fi

echo
echo "========================================="
echo "           NEXT STEPS"
echo "========================================="
echo "1. 🌐 For web-based Claude Code:"
echo "   - Open your browser and visit claude.ai"
echo "   - Sign up/login and start coding!"
echo
echo "2. 🔧 For VS Code integration:"
echo "   - Install Claude/AI extensions in VS Code"
echo "   - Configure API keys if needed"
echo
echo "3. 🐍 For local Python development:"
echo "   - Use: pip3 install --user <package_name>"
echo "   - Your Python environment is ready!"
echo
echo "4. 🔄 If you see warnings:"
echo "   - Most warnings won't block Claude Code usage"
echo "   - Address them for optimal performance"
echo
echo "========================================="
echo "Summary: $PASS_COUNT passed, $WARN_COUNT warnings, $FAIL_COUNT failed"
echo "========================================="
