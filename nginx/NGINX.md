# NGINX Cheatsheet

> A comprehensive reference for NGINX configuration, commands, and patterns.

---

## Table of Contents

1. [Installation](#installation)
2. [CLI Commands](#cli-commands)
3. [File & Directory Structure](#file--directory-structure)
4. [Core Configuration Concepts](#core-configuration-concepts)
5. [Main Config Blocks](#main-config-blocks)
6. [Server Blocks (Virtual Hosts)](#server-blocks-virtual-hosts)
7. [Location Blocks](#location-blocks)
8. [Variables](#variables)
9. [Reverse Proxy](#reverse-proxy)
10. [Load Balancing](#load-balancing)
11. [SSL / TLS](#ssl--tls)
12. [Redirects & Rewrites](#redirects--rewrites)
13. [Static File Serving](#static-file-serving)
14. [Caching](#caching)
15. [Gzip Compression](#gzip-compression)
16. [Rate Limiting](#rate-limiting)
17. [Security Headers](#security-headers)
18. [Access Control](#access-control)
19. [Logging](#logging)
20. [WebSocket Proxying](#websocket-proxying)
21. [PHP-FPM (FastCGI)](#php-fpm-fastcgi)
22. [Timeouts & Performance Tuning](#timeouts--performance-tuning)
23. [Common Patterns & Recipes](#common-patterns--recipes)
24. [Debugging & Troubleshooting](#debugging--troubleshooting)

---

## Installation

```bash
# Ubuntu / Debian
sudo apt update && sudo apt install nginx

# CentOS / RHEL / Fedora
sudo dnf install nginx           # Fedora / RHEL 8+
sudo yum install nginx           # CentOS 7

# macOS (Homebrew)
brew install nginx

# Compile from source
./configure --with-http_ssl_module --with-http_v2_module
make && sudo make install
```

---

## CLI Commands

```bash
# Start / Stop / Restart / Reload
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx
sudo systemctl reload nginx      # Graceful reload (no dropped connections)

# Enable / Disable on boot
sudo systemctl enable nginx
sudo systemctl disable nginx

# Test configuration syntax
sudo nginx -t
sudo nginx -T                    # Test + dump full resolved config

# Send signals directly
sudo nginx -s reload             # Graceful reload
sudo nginx -s reopen             # Reopen log files
sudo nginx -s quit               # Graceful shutdown
sudo nginx -s stop               # Fast shutdown

# Show version and compile options
nginx -v                         # Version only
nginx -V                         # Version + compile flags

# Run with custom config file
sudo nginx -c /path/to/nginx.conf

# Check which config file is loaded
nginx -t 2>&1 | grep "configuration file"
```

---

## File & Directory Structure

```
/etc/nginx/
├── nginx.conf                  # Main configuration file
├── conf.d/                     # Additional config files (*.conf auto-included)
├── sites-available/            # Virtual host definitions
├── sites-enabled/              # Symlinks to active virtual hosts
├── snippets/                   # Reusable config fragments
├── mime.types                  # MIME type mappings
├── fastcgi_params              # FastCGI parameters
├── proxy_params                # Common proxy headers
└── uwsgi_params                # uWSGI parameters

/var/log/nginx/
├── access.log                  # Request log
└── error.log                   # Error log

/var/www/html/                  # Default web root (Debian/Ubuntu)
/usr/share/nginx/html/          # Default web root (CentOS/RHEL)

/run/nginx.pid                  # PID file
```

### Enable a Site (Debian/Ubuntu pattern)

```bash
sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

---

## Core Configuration Concepts

- **Directives** — key-value pairs ending with `;`
- **Blocks / Contexts** — groups of directives in `{ }` (`http`, `server`, `location`, `events`)
- **Inheritance** — child contexts inherit from parent; can override
- **Include** — split config across files with `include /path/*.conf;`

### Context Hierarchy

```
main (global)
└── events { }
└── http { }
    └── upstream { }
    └── server { }
        └── location { }
```

---

## Main Config Blocks

```nginx
# /etc/nginx/nginx.conf

user  www-data;                         # Worker process user
worker_processes  auto;                 # Number of worker processes (auto = CPU cores)
pid  /run/nginx.pid;                    # PID file path
error_log  /var/log/nginx/error.log warn;

events {
    worker_connections  1024;           # Max simultaneous connections per worker
    use  epoll;                         # I/O event method (Linux: epoll, BSD: kqueue)
    multi_accept  on;                   # Accept multiple connections at once
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    sendfile        on;                 # Efficient file transfer
    tcp_nopush      on;                 # Send headers in one packet
    tcp_nodelay     on;                 # No buffering for keep-alive connections

    keepalive_timeout  65;
    server_tokens  off;                 # Hide NGINX version in responses

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```

---

## Server Blocks (Virtual Hosts)

```nginx
server {
    listen       80;                    # IPv4
    listen       [::]:80;              # IPv6
    server_name  example.com www.example.com;

    root  /var/www/example.com/public;
    index index.html index.htm;

    # Default catch-all server (lowest priority)
    # listen 80 default_server;
}

# HTTPS server
server {
    listen       443 ssl http2;
    listen       [::]:443 ssl http2;
    server_name  example.com;

    ssl_certificate     /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
}
```

---

## Location Blocks

Location matching is evaluated in this priority order:

| Modifier | Type | Priority |
|----------|------|----------|
| `=`      | Exact match | 1 (highest) |
| `^~`     | Prefix match (no regex after) | 2 |
| `~`      | Case-sensitive regex | 3 |
| `~*`     | Case-insensitive regex | 3 |
| *(none)* | Prefix match | 4 (lowest) |

```nginx
# Exact match
location = /favicon.ico { }

# Prefix match — stops regex search if matched
location ^~ /static/ { }

# Case-sensitive regex
location ~ \.php$ { }

# Case-insensitive regex
location ~* \.(jpg|jpeg|png|gif|ico)$ { }

# Generic prefix match
location /api/ { }

# Catch-all
location / { }
```

### `try_files` Directive

```nginx
location / {
    # Try: file → directory → fallback
    try_files $uri $uri/ /index.html;

    # Try file, then pass to named location on 404
    try_files $uri $uri/ @backend;
}

location @backend {
    proxy_pass http://localhost:3000;
}
```

---

## Variables

| Variable | Description |
|----------|-------------|
| `$host` | Request Host header |
| `$uri` | Current URI (normalized, no query string) |
| `$request_uri` | Full original URI including query string |
| `$args` / `$query_string` | Query string |
| `$scheme` | `http` or `https` |
| `$request_method` | GET, POST, etc. |
| `$remote_addr` | Client IP address |
| `$remote_port` | Client port |
| `$server_addr` | Server IP |
| `$server_port` | Server port |
| `$server_name` | Server name matched |
| `$request_filename` | Full filesystem path |
| `$document_root` | Root directory value |
| `$http_<header>` | Any request header (e.g. `$http_user_agent`) |
| `$sent_http_<header>` | Any response header |
| `$status` | Response status code |
| `$body_bytes_sent` | Bytes sent in response body |
| `$request_time` | Request processing time (seconds) |
| `$upstream_response_time` | Time waiting for upstream |
| `$upstream_addr` | Upstream server address |
| `$ssl_protocol` | SSL/TLS protocol |
| `$ssl_cipher` | SSL/TLS cipher used |
| `$is_args` | `?` if args present, else empty string |
| `$realpath_root` | Resolved document root |

---

## Reverse Proxy

```nginx
server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass         http://localhost:3000;

        # Essential proxy headers
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;

        # Buffering
        proxy_buffering        on;
        proxy_buffer_size      16k;
        proxy_buffers          4 32k;
        proxy_busy_buffers_size 64k;

        # Timeouts
        proxy_connect_timeout  60s;
        proxy_send_timeout     60s;
        proxy_read_timeout     60s;
    }
}
```

### Proxy to HTTPS Upstream

```nginx
location / {
    proxy_pass https://upstream-server;
    proxy_ssl_verify        on;
    proxy_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt;
    proxy_ssl_server_name   on;
}
```

### Reuse `/etc/nginx/proxy_params`

```nginx
# /etc/nginx/proxy_params
proxy_set_header Host             $http_host;
proxy_set_header X-Real-IP        $remote_addr;
proxy_set_header X-Forwarded-For  $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;

# In your server block:
location / {
    proxy_pass http://localhost:3000;
    include proxy_params;
}
```

---

## Load Balancing

```nginx
upstream backend {
    # Round-robin (default)
    server backend1.example.com;
    server backend2.example.com;
    server backend3.example.com weight=3;   # Weighted

    # Least connections
    least_conn;

    # IP hash (sticky sessions)
    ip_hash;

    # Backup server (used when others are down)
    server backup.example.com backup;

    # Mark as down without removing
    server bad.example.com down;

    # Health checks (NGINX Plus / OpenResty)
    # health_check interval=5s;

    # Keep alive connections to upstream
    keepalive 32;
}

server {
    location / {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";     # Required for keepalive
    }
}
```

### Upstream Parameters

| Parameter | Description |
|-----------|-------------|
| `weight=N` | Load weight (default 1) |
| `max_fails=N` | Failures before marking unavailable (default 1) |
| `fail_timeout=Ns` | Duration to mark as failed + check interval |
| `backup` | Use only when primary servers are down |
| `down` | Permanently marks server as unavailable |
| `resolve` | Re-resolve DNS for domain names |

---

## SSL / TLS

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;

    # Certificate files
    ssl_certificate     /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    # Strong protocols only
    ssl_protocols  TLSv1.2 TLSv1.3;

    # Cipher suites (Mozilla Intermediate)
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Session cache
    ssl_session_cache   shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;

    # OCSP stapling
    ssl_stapling        on;
    ssl_stapling_verify on;
    resolver            8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout    5s;

    # HSTS (optional — enables strict HTTPS)
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;

    # Diffie-Hellman params (generate: openssl dhparam -out /etc/nginx/dhparam.pem 2048)
    ssl_dhparam /etc/nginx/dhparam.pem;
}
```

### Let's Encrypt with Certbot

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Obtain and install certificate
sudo certbot --nginx -d example.com -d www.example.com

# Renewal (auto via systemd timer)
sudo certbot renew --dry-run
```

---

## Redirects & Rewrites

### HTTP → HTTPS Redirect

```nginx
server {
    listen 80;
    server_name example.com www.example.com;
    return 301 https://$host$request_uri;
}
```

### www → non-www Redirect

```nginx
server {
    listen 443 ssl http2;
    server_name www.example.com;
    return 301 https://example.com$request_uri;
}
```

### `return` Directive

```nginx
return 301 https://example.com$request_uri;    # Permanent redirect
return 302 /new-path;                           # Temporary redirect
return 200 "OK";                                # Custom response
return 404;                                     # Not found
return 410;                                     # Gone
```

### `rewrite` Directive

```nginx
# Syntax: rewrite regex replacement [flag];
# Flags: last, break, redirect (302), permanent (301)

rewrite ^/old-path/?$   /new-path  permanent;
rewrite ^/blog/(.*)$    /news/$1   last;

# Rewrite with captured group
rewrite ^/users/(\d+)$  /profile?id=$1  last;
```

### `rewrite` vs `return`

| | `return` | `rewrite` |
|--|----------|-----------|
| Performance | Faster (no regex) | Slower |
| Use for | Simple redirects | Complex URI manipulation |
| Regex | No | Yes |

---

## Static File Serving

```nginx
server {
    listen 80;
    server_name example.com;
    root /var/www/example.com;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff2?)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
}
```

### Directory Listings

```nginx
location /files/ {
    autoindex on;
    autoindex_exact_size off;     # Show human-readable sizes
    autoindex_localtime on;       # Use local timezone
}
```

---

## Caching

### Proxy Cache

```nginx
http {
    # Define cache zone (in http block)
    proxy_cache_path /var/cache/nginx
                     levels=1:2
                     keys_zone=my_cache:10m
                     max_size=1g
                     inactive=60m
                     use_temp_path=off;

    server {
        location / {
            proxy_pass         http://backend;
            proxy_cache        my_cache;
            proxy_cache_valid  200 1d;          # Cache 200 responses for 1 day
            proxy_cache_valid  404 1m;
            proxy_cache_use_stale error timeout updating;
            proxy_cache_lock   on;

            # Add cache status header for debugging
            add_header X-Cache-Status $upstream_cache_status;
        }

        # Bypass cache with header or cookie
        location /api/ {
            proxy_pass       http://backend;
            proxy_cache      my_cache;
            proxy_cache_bypass $http_cache_control;
            proxy_no_cache   $http_pragma;
        }
    }
}
```

### Browser Cache Headers

```nginx
# Immutable assets (fingerprinted filenames)
location ~* \.(js|css)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}

# Images
location ~* \.(png|jpg|jpeg|gif|webp|svg|ico)$ {
    expires 30d;
    add_header Cache-Control "public";
}

# HTML — don't cache
location ~* \.html$ {
    expires -1;
    add_header Cache-Control "no-cache, no-store, must-revalidate";
}
```

---

## Gzip Compression

```nginx
http {
    gzip               on;
    gzip_vary          on;           # Vary: Accept-Encoding header
    gzip_proxied       any;
    gzip_comp_level    6;            # 1 (fastest) to 9 (best compression)
    gzip_buffers       16 8k;
    gzip_http_version  1.1;
    gzip_min_length    256;          # Don't compress tiny files

    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml
        application/xml+rss
        application/atom+xml
        image/svg+xml
        font/truetype
        font/opentype
        application/vnd.ms-fontobject;
}
```

### Brotli Compression (requires module)

```nginx
brotli             on;
brotli_comp_level  6;
brotli_types       text/plain text/css application/json application/javascript;
```

---

## Rate Limiting

```nginx
http {
    # Define rate limit zone (key=IP, 10MB memory, 10 req/s)
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m    rate=1r/m;

    # Connection limit zone
    limit_conn_zone $binary_remote_addr zone=conn_limit:10m;

    server {
        # Apply rate limit: burst up to 20, no delay
        location /api/ {
            limit_req zone=api_limit burst=20 nodelay;
            limit_req_status 429;
            proxy_pass http://backend;
        }

        # Strict login rate limit: burst 5, delay extras
        location /login {
            limit_req zone=login burst=5;
            limit_req_status 429;
        }

        # Connection limit: max 10 connections per IP
        location /download/ {
            limit_conn conn_limit 10;
            limit_conn_status 429;
        }
    }
}
```

---

## Security Headers

```nginx
server {
    # Remove server version
    server_tokens off;

    # Prevent clickjacking
    add_header X-Frame-Options "SAMEORIGIN" always;

    # XSS protection
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Content Security Policy (customize for your app)
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';" always;

    # Referrer policy
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Permissions policy
    add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;

    # HSTS (only if HTTPS)
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
}
```

---

## Access Control

### Allow/Deny by IP

```nginx
location /admin/ {
    allow 192.168.1.0/24;
    allow 10.0.0.1;
    deny  all;
}
```

### Basic Authentication

```bash
# Create password file
sudo apt install apache2-utils
sudo htpasswd -c /etc/nginx/.htpasswd username
```

```nginx
location /private/ {
    auth_basic           "Restricted Area";
    auth_basic_user_file /etc/nginx/.htpasswd;
}
```

### Block by User Agent

```nginx
if ($http_user_agent ~* (bot|crawler|spider|wget|curl)) {
    return 403;
}
```

### Block by Request Method

```nginx
if ($request_method !~ ^(GET|HEAD|POST)$) {
    return 405;
}
```

---

## Logging

### Log Format

```nginx
http {
    # Combined format (default)
    log_format combined '$remote_addr - $remote_user [$time_local] '
                        '"$request" $status $body_bytes_sent '
                        '"$http_referer" "$http_user_agent"';

    # JSON format
    log_format json_log escape=json '{'
        '"time":"$time_iso8601",'
        '"remote_addr":"$remote_addr",'
        '"method":"$request_method",'
        '"uri":"$request_uri",'
        '"status":$status,'
        '"bytes_sent":$body_bytes_sent,'
        '"request_time":$request_time,'
        '"upstream_time":"$upstream_response_time",'
        '"user_agent":"$http_user_agent"'
    '}';

    access_log /var/log/nginx/access.log combined;
    error_log  /var/log/nginx/error.log  warn;
}
```

### Per-Server Logging

```nginx
server {
    access_log /var/log/nginx/example.access.log combined;
    error_log  /var/log/nginx/example.error.log;

    # Disable access log for static assets
    location ~* \.(css|js|ico|png)$ {
        access_log off;
    }

    # Conditional logging (log only errors)
    map $status $loggable {
        ~^[23]  0;
        default 1;
    }
    access_log /var/log/nginx/errors.log combined if=$loggable;
}
```

### Log Rotation

```bash
# Logrotate config: /etc/logrotate.d/nginx
/var/log/nginx/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    sharedscripts
    postrotate
        nginx -s reopen
    endscript
}
```

---

## WebSocket Proxying

```nginx
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

server {
    location /ws/ {
        proxy_pass         http://ws_backend;
        proxy_http_version 1.1;

        proxy_set_header   Upgrade    $http_upgrade;
        proxy_set_header   Connection $connection_upgrade;
        proxy_set_header   Host       $host;

        proxy_read_timeout 3600s;     # Keep WebSocket connections alive
        proxy_send_timeout 3600s;
    }
}
```

---

## PHP-FPM (FastCGI)

```nginx
server {
    listen 80;
    server_name example.com;
    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass   unix:/run/php/php8.1-fpm.sock;  # or 127.0.0.1:9000
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include        fastcgi_params;
    }

    # Deny access to .htaccess
    location ~ /\.ht {
        deny all;
    }
}
```

---

## Timeouts & Performance Tuning

```nginx
http {
    # Client timeouts
    client_header_timeout   10s;
    client_body_timeout     10s;
    send_timeout            10s;
    keepalive_timeout       65s;
    keepalive_requests      1000;

    # Client body
    client_max_body_size    16m;     # Max upload size (0 = unlimited)
    client_body_buffer_size 128k;

    # Proxy timeouts
    proxy_connect_timeout   60s;
    proxy_read_timeout      60s;
    proxy_send_timeout      60s;

    # File serving
    sendfile        on;
    sendfile_max_chunk 1m;
    tcp_nopush      on;
    tcp_nodelay     on;

    # Open file cache
    open_file_cache          max=10000 inactive=30s;
    open_file_cache_valid    60s;
    open_file_cache_min_uses 2;
    open_file_cache_errors   on;

    # Worker tuning (in main context)
    # worker_processes auto;
    # worker_rlimit_nofile 65535;
}

events {
    worker_connections 4096;
    multi_accept on;
    use epoll;                       # Linux only
}
```

---

## Common Patterns & Recipes

### Single Page Application (React / Vue / Angular)

```nginx
server {
    listen 80;
    server_name example.com;
    root /var/www/app/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache hashed assets forever
    location ~* \.(js|css)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### Node.js App Proxy

```nginx
upstream node_app {
    server 127.0.0.1:3000;
    keepalive 64;
}

server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass         http://node_app;
        proxy_http_version 1.1;
        proxy_set_header   Connection "";
        proxy_set_header   Host             $host;
        proxy_set_header   X-Real-IP        $remote_addr;
        proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }
}
```

### WordPress

```nginx
server {
    listen 80;
    server_name example.com;
    root /var/www/wordpress;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff2)$ {
        expires max;
        log_not_found off;
    }

    # Deny access to sensitive files
    location ~ /\.(ht|git) { deny all; }
    location = /wp-config.php { deny all; }
    location ~* /wp-admin/.*\.php$ {
        allow 203.0.113.0/24;          # Your admin IP range
        deny all;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

### Serve Multiple Sites from One IP

```nginx
# /etc/nginx/sites-available/site-a.conf
server {
    listen 80;
    server_name site-a.com;
    root /var/www/site-a;
    ...
}

# /etc/nginx/sites-available/site-b.conf
server {
    listen 80;
    server_name site-b.com;
    root /var/www/site-b;
    ...
}
```

### Custom Error Pages

```nginx
server {
    error_page 404              /404.html;
    error_page 500 502 503 504  /50x.html;

    location = /404.html {
        root /var/www/errors;
        internal;
    }

    location = /50x.html {
        root /var/www/errors;
        internal;
    }
}
```

### Maintenance Mode

```nginx
set $maintenance off;
if (-f /var/www/maintenance.flag) {
    set $maintenance on;
}
if ($maintenance = on) {
    return 503;
}

error_page 503 /maintenance.html;
location = /maintenance.html {
    root /var/www/html;
    internal;
}
```

### CORS Headers

```nginx
location /api/ {
    add_header Access-Control-Allow-Origin  "https://app.example.com" always;
    add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Authorization, Content-Type" always;

    if ($request_method = OPTIONS) {
        add_header Access-Control-Max-Age 1728000;
        add_header Content-Length 0;
        return 204;
    }

    proxy_pass http://backend;
}
```

### Protect .git and Other Sensitive Paths

```nginx
location ~ /\.(git|env|svn|htaccess|htpasswd) {
    deny all;
    return 404;
}
```

---

## Debugging & Troubleshooting

### Common Commands

```bash
# Test config before applying
sudo nginx -t

# Check nginx is running and see processes
sudo systemctl status nginx
ps aux | grep nginx

# Check listening ports
sudo ss -tlnp | grep nginx
sudo netstat -tlnp | grep nginx

# View real-time access log
sudo tail -f /var/log/nginx/access.log

# View real-time error log
sudo tail -f /var/log/nginx/error.log

# Filter errors only
sudo grep "error" /var/log/nginx/error.log | tail -50

# Check what config file is used
sudo nginx -T | head -20

# Test a specific URL (from server)
curl -I http://localhost
curl -Lv https://example.com

# Check upstream connectivity
curl -I http://127.0.0.1:3000
```

### Increase Debug Logging

```nginx
error_log /var/log/nginx/error.log debug;  # Temporary — very verbose
```

### `$upstream_cache_status` Values

| Value | Meaning |
|-------|---------|
| `HIT` | Served from cache |
| `MISS` | Not in cache, fetched from upstream |
| `BYPASS` | Cache bypassed by rule |
| `EXPIRED` | Cached but expired |
| `STALE` | Stale cache served |
| `UPDATING` | Stale cache while cache is being updated |
| `REVALIDATED` | Cached and revalidated with upstream |

### Common HTTP Status Codes

| Code | Meaning |
|------|---------|
| `200` | OK |
| `301` | Moved Permanently |
| `302` | Found (Temporary Redirect) |
| `304` | Not Modified |
| `400` | Bad Request |
| `401` | Unauthorized |
| `403` | Forbidden |
| `404` | Not Found |
| `405` | Method Not Allowed |
| `429` | Too Many Requests |
| `499` | Client Closed Request (NGINX-specific) |
| `500` | Internal Server Error |
| `502` | Bad Gateway |
| `503` | Service Unavailable |
| `504` | Gateway Timeout |

---

## Quick Reference Card

```nginx
# Minimal HTTP server
server {
    listen 80;
    server_name example.com;
    root /var/www/html;
    index index.html;
    location / { try_files $uri $uri/ =404; }
}

# Minimal HTTPS reverse proxy
server {
    listen 443 ssl http2;
    server_name example.com;
    ssl_certificate     /path/to/fullchain.pem;
    ssl_certificate_key /path/to/privkey.pem;
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
server {
    listen 80;
    server_name example.com;
    return 301 https://$host$request_uri;
}
```

---

*Generated reference — always consult the [official NGINX documentation](https://nginx.org/en/docs/) for the latest details.*
