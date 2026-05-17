#!/bin/bash

# Website Security Analyzer - For legitimate security research
# Author: Security Researcher
# Disclaimer: Use only on websites you own or have explicit permission to test

# Authorized users (space-separated list of usernames)
AUTHORIZED_USERS="root"

# Check if the script is run by an authorized user
check_authorized_user() {
    local current_user
    current_user=$(whoami)
    for user in $AUTHORIZED_USERS; do
        if [ "$current_user" = "$user" ]; then
            return 0
        fi
    done
    echo -e "\033[0;31m[!] This script must be run by an authorized user (root).\033[0m"
    echo -e "\033[1;33m[*] Please run with: sudo $0 $*\033[0m"
    exit 1
}

# Run authorization check early
check_authorized_user "$@"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Print banner
print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║         Website Security Analyzer - Research Tool            ║"
    echo "║            For Authorized Testing Only                       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check required tools
check_dependencies() {
    echo -e "${YELLOW}[*] Checking dependencies...${NC}"
    local deps=("curl" "nmap" "openssl" "whois" "dig" "nslookup" "wget" "whatweb")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${RED}[!] Missing dependencies: ${missing[*]}${NC}"
        echo -e "${YELLOW}[*] Would you like to install them now? (y/N)${NC}"
        read -r answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}[*] Installing missing packages...${NC}"
            sudo apt-get update -qq
            sudo apt-get install -y "${missing[@]}"
            # Verify installation
            local still_missing=()
            for dep in "${missing[@]}"; do
                if ! command -v "$dep" &> /dev/null; then
                    still_missing+=("$dep")
                fi
            done
            if [ ${#still_missing[@]} -ne 0 ]; then
                echo -e "${RED}[!] Failed to install: ${still_missing[*]}${NC}"
                echo -e "${YELLOW}[*] Please install them manually and re-run the script.${NC}"
                exit 1
            fi
            echo -e "${GREEN}[+] Dependencies installed successfully${NC}"
        else
            echo -e "${RED}[!] Cannot proceed without required dependencies.${NC}"
            echo -e "${YELLOW}[*] Install with: sudo apt-get install ${missing[*]} -y${NC}"
            exit 1
        fi
    fi
    echo -e "${GREEN}[+] All dependencies satisfied${NC}"
}

# Get technologies using whatweb
get_technologies() {
    echo -e "${YELLOW}[*] Detecting technologies...${NC}"
    if command -v whatweb &> /dev/null; then
        whatweb "$1" -q | cut -d' ' -f2-
    else
        echo -e "${RED}[!] whatweb not installed${NC}"
    fi
}

# Check security headers
check_security_headers() {
    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}🔒 SECURITY HEADERS ANALYSIS${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
    
    local headers=$(curl -s -I -k "$1" | tr -d '\r')
    
    check_header() {
        local header="$1"
        local description="$2"
        if echo "$headers" | grep -qi "^$header:"; then
            local value=$(echo "$headers" | grep -i "^$header:" | cut -d' ' -f2-)
            echo -e "${GREEN}✅ $header: $value${NC}"
        else
            echo -e "${RED}❌ $header - $description${NC}"
        fi
    }
    
    check_header "Strict-Transport-Security" "Missing HSTS - vulnerable to protocol downgrade attacks"
    check_header "Content-Security-Policy" "Missing CSP - vulnerable to XSS attacks"
    check_header "X-Frame-Options" "Missing - vulnerable to clickjacking"
    check_header "X-Content-Type-Options" "Missing - possible MIME confusion attacks"
    check_header "X-XSS-Protection" "Missing - XSS filtering not enforced"
    check_header "Referrer-Policy" "Missing - information leakage possible"
    check_header "Permissions-Policy" "Missing - browser features not restricted"
}

# SSL/TLS Security Check
check_ssl_security() {
    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}🔐 SSL/TLS SECURITY ANALYSIS${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
    
    local domain=$(echo "$1" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
    
    # Get SSL certificate info
    echo -e "${YELLOW}[*] Fetching SSL certificate...${NC}"
    echo | openssl s_client -servername "$domain" -connect "$domain":443 2>/dev/null | openssl x509 -text -noout 2>/dev/null | grep -E "Not Before:|Not After :|Subject:|Issuer:|DNS:" | head -10
    
    # Check SSL protocols
    echo -e "\n${YELLOW}[*] Checking supported SSL/TLS versions...${NC}"
    for version in ssl2 ssl3 tls1 tls1_1 tls1_2 tls1_3; do
        if echo | openssl s_client -$version -connect "$domain":443 2>/dev/null | grep -q "CONNECTED"; then
            echo -e "${RED}⚠️  $version is ENABLED (insecure)${NC}"
        else
            echo -e "${GREEN}✅ $version is disabled${NC}"
        fi
    done
}

# Check for common vulnerabilities
check_vulnerabilities() {
    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}💣 VULNERABILITY CHECKS${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
    
    local domain=$(echo "$1" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
    
    # Check for open ports
    echo -e "${YELLOW}[*] Scanning common ports...${NC}"
    for port in 21 22 23 25 80 443 3306 5432 27017 6379 8080 8443; do
        timeout 1 bash -c "echo >/dev/tcp/$domain/$port" 2>/dev/null && echo -e "${RED}⚠️  Port $port is OPEN${NC}"
    done
    
    # Check for directory traversal
    echo -e "\n${YELLOW}[*] Testing for directory listing...${NC}"
    response=$(curl -s -k -o /dev/null -w "%{http_code}" "$1/uploads/")
    if [ "$response" == "200" ] || [ "$response" == "403" ]; then
        echo -e "${RED}⚠️  Possible directory listing vulnerability at /uploads/${NC}"
    fi
    
    # Check for server info disclosure
    echo -e "\n${YELLOW}[*] Checking for information disclosure...${NC}"
    curl -s -I -k "$1" | grep -i "server:" && echo -e "${RED}⚠️  Server information disclosed${NC}"
    
    # Check for backup files
    echo -e "${YELLOW}[*] Checking for exposed backup files...${NC}"
    for backup in ".env" ".git/config" "backup.zip" "backup.tar.gz" "wp-config.php.bak"; do
        response=$(curl -s -k -o /dev/null -w "%{http_code}" "$1/$backup")
        if [ "$response" == "200" ]; then
            echo -e "${RED}⚠️  Backup file exposed: $backup${NC}"
        fi
    done
    
    # Check for admin panels
    echo -e "${YELLOW}[*] Checking for exposed admin panels...${NC}"
    for admin in "admin" "login" "wp-admin" "administrator" "cpanel" "webmin"; do
        response=$(curl -s -k -o /dev/null -w "%{http_code}" "$1/$admin")
        if [ "$response" == "200" ] || [ "$response" == "403" ]; then
            echo -e "${RED}⚠️  Admin panel found: /$admin (HTTP $response)${NC}"
        fi
    done
}

# DNS Security Check
check_dns_security() {
    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}🌐 DNS SECURITY ANALYSIS${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
    
    local domain=$(echo "$1" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
    
    # Check DNS records
    echo -e "${YELLOW}[*] DNS Records:${NC}"
    for record in A MX TXT NS CNAME; do
        dig +short "$domain" "$record" 2>/dev/null | head -3 | while read line; do
            [ -n "$line" ] && echo -e "${GREEN}📋 $record: $line${NC}"
        done
    done
    
    # Check for SPF record
    echo -e "\n${YELLOW}[*] Email Security (SPF/DKIM/DMARC):${NC}"
    spf=$(dig +short TXT "$domain" | grep -i "v=spf1")
    if [ -n "$spf" ]; then
        echo -e "${GREEN}✅ SPF Record found${NC}"
    else
        echo -e "${RED}❌ No SPF record - vulnerable to email spoofing${NC}"
    fi
}

# WHOIS Information
get_whois_info() {
    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}ℹ️  DOMAIN REGISTRATION INFO${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
    
    local domain=$(echo "$1" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
    whois "$domain" 2>/dev/null | grep -E "Creation Date|Registry Expiry Date|Name Server|Registrar|Organization" | head -10
}

# Full port scan (optional - can be slow)
quick_port_scan() {
    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}🔌 PORT SCAN${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
    
    local domain=$(echo "$1" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
    echo -e "${YELLOW}[*] Scanning top 20 ports (this may take a moment)...${NC}"
    nmap -T4 -F "$domain" 2>/dev/null | grep -E "open|closed|filtered"
}

# Generate security recommendations
generate_recommendations() {
    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}🛡️ SECURITY RECOMMENDATIONS${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
    
    echo -e "${GREEN}1. Always use HTTPS with HSTS preload${NC}"
    echo -e "${GREEN}2. Implement Content Security Policy (CSP)${NC}"
    echo -e "${GREEN}3. Disable directory listing on web server${NC}"
    echo -e "${GREEN}4. Remove server version information from headers${NC}"
    echo -e "${GREEN}5. Regularly update CMS, plugins, and dependencies${NC}"
    echo -e "${GREEN}6. Use Web Application Firewall (WAF)${NC}"
    echo -e "${GREEN}7. Implement rate limiting and brute force protection${NC}"
    echo -e "${GREEN}8. Conduct regular security audits and penetration tests${NC}"
    echo -e "${GREEN}9. Enable DNSSEC${NC}"
    echo -e "${GREEN}10. Implement proper input validation and parameterized queries${NC}"
}

# Main function
main() {
    print_banner
    
    if [ -z "$1" ]; then
        echo -e "${RED}Usage: $0 <website_url>${NC}"
        echo -e "${YELLOW}Example: $0 https://example.com${NC}"
        exit 1
    fi
    
    TARGET="$1"
    echo -e "${GREEN}[+] Target: $TARGET${NC}"
    
    check_dependencies
    
    # Run all checks
    get_technologies "$TARGET"
    check_security_headers "$TARGET"
    check_ssl_security "$TARGET"
    check_vulnerabilities "$TARGET"
    check_dns_security "$TARGET"
    get_whois_info "$TARGET"
    
    # Optional: Uncomment for port scanning (slower)
    # quick_port_scan "$TARGET"
    
    generate_recommendations
    
    echo -e "\n${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ Analysis complete!${NC}"
    echo -e "${YELLOW}⚠️  Remember: Only test websites you own or have permission to test${NC}"
}

# Run main function with all arguments
main "$@"
