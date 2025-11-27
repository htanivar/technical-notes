#!/bin/bash
# web_domain.sh - Web domain and SSL certificate management helper functions
# Source: source "$(dirname "$0")/helpers/web_domain.sh"

# Source core utilities
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIR/core_utils.sh"

# =============================================================================
# DOMAIN MANAGEMENT
# =============================================================================

# Setup Apache virtual host
setup_apache_domain() {
    local domain="$1"
    local document_root="${2:-/var/www/$domain/html}"
    local admin_email="${3:-webmaster@$domain}"
    
    require_root
    require_command "apache2"
    
    log_step "DOMAIN" "Setting up Apache domain: $domain"
    
    # Create document root
    create_directory "$document_root" www-data www-data 755
    
    # Create a simple index.html
    cat > "$document_root/index.html" <<EOF
<html>
<head><title>Welcome to $domain</title></head>
<body><h1>Hello from $domain!</h1></body>
</html>
EOF
    
    chown www-data:www-data "$document_root/index.html"
    
    # Create Apache virtual host configuration
    local vhost_config="/etc/apache2/sites-available/${domain}.conf"
    cat > "$vhost_config" <<EOF
<VirtualHost *:80>
    ServerAdmin $admin_email
    ServerName $domain
    DocumentRoot $document_root

    ErrorLog \${APACHE_LOG_DIR}/${domain}_error.log
    CustomLog \${APACHE_LOG_DIR}/${domain}_access.log combined
</VirtualHost>
EOF
    
    # Enable the site
    a2ensite "${domain}.conf" || error_exit "Failed to enable Apache site: $domain"
    
    # Reload Apache
    systemctl reload apache2 || error_exit "Failed to reload Apache"
    
    # Update hosts file for local testing
    update_hosts_file "$domain"
    
    log_info "Apache domain setup completed: $domain"
}

# Setup Nginx virtual host
setup_nginx_domain() {
    local domain="$1"
    local document_root="${2:-/var/www/$domain/html}"
    local server_name="${3:-$domain}"
    
    require_root
    require_command "nginx"
    
    log_step "DOMAIN" "Setting up Nginx domain: $domain"
    
    # Create document root
    create_directory "$document_root" www-data www-data 755
    
    # Create a simple index.html
    cat > "$document_root/index.html" <<EOF
<html>
<head><title>Welcome to $domain</title></head>
<body><h1>Hello from $domain!</h1></body>
</html>
EOF
    
    chown www-data:www-data "$document_root/index.html"
    
    # Create Nginx server block
    local server_config="/etc/nginx/sites-available/$domain"
    cat > "$server_config" <<EOF
server {
    listen 80;
    listen [::]:80;
    
    server_name $server_name;
    root $document_root;
    index index.html index.htm index.php;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
}
EOF
    
    # Enable the site
    ln -sf "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/" || error_exit "Failed to enable Nginx site: $domain"
    
    # Test configuration and reload
    nginx -t || error_exit "Nginx configuration test failed"
    systemctl reload nginx || error_exit "Failed to reload Nginx"
    
    # Update hosts file for local testing
    update_hosts_file "$domain"
    
    log_info "Nginx domain setup completed: $domain"
}

# Remove domain configuration
remove_domain() {
    local domain="$1"
    local web_server="${2:-apache}"  # apache or nginx
    
    require_root
    
    log_step "DOMAIN" "Removing domain: $domain ($web_server)"
    
    case "$web_server" in
        apache)
            # Disable site
            a2dissite "${domain}.conf" 2>/dev/null || true
            
            # Remove configuration file
            rm -f "/etc/apache2/sites-available/${domain}.conf"
            
            # Reload Apache
            systemctl reload apache2 2>/dev/null || true
            ;;
        nginx)
            # Remove enabled site
            rm -f "/etc/nginx/sites-enabled/$domain"
            
            # Remove configuration file
            rm -f "/etc/nginx/sites-available/$domain"
            
            # Reload Nginx
            nginx -t && systemctl reload nginx 2>/dev/null || true
            ;;
        *)
            error_exit "Unsupported web server: $web_server"
            ;;
    esac
    
    # Remove from hosts file
    remove_from_hosts_file "$domain"
    
    # Optionally remove document root (ask user)
    if confirm_action "Remove document root directory /var/www/$domain?" "n"; then
        rm -rf "/var/www/$domain"
        log_info "Document root removed: /var/www/$domain"
    fi
    
    log_info "Domain removed: $domain"
}

# =============================================================================
# SUBDOMAIN MANAGEMENT
# =============================================================================

# Setup subdomain
setup_subdomain() {
    local subdomain="$1"
    local parent_domain="$2"
    local web_server="${3:-apache}"
    local full_domain="${subdomain}.${parent_domain}"
    
    log_step "SUBDOMAIN" "Setting up subdomain: $full_domain"
    
    case "$web_server" in
        apache)
            setup_apache_domain "$full_domain"
            ;;
        nginx)
            setup_nginx_domain "$full_domain"
            ;;
        *)
            error_exit "Unsupported web server for subdomain: $web_server"
            ;;
    esac
    
    log_info "Subdomain setup completed: $full_domain"
}

# =============================================================================
# HOSTS FILE MANAGEMENT
# =============================================================================

# Update hosts file with domain entry
update_hosts_file() {
    local domain="$1"
    local ip="${2:-127.0.0.1}"
    
    require_root
    
    log_step "HOSTS" "Updating hosts file for domain: $domain"
    
    # Backup hosts file
    backup_file "/etc/hosts" "/etc"
    
    # Check if entry already exists
    if grep -q "$domain" /etc/hosts; then
        log_debug "Domain already exists in hosts file: $domain"
        # Update existing entry
        sed -i "s/.*$domain.*/$ip    $domain/" /etc/hosts
    else
        # Add new entry
        echo "$ip    $domain" >> /etc/hosts
    fi
    
    log_info "Hosts file updated: $domain -> $ip"
}

# Remove domain from hosts file
remove_from_hosts_file() {
    local domain="$1"
    
    require_root
    
    log_step "HOSTS" "Removing domain from hosts file: $domain"
    
    # Backup hosts file
    backup_file "/etc/hosts" "/etc"
    
    # Remove entries containing the domain
    sed -i "/$domain/d" /etc/hosts
    
    log_info "Domain removed from hosts file: $domain"
}

# =============================================================================
# SSL CERTIFICATE MANAGEMENT
# =============================================================================

# Create self-signed certificate
create_self_signed_cert() {
    local domain="$1"
    local cert_dir="${2:-/etc/ssl/certs}"
    local key_dir="${3:-/etc/ssl/private}"
    local days="${4:-365}"
    
    require_root
    require_command "openssl"
    
    log_step "SSL" "Creating self-signed certificate for: $domain"
    
    # Create directories
    create_directory "$cert_dir" root root 755
    create_directory "$key_dir" root root 700
    
    local cert_file="$cert_dir/${domain}.crt"
    local key_file="$key_dir/${domain}.key"
    
    # Generate private key and certificate
    openssl req -x509 -nodes -days "$days" -newkey rsa:2048 \
        -keyout "$key_file" \
        -out "$cert_file" \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$domain" \
        || error_exit "Failed to create self-signed certificate for $domain"
    
    # Set proper permissions
    chmod 600 "$key_file"
    chmod 644 "$cert_file"
    
    log_info "Self-signed certificate created for $domain"
    log_info "Certificate: $cert_file"
    log_info "Private key: $key_file"
}

# Create certificate signing request
create_cert_request() {
    local domain="$1"
    local key_file="$2"
    local csr_file="$3"
    local country="${4:-US}"
    local state="${5:-State}"
    local city="${6:-City}"
    local organization="${7:-Organization}"
    local org_unit="${8:-IT Department}"
    local email="${9:-admin@$domain}"
    
    require_command "openssl"
    
    log_step "SSL" "Creating certificate signing request for: $domain"
    
    # Generate CSR
    openssl req -new \
        -key "$key_file" \
        -out "$csr_file" \
        -subj "/C=$country/ST=$state/L=$city/O=$organization/OU=$org_unit/CN=$domain/emailAddress=$email" \
        || error_exit "Failed to create CSR for $domain"
    
    log_info "Certificate signing request created: $csr_file"
}

# Sign certificate with CA
sign_certificate() {
    local csr_file="$1"
    local ca_cert="$2"
    local ca_key="$3"
    local cert_file="$4"
    local days="${5:-365}"
    
    require_command "openssl"
    require_file "$csr_file"
    require_file "$ca_cert"
    require_file "$ca_key"
    
    log_step "SSL" "Signing certificate with CA"
    
    # Sign the certificate
    openssl x509 -req \
        -days "$days" \
        -in "$csr_file" \
        -CA "$ca_cert" \
        -CAkey "$ca_key" \
        -CAcreateserial \
        -out "$cert_file" \
        || error_exit "Failed to sign certificate"
    
    log_info "Certificate signed successfully: $cert_file"
}

# Setup SSL for Apache domain
setup_apache_ssl() {
    local domain="$1"
    local cert_file="$2"
    local key_file="$3"
    local document_root="${4:-/var/www/$domain/html}"
    
    require_root
    require_command "apache2"
    require_file "$cert_file"
    require_file "$key_file"
    
    log_step "SSL" "Setting up SSL for Apache domain: $domain"
    
    # Enable SSL module
    a2enmod ssl || error_exit "Failed to enable SSL module"
    a2enmod headers || warn "Failed to enable headers module"
    
    # Create SSL virtual host
    local ssl_config="/etc/apache2/sites-available/${domain}-ssl.conf"
    cat > "$ssl_config" <<EOF
<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerAdmin webmaster@$domain
    ServerName $domain
    DocumentRoot $document_root
    
    SSLEngine on
    SSLCertificateFile $cert_file
    SSLCertificateKeyFile $key_file
    
    # Security headers
    Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
    Header always set X-Frame-Options DENY
    Header always set X-Content-Type-Options nosniff
    
    ErrorLog \${APACHE_LOG_DIR}/${domain}_ssl_error.log
    CustomLog \${APACHE_LOG_DIR}/${domain}_ssl_access.log combined
</VirtualHost>
</IfModule>
EOF
    
    # Enable SSL site
    a2ensite "${domain}-ssl.conf" || error_exit "Failed to enable SSL site: $domain"
    
    # Reload Apache
    systemctl reload apache2 || error_exit "Failed to reload Apache"
    
    log_info "SSL setup completed for Apache domain: $domain"
}

# Setup SSL for Nginx domain
setup_nginx_ssl() {
    local domain="$1"
    local cert_file="$2"
    local key_file="$3"
    local document_root="${4:-/var/www/$domain/html}"
    
    require_root
    require_command "nginx"
    require_file "$cert_file"
    require_file "$key_file"
    
    log_step "SSL" "Setting up SSL for Nginx domain: $domain"
    
    # Update Nginx configuration to include SSL
    local server_config="/etc/nginx/sites-available/$domain"
    cat > "$server_config" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    
    server_name $domain;
    root $document_root;
    index index.html index.htm index.php;
    
    ssl_certificate $cert_file;
    ssl_certificate_key $key_file;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    access_log /var/log/nginx/${domain}_ssl_access.log;
    error_log /var/log/nginx/${domain}_ssl_error.log;
}
EOF
    
    # Test configuration and reload
    nginx -t || error_exit "Nginx SSL configuration test failed"
    systemctl reload nginx || error_exit "Failed to reload Nginx"
    
    log_info "SSL setup completed for Nginx domain: $domain"
}

# =============================================================================
# CERTIFICATE AUTHORITY MANAGEMENT
# =============================================================================

# Create Certificate Authority
create_ca() {
    local ca_name="$1"
    local ca_dir="${2:-$HOME/$ca_name}"
    local days="${3:-3650}"
    local country="${4:-US}"
    local state="${5:-State}"
    local city="${6:-City}"
    local organization="${7:-$ca_name CA}"
    
    require_command "openssl"
    
    log_step "CA" "Creating Certificate Authority: $ca_name"
    
    # Create CA directory structure
    create_directory "$ca_dir"
    create_directory "$ca_dir/private"
    create_directory "$ca_dir/certs"
    
    local ca_key="$ca_dir/private/ca_private_key.pem"
    local ca_cert="$ca_dir/ca_certificate.pem"
    
    # Generate CA private key
    openssl genpkey -algorithm RSA -out "$ca_key" -aes256 \
        || error_exit "Failed to generate CA private key"
    
    chmod 600 "$ca_key"
    
    # Generate CA certificate
    openssl req -x509 -new -nodes -key "$ca_key" -sha256 -days "$days" -out "$ca_cert" \
        -subj "/C=$country/ST=$state/L=$city/O=$organization/CN=$ca_name Root CA" \
        || error_exit "Failed to generate CA certificate"
    
    chmod 644 "$ca_cert"
    
    log_info "Certificate Authority created: $ca_name"
    log_info "CA Certificate: $ca_cert"
    log_info "CA Private Key: $ca_key"
}

# Export functions
export -f setup_apache_domain setup_nginx_domain remove_domain setup_subdomain
export -f update_hosts_file remove_from_hosts_file
export -f create_self_signed_cert create_cert_request sign_certificate
export -f setup_apache_ssl setup_nginx_ssl create_ca