# Nginx Server Diagnostic & Security Audit Report

| Property | Value |
| :--- | :--- |
| **Overall Health** | **CRITICAL (3 FAIL, 15 WARN)** |
| **Checks Summary** | **OK:** `15` &nbsp; **WARN:** `15` &nbsp; **FAIL:** `3` |
| **Generated At** | `2026-11-14 19:02:06 IST` |
| **Host / OS** | `sandbox` (Debian GNU/Linux 12 (bookworm)) |
| **Nginx Version** | `nginx/1.22.1` — Binary: [nginx](file:///usr/sbin/nginx) (`/usr/sbin/nginx`) |
| **Main Config** | [nginx.conf](file:///etc/nginx/nginx.conf) (`/etc/nginx/nginx.conf`) |
| **Audit Script** | [status_nginx.sh](file:///home/ubuntu/code/github/raviautopilot/technical-notes/000_init/install/nginx/status_nginx.sh) (`/home/ubuntu/code/github/raviautopilot/technical-notes/000_init/install/nginx/status_nginx.sh`) |

## Quick Navigation

- [Actionable Issues Index (Failures & Warnings)](#actionable-issues)
- [1. System Overview](#1-system-overview)
- [2. Nginx Binary & Build](#2-nginx-binary-build)
- [3. Service Status & Processes](#3-service-status-processes)
- [4. Listening Ports & Connections](#4-listening-ports-connections)
- [5. Configuration Files & Layout](#5-configuration-files-layout)
- [6. Sites / Virtual Hosts](#6-sites-virtual-hosts-parsed-from-effective-config)
- [7. SSL / TLS Certificates](#7-ssl-tls-certificates)
- [8. Security Audit](#8-security-audit-config-based)
- [9. File & Directory Permissions](#9-file-directory-permissions)
- [10. System-Level Hardening](#10-system-level-hardening)
- [11. Logs - Locations, Size, Rotation](#11-logs-locations-size-rotation)
- [12. Error Log Analysis](#12-error-log-analysis)
- [13. Access Log & Traffic Analysis](#13-access-log-traffic-analysis-assumes-combined-format)
- [14. Live Endpoint Checks](#14-live-endpoint-checks-localhost)
- [15. Performance & Capacity Hints](#15-performance-capacity-hints)
- [16. Backends & Related Services](#16-backends-related-services)
- [17. Config Backup & Change Tracking](#17-config-backup-change-tracking)

<a id="actionable-issues"></a>

## What Is Wrong & How to Fix It (Failures & Warnings)

### Critical Failures (`[FAIL]` — Fix Immediately)

| ID | Section | What Is Wrong | Where (File / Line Link) | Docs | How to Fix |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FAIL-1** | [3. SERVICE STATUS & PROCESSES](#3-service-status-processes) | nginx daemon is NOT running (0 active nginx processes) | [nginx](file:///etc/init.d/nginx) (`/etc/init.d/nginx`) | [Docs](https://nginx.org/en/docs/control.html) | Verify config and start service: sudo nginx -t && sudo service nginx start (or sudo nginx) |
| **FAIL-2** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | Deprecated/insecure TLS protocols enabled (SSLv3/TLSv1/TLSv1.1) | [nginx.conf:33](file:///etc/nginx/nginx.conf#L33) (`/etc/nginx/nginx.conf:33`) | [Docs](https://ssl-config.mozilla.org/#server=nginx) | Set 'ssl_protocols TLSv1.2 TLSv1.3;' in /etc/nginx/nginx.conf and remove TLSv1 / TLSv1.1 |
| **FAIL-3** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | Weak TLS cipher suites allowed in ssl_ciphers | [nginx.localhost.com.conf:18](file:///etc/nginx/conf.d/nginx.localhost.com.conf#L18) (`/etc/nginx/conf.d/nginx.localhost.com.conf:18`) | [Docs](https://ssl-config.mozilla.org/#server=nginx) | Update ssl_ciphers using Mozilla Intermediate TLS configuration |

### Warnings (`[WARN]` — Recommended Hardening & Fixes)

| ID | Section | Warning Details | Where (File / Line Link) | Docs | How to Fix |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **WARN-1** | [3. SERVICE STATUS & PROCESSES](#3-service-status-processes) | Nginx init script not enabled in default runlevels | [nginx](file:///etc/init.d/nginx) (`/etc/init.d/nginx`) | [Docs](https://manpages.debian.org/bookworm/init-system-helpers/update-rc.d.8.en.html) | Enable at boot: sudo update-rc.d nginx defaults |
| **WARN-2** | [3. SERVICE STATUS & PROCESSES](#3-service-status-processes) | nginx -t could not read restricted file '/etc/ssl/certs/nginx/nginx.key' as non-root user | [nginx.localhost.com.conf:14](file:///etc/nginx/conf.d/nginx.localhost.com.conf#L14) (`/etc/nginx/conf.d/nginx.localhost.com.conf:14`) | [Docs](https://nginx.org/en/docs/switches.html) | Run audit or syntax test with root privileges: sudo /home/ubuntu/code/github/raviautopilot/technical-notes/000_init/install/nginx/status_nginx.sh (or sudo nginx -t) |
| **WARN-3** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | server_tokens is not set to 'off' - Nginx version is exposed in HTTP headers and error pages | [nginx.conf:21](file:///etc/nginx/nginx.conf#L21) (`/etc/nginx/nginx.conf:21`) | [Docs](https://nginx.org/en/docs/http/ngx_http_core_module.html#server_tokens) | Uncomment or add 'server_tokens off;' inside the http {} block in /etc/nginx/nginx.conf |
| **WARN-4** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | ssl_session_cache is not configured (impacts TLS handshake performance) | [nginx.conf:12](file:///etc/nginx/nginx.conf#L12) (`/etc/nginx/nginx.conf:12`) | [Docs](https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_session_cache) | Add 'ssl_session_cache shared:SSL:10m; ssl_session_timeout 1d;' in http {} block of /etc/nginx/nginx.conf |
| **WARN-5** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | HTTP security header 'Strict-Transport-Security' is missing from configuration | [nginx.localhost.com.conf:1](file:///etc/nginx/conf.d/nginx.localhost.com.conf#L1) (`/etc/nginx/conf.d/nginx.localhost.com.conf:1`) | [Docs](https://owasp.org/www-project-secure-headers/) | Add 'add_header Strict-Transport-Security "..." always;' to your server {} block or shared security snippet |
| **WARN-6** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | HTTP security header 'X-Frame-Options' is missing from configuration | [nginx.localhost.com.conf:1](file:///etc/nginx/conf.d/nginx.localhost.com.conf#L1) (`/etc/nginx/conf.d/nginx.localhost.com.conf:1`) | [Docs](https://owasp.org/www-project-secure-headers/) | Add 'add_header X-Frame-Options "..." always;' to your server {} block or shared security snippet |
| **WARN-7** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | HTTP security header 'X-Content-Type-Options' is missing from configuration | [nginx.localhost.com.conf:1](file:///etc/nginx/conf.d/nginx.localhost.com.conf#L1) (`/etc/nginx/conf.d/nginx.localhost.com.conf:1`) | [Docs](https://owasp.org/www-project-secure-headers/) | Add 'add_header X-Content-Type-Options "..." always;' to your server {} block or shared security snippet |
| **WARN-8** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | HTTP security header 'Content-Security-Policy' is missing from configuration | [nginx.localhost.com.conf:1](file:///etc/nginx/conf.d/nginx.localhost.com.conf#L1) (`/etc/nginx/conf.d/nginx.localhost.com.conf:1`) | [Docs](https://owasp.org/www-project-secure-headers/) | Add 'add_header Content-Security-Policy "..." always;' to your server {} block or shared security snippet |
| **WARN-9** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | HTTP security header 'Referrer-Policy' is missing from configuration | [nginx.localhost.com.conf:1](file:///etc/nginx/conf.d/nginx.localhost.com.conf#L1) (`/etc/nginx/conf.d/nginx.localhost.com.conf:1`) | [Docs](https://owasp.org/www-project-secure-headers/) | Add 'add_header Referrer-Policy "..." always;' to your server {} block or shared security snippet |
| **WARN-10** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | HTTP security header 'Permissions-Policy' is missing from configuration | [nginx.localhost.com.conf:1](file:///etc/nginx/conf.d/nginx.localhost.com.conf#L1) (`/etc/nginx/conf.d/nginx.localhost.com.conf:1`) | [Docs](https://owasp.org/www-project-secure-headers/) | Add 'add_header Permissions-Policy "..." always;' to your server {} block or shared security snippet |
| **WARN-11** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | No limit_req_zone defined (no request rate limiting against brute-force/DDoS) | [nginx.conf:12](file:///etc/nginx/nginx.conf#L12) (`/etc/nginx/nginx.conf:12`) | [Docs](https://nginx.org/en/docs/http/ngx_http_limit_req_module.html#limit_req_zone) | Add 'limit_req_zone $binary_remote_addr zone=req_limit:10m rate=10r/s;' in http {} block of /etc/nginx/nginx.conf |
| **WARN-12** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | limit_req is not applied to any server or location context | [nginx.localhost.com.conf:1](file:///etc/nginx/conf.d/nginx.localhost.com.conf#L1) (`/etc/nginx/conf.d/nginx.localhost.com.conf:1`) | [Docs](https://nginx.org/en/docs/http/ngx_http_limit_req_module.html#limit_req) | Apply 'limit_req zone=req_limit burst=20 nodelay;' inside sensitive server/location blocks |
| **WARN-13** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | No location rule blocking hidden dotfiles (/.git, /.env, /.htpasswd) | [nginx.localhost.com.conf:1](file:///etc/nginx/conf.d/nginx.localhost.com.conf#L1) (`/etc/nginx/conf.d/nginx.localhost.com.conf:1`) | [Docs](https://nginx.org/en/docs/http/ngx_http_core_module.html#location) | Add 'location ~ /\.(?!well-known).* { deny all; }' to server {} blocks |
| **WARN-14** | [10. SYSTEM-LEVEL HARDENING](#10-system-level-hardening) | No active host firewall rules detected ( or requires root to inspect iptables/nftables ) | [etc](file:///etc) (`/etc`) | [Docs](https://wiki.debian.org/Uncomplicated%20Firewall%20%28ufw%29) | Enable host firewall (e.g. sudo ufw allow 'Nginx Full' && sudo ufw enable) or run audit with sudo |
| **WARN-15** | [10. SYSTEM-LEVEL HARDENING](#10-system-level-hardening) | fail2ban is not installed (recommended for nginx-http-auth and bot/scanner rate-banning) | [etc](file:///etc) (`/etc`) | [Docs](https://www.fail2ban.org/wiki/index.php/Main_Page) | Install fail2ban: sudo apt-get install -y fail2ban |

---


<a id="1-system-overview"></a>

## 1. SYSTEM OVERVIEW

- OS        : Debian GNU/Linux 12 (bookworm)
- Kernel    : 6.14.2-1-liquorix-amd64  (x86_64)
- Uptime    : up 3 hours, 34 minutes
- Load avg  : 0.67 0.60 0.74   CPUs: 2

### Memory


```text
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       2.1Gi       825Mi        95Mi       1.3Gi       1.8Gi
Swap:          7.0Gi       443Mi       6.6Gi
```


### Disk usage


```text
Filesystem     Type    Size  Used Avail Use% Mounted on
apps           vboxsf  196G   91G  105G  47% /apps/go/go1.26.1
/dev/sda1      ext4     98G   25G   69G  27% /etc
```


### Disk inodes


```text
Filesystem      Inodes   IUsed   IFree IUse% Mounted on
apps              1000 -999000 1000000     - /apps/go/go1.26.1
/dev/sda1      6553600  460303 6093297    8% /etc
```


### Public / local IPs


<a id="2-nginx-binary-build"></a>

## 2. NGINX BINARY & BUILD

- Binary    : [nginx](file:///usr/sbin/nginx) (`/usr/sbin/nginx`)
- Version   : 1.22.1
- Config    : [nginx.conf](file:///etc/nginx/nginx.conf) (`/etc/nginx/nginx.conf`)

### Build info (nginx -V)


```text
nginx version: nginx/1.22.1
built with OpenSSL 3.0.20 7 Apr 2026 (running with OpenSSL 3.0.22 25 Aug 2026)
TLS SNI support enabled
configure arguments:
    --with-cc-opt='-g -O2 -ffile-prefix-map=/build/reproducible-path/nginx-1.22.1=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2'
    --with-ld-opt='-Wl,-z,relro -Wl,-z,now -fPIC'
    --prefix=/usr/share/nginx
    --conf-path=/etc/nginx/nginx.conf
    --http-log-path=/var/log/nginx/access.log
    --error-log-path=stderr
    --lock-path=/var/lock/nginx.lock
    --pid-path=/run/nginx.pid
    --modules-path=/usr/lib/nginx/modules
    --http-client-body-temp-path=/var/lib/nginx/body
    --http-fastcgi-temp-path=/var/lib/nginx/fastcgi
    --http-proxy-temp-path=/var/lib/nginx/proxy
    --http-scgi-temp-path=/var/lib/nginx/scgi
    --http-uwsgi-temp-path=/var/lib/nginx/uwsgi
    --with-compat
    --with-debug
    --with-pcre-jit
    --with-http_ssl_module
    --with-http_stub_status_module
    --with-http_realip_module
    --with-http_auth_request_module
    --with-http_v2_module
    --with-http_dav_module
    --with-http_slice_module
    --with-threads
    --with-http_addition_module
    --with-http_flv_module
    --with-http_gunzip_module
    --with-http_gzip_static_module
    --with-http_mp4_module
    --with-http_random_index_module
    --with-http_secure_link_module
    --with-http_sub_module
    --with-mail_ssl_module
    --with-stream_ssl_module
    --with-stream_ssl_preread_module
    --with-stream_realip_module
    --with-http_geoip_module=dynamic
    --with-http_image_filter_module=dynamic
    --with-http_perl_module=dynamic
    --with-http_xslt_module=dynamic
    --with-mail=dynamic
    --with-stream=dynamic
    --with-stream_geoip_module=dynamic
```


### Modules compiled in / dynamic


```text
--with-http_addition_module
--with-http_auth_request_module
--with-http_dav_module
--with-http_flv_module
--with-http_geoip_module=dynamic
--with-http_gunzip_module
--with-http_gzip_static_module
--with-http_image_filter_module=dynamic
--with-http_perl_module=dynamic
--with-http_random_index_module
--with-http_realip_module
--with-http_secure_link_module
--with-http_slice_module
--with-http_ssl_module
--with-http_stub_status_module
--with-http_sub_module
--with-http_xslt_module=dynamic
--with-mail_ssl_module
--with-stream_geoip_module=dynamic
--with-stream_realip_module
--with-stream_ssl_module
--with-stream_ssl_preread_module
```


### Package info


```text
nginx 1.22.1-9+deb12u10
nginx-common 1.22.1-9+deb12u10
```


### Update availability

- **[ OK ]** No nginx update pending (per local apt cache)
- Security Advisories: https://nginx.org/en/security_advisories.html

<a id="3-service-status-processes"></a>

## 3. SERVICE STATUS & PROCESSES

- **[FAIL] (`FAIL-1`)** nginx daemon is NOT running (0 active nginx processes)
  - **Where**: [nginx](file:///etc/init.d/nginx) (`/etc/init.d/nginx`)
  - **Reference**: <https://nginx.org/en/docs/control.html>
  - **How to Fix**: Verify config and start service: sudo nginx -t && sudo service nginx start (or sudo nginx)
- **[WARN] (`WARN-1`)** Nginx init script not enabled in default runlevels
  - **Where**: [nginx](file:///etc/init.d/nginx) (`/etc/init.d/nginx`)
  - **Reference**: <https://manpages.debian.org/bookworm/init-system-helpers/update-rc.d.8.en.html>
  - **How to Fix**: Enable at boot: sudo update-rc.d nginx defaults

### Config syntax test (nginx -t)

- **[WARN] (`WARN-2`)** nginx -t could not read restricted file '/etc/ssl/certs/nginx/nginx.key' as non-root user
  - **Where**: [nginx.localhost.com.conf:14](file:///etc/nginx/conf.d/nginx.localhost.com.conf#L14) (`/etc/nginx/conf.d/nginx.localhost.com.conf:14`)
  - **Reference**: <https://nginx.org/en/docs/switches.html>
  - **How to Fix**: Run audit or syntax test with root privileges: sudo /home/ubuntu/code/github/raviautopilot/technical-notes/000_init/install/nginx/status_nginx.sh (or sudo nginx -t)

```text
2026/11/14 19:02:06 [warn] 27#27: the "user" directive makes sense only if the master process runs with super-user privileges, ignored in /etc/nginx/nginx.conf:1
2026/11/14 19:02:06 [emerg] 27#27: cannot load certificate key "/etc/ssl/certs/nginx/nginx.key": BIO_new_file() failed (SSL: error:8000000D:system library::Permission denied:calling fopen(/etc/ssl/certs/nginx/nginx.key, r) error:10080002:BIO routines::system lib)
nginx: configuration file /etc/nginx/nginx.conf test failed
```

- Note: Effective config was loaded via direct file inclusion because 'nginx -T' exited non-zero.

### Processes


```text
    PID    PPID USER     %CPU %MEM   RSS     ELAPSED CMD
```

- No running nginx master/worker processes to inspect.
- Active worker processes: 0   (CPU cores: 2)
- PID file configured: /run/nginx.pid

<a id="4-listening-ports-connections"></a>

## 4. LISTENING PORTS & CONNECTIONS


### Sockets owned by nginx


```text
(no active sockets owned by nginx)
```


### Ports declared in config


```text
      1 [::]:80 default_server
      1 80 default_server
      1 80
      1 443 ssl
```


### TCP connection states (all :80/:443 traffic)


```text
(no active :80/:443 connections)
```


### Top 10 client IPs currently connected


```text
(none)
```


### Other services listening publicly (potential exposure)


```text
(none detected)
```


<a id="5-configuration-files-layout"></a>

## 5. CONFIGURATION FILES & LAYOUT

- Main config dir: [nginx](file:///etc/nginx) (`/etc/nginx`)

### Files loaded

- Loaded: [nginx.localhost.com.conf](file:///etc/nginx/conf.d/nginx.localhost.com.conf) (`/etc/nginx/conf.d/nginx.localhost.com.conf`)
- Loaded: [nginx.conf](file:///etc/nginx/nginx.conf) (`/etc/nginx/nginx.conf`)
- Loaded: [default](file:///etc/nginx/sites-enabled/default) (`/etc/nginx/sites-enabled/default`)

### Directory tree


```text
/etc/nginx/sites-available:
  -rw-r--r-- 1 nobody nogroup 2412 Jul 18 21:48 default
/etc/nginx/sites-enabled:
  lrwxrwxrwx 1 nobody nogroup   34 Nov 14 17:33 default -> /etc/nginx/sites-available/default
/etc/nginx/conf.d:
  -rw-r--r-- 1 nobody nogroup  748 Nov 14 17:57 nginx.localhost.com.conf
/etc/nginx/snippets:
  -rw-r--r-- 1 nobody nogroup  423 Jul 18 21:48 fastcgi-php.conf
  -rw-r--r-- 1 nobody nogroup  217 Jul 18 21:48 snakeoil.conf
/etc/nginx/modules-enabled:
```


### Broken symlinks in nginx config dir

- **[ OK ]** No broken symlinks in /etc/nginx

### Sites available but NOT enabled


### Core / global settings


```text
user www-data;
worker_processes auto;
worker_connections 768;
sendfile on;
tcp_nopush on;
types_hash_max_size 2048;
gzip on;
error_log /var/log/nginx/error.log;
error_log /var/log/nginx/nginx.localhost.com.error.log;
access_log /var/log/nginx/access.log;
access_log /var/log/nginx/nginx.localhost.com.access.log;
```

- **[ OK ]** worker_processes auto

<a id="6-sites-virtual-hosts-parsed-from-effective-config"></a>

## 6. SITES / VIRTUAL HOSTS (parsed from effective config)


```text
[1] nginx.localhost.com
    file       : /etc/nginx/conf.d/nginx.localhost.com.conf:1
    listen     : 80
    return     : 301 https://$host$request_uri
    locations  : 0     

[2] nginx.localhost.com
    file       : /etc/nginx/conf.d/nginx.localhost.com.conf:8
    listen     : 443 ssl
    root       : /var/www/html/nginx.localhost.com
    ssl cert   : /etc/ssl/certs/nginx/nginx.crt
    ssl key    : /etc/ssl/certs/nginx/nginx.key
    access_log : /var/log/nginx/nginx.localhost.com.access.log
    locations  : 1     

[3] _
    file       : /etc/nginx/sites-enabled/default:21
    listen     : 80 default_server | [::]:80 default_server
    root       : /var/www/html
    locations  : 1     

Total server blocks: 3
```


### Domains (unique server_names)


```text
_
nginx.localhost.com
```


### Default servers

- **[ OK ]** Explicit default_server configured

```text
	listen 80 default_server;
	listen [::]:80 default_server;
```


### Upstream blocks


```text
(no upstream blocks defined)
```


### Location blocks summary


```text
      2 location / {
```


### Web root(s): size & owner

- Web root [html](file:///var/www/html) (`/var/www/html`) — size=16K owner=nobody:nogroup perms=755
- Web root [nginx.localhost.com](file:///var/www/html/nginx.localhost.com) (`/var/www/html/nginx.localhost.com`) — size=8.0K owner=nobody:nogroup perms=755

<a id="7-ssl-tls-certificates"></a>

## 7. SSL / TLS CERTIFICATES

- Certificate : [nginx.crt](file:///etc/ssl/certs/nginx/nginx.crt) (`/etc/ssl/certs/nginx/nginx.crt`) (configured at [nginx.localhost.com.conf:13](file:///etc/nginx/conf.d/nginx.localhost.com.conf#L13) (`/etc/nginx/conf.d/nginx.localhost.com.conf:13`))
-   Subject   : C = US, ST = State, L = City, O = LocalHost, CN = nginx.localhost.com
-   Issuer    : C = US, ST = State, L = City, O = LocalHost, CN = nginx.localhost.com
-   SANs      : n/a
-   Expires   : Nov 14 12:27:30 2027 GMT (364 days remaining)
-   Key / Sig : 2048 bit / sha256WithRSAEncryption
- **[ OK ]** Certificate /etc/ssl/certs/nginx/nginx.crt validity OK (364 days remaining)

### Private key permissions

- **[ OK ]** Private key /etc/ssl/certs/nginx/nginx.key permissions OK (600 nobody:nogroup)

<a id="8-security-audit-config-based"></a>

## 8. SECURITY AUDIT (config-based)


### Information disclosure

- **[WARN] (`WARN-3`)** server_tokens is not set to 'off' - Nginx version is exposed in HTTP headers and error pages
  - **Where**: [nginx.conf:21](file:///etc/nginx/nginx.conf#L21) (`/etc/nginx/nginx.conf:21`)
  - **Reference**: <https://nginx.org/en/docs/http/ngx_http_core_module.html#server_tokens>
  - **How to Fix**: Uncomment or add 'server_tokens off;' inside the http {} block in /etc/nginx/nginx.conf
- Consider adding: proxy_hide_header X-Powered-By;

### TLS protocol & cipher policy

- ssl_protocols configured: TLSv1 TLSv1.1 TLSv1.2 TLSv1.3  TLSv1.2 TLSv1.3 
- **[FAIL] (`FAIL-2`)** Deprecated/insecure TLS protocols enabled (SSLv3/TLSv1/TLSv1.1)
  - **Where**: [nginx.conf:33](file:///etc/nginx/nginx.conf#L33) (`/etc/nginx/nginx.conf:33`)
  - **Reference**: <https://ssl-config.mozilla.org/#server=nginx>
  - **How to Fix**: Set 'ssl_protocols TLSv1.2 TLSv1.3;' in /etc/nginx/nginx.conf and remove TLSv1 / TLSv1.1
- **[ OK ]** TLSv1.3 enabled
- ssl_ciphers HIGH:!aNULL:!MD5;
- **[FAIL] (`FAIL-3`)** Weak TLS cipher suites allowed in ssl_ciphers
  - **Where**: [nginx.localhost.com.conf:18](file:///etc/nginx/conf.d/nginx.localhost.com.conf#L18) (`/etc/nginx/conf.d/nginx.localhost.com.conf:18`)
  - **Reference**: <https://ssl-config.mozilla.org/#server=nginx>
  - **How to Fix**: Update ssl_ciphers using Mozilla Intermediate TLS configuration
- **[WARN] (`WARN-4`)** ssl_session_cache is not configured (impacts TLS handshake performance)
  - **Where**: [nginx.conf:12](file:///etc/nginx/nginx.conf#L12) (`/etc/nginx/nginx.conf:12`)
  - **Reference**: <https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_session_cache>
  - **How to Fix**: Add 'ssl_session_cache shared:SSL:10m; ssl_session_timeout 1d;' in http {} block of /etc/nginx/nginx.conf

### Security headers (add_header)

- **[WARN] (`WARN-5`)** HTTP security header 'Strict-Transport-Security' is missing from configuration
  - **Where**: [nginx.localhost.com.conf:1](file:///etc/nginx/conf.d/nginx.localhost.com.conf#L1) (`/etc/nginx/conf.d/nginx.localhost.com.conf:1`)
  - **Reference**: <https://owasp.org/www-project-secure-headers/>
  - **How to Fix**: Add 'add_header Strict-Transport-Security "..." always;' to your server {} block or shared security snippet
- **[WARN] (`WARN-6`)** HTTP security header 'X-Frame-Options' is missing from configuration
  - **Where**: [nginx.localhost.com.conf:1](file:///etc/nginx/conf.d/nginx.localhost.com.conf#L1) (`/etc/nginx/conf.d/nginx.localhost.com.conf:1`)
  - **Reference**: <https://owasp.org/www-project-secure-headers/>
  - **How to Fix**: Add 'add_header X-Frame-Options "..." always;' to your server {} block or shared security snippet
- **[WARN] (`WARN-7`)** HTTP security header 'X-Content-Type-Options' is missing from configuration
  - **Where**: [nginx.localhost.com.conf:1](file:///etc/nginx/conf.d/nginx.localhost.com.conf#L1) (`/etc/nginx/conf.d/nginx.localhost.com.conf:1`)
  - **Reference**: <https://owasp.org/www-project-secure-headers/>
  - **How to Fix**: Add 'add_header X-Content-Type-Options "..." always;' to your server {} block or shared security snippet
- **[WARN] (`WARN-8`)** HTTP security header 'Content-Security-Policy' is missing from configuration
  - **Where**: [nginx.localhost.com.conf:1](file:///etc/nginx/conf.d/nginx.localhost.com.conf#L1) (`/etc/nginx/conf.d/nginx.localhost.com.conf:1`)
  - **Reference**: <https://owasp.org/www-project-secure-headers/>
  - **How to Fix**: Add 'add_header Content-Security-Policy "..." always;' to your server {} block or shared security snippet
- **[WARN] (`WARN-9`)** HTTP security header 'Referrer-Policy' is missing from configuration
  - **Where**: [nginx.localhost.com.conf:1](file:///etc/nginx/conf.d/nginx.localhost.com.conf#L1) (`/etc/nginx/conf.d/nginx.localhost.com.conf:1`)
  - **Reference**: <https://owasp.org/www-project-secure-headers/>
  - **How to Fix**: Add 'add_header Referrer-Policy "..." always;' to your server {} block or shared security snippet
- **[WARN] (`WARN-10`)** HTTP security header 'Permissions-Policy' is missing from configuration
  - **Where**: [nginx.localhost.com.conf:1](file:///etc/nginx/conf.d/nginx.localhost.com.conf#L1) (`/etc/nginx/conf.d/nginx.localhost.com.conf:1`)
  - **Reference**: <https://owasp.org/www-project-secure-headers/>
  - **How to Fix**: Add 'add_header Permissions-Policy "..." always;' to your server {} block or shared security snippet

### HTTP -> HTTPS redirection

- **[ OK ]** HTTP -> HTTPS redirect present
- HTTP/2 not enabled (consider adding 'http2' to listen 443)

### Rate limiting / DoS protection

- **[WARN] (`WARN-11`)** No limit_req_zone defined (no request rate limiting against brute-force/DDoS)
  - **Where**: [nginx.conf:12](file:///etc/nginx/nginx.conf#L12) (`/etc/nginx/nginx.conf:12`)
  - **Reference**: <https://nginx.org/en/docs/http/ngx_http_limit_req_module.html#limit_req_zone>
  - **How to Fix**: Add 'limit_req_zone $binary_remote_addr zone=req_limit:10m rate=10r/s;' in http {} block of /etc/nginx/nginx.conf
- **[WARN] (`WARN-12`)** limit_req is not applied to any server or location context
  - **Where**: [nginx.localhost.com.conf:1](file:///etc/nginx/conf.d/nginx.localhost.com.conf#L1) (`/etc/nginx/conf.d/nginx.localhost.com.conf:1`)
  - **Reference**: <https://nginx.org/en/docs/http/ngx_http_limit_req_module.html#limit_req>
  - **How to Fix**: Apply 'limit_req zone=req_limit burst=20 nodelay;' inside sensitive server/location blocks
- client_max_body_size default (1m)

### Dangerous / risky patterns

- **[WARN] (`WARN-13`)** No location rule blocking hidden dotfiles (/.git, /.env, /.htpasswd)
  - **Where**: [nginx.localhost.com.conf:1](file:///etc/nginx/conf.d/nginx.localhost.com.conf#L1) (`/etc/nginx/conf.d/nginx.localhost.com.conf:1`)
  - **Reference**: <https://nginx.org/en/docs/http/ngx_http_core_module.html#location>
  - **How to Fix**: Add 'location ~ /\.(?!well-known).* { deny all; }' to server {} blocks

### Access control

- auth_basic protected locations: 0
0

### ModSecurity / WAF

- ModSecurity/WAF not detected in nginx

<a id="9-file-directory-permissions"></a>

## 9. FILE & DIRECTORY PERMISSIONS

- [nginx.conf](file:///etc/nginx/nginx.conf) (`/etc/nginx/nginx.conf`)  perms=644 owner=nobody:nogroup
- **[ OK ]** No world-writable config files in /etc/nginx

### Web roots - world-writable & sensitive files

- **[ OK ]** Web root /var/www/html has no world-writable files
- **[ OK ]** Web root /var/www/html/nginx.localhost.com has no world-writable files

### Log dir permissions


```text
drwxr-xr-x 2 nobody nogroup 4096 Nov 14 17:33 /var/log/nginx
```


<a id="10-system-level-hardening"></a>

## 10. SYSTEM-LEVEL HARDENING


### Firewall

- **[WARN] (`WARN-14`)** No active host firewall rules detected ( or requires root to inspect iptables/nftables )
  - **Where**: [etc](file:///etc) (`/etc`)
  - **Reference**: <https://wiki.debian.org/Uncomplicated%20Firewall%20%28ufw%29>
  - **How to Fix**: Enable host firewall (e.g. sudo ufw allow 'Nginx Full' && sudo ufw enable) or run audit with sudo

### Fail2ban

- **[WARN] (`WARN-15`)** fail2ban is not installed (recommended for nginx-http-auth and bot/scanner rate-banning)
  - **Where**: [etc](file:///etc) (`/etc`)
  - **Reference**: <https://www.fail2ban.org/wiki/index.php/Main_Page>
  - **How to Fix**: Install fail2ban: sudo apt-get install -y fail2ban

### SELinux / AppArmor


### Kernel network tunables relevant to web servers


```text
net.core.somaxconn                   4096
net.ipv4.tcp_max_syn_backlog         256
net.ipv4.tcp_syncookies              1
net.ipv4.ip_local_port_range         32768	60999
net.ipv4.tcp_tw_reuse                2
fs.file-max                          386291
```


### Auto security updates


```text
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
```


### Pending security updates


```text
apt-transport-https/oldstable-security,oldstable-security 2.6.2 all [upgradable from: 2.6.1]
apt-utils/oldstable-security 2.6.2 amd64 [upgradable from: 2.6.1]
apt/oldstable-security 2.6.2 amd64 [upgradable from: 2.6.1]
bind9-dnsutils/oldstable-security 1:9.18.49-1~deb12u3 amd64 [upgradable from: 1:9.18.33-1~deb12u2]
bind9-host/oldstable-security 1:9.18.49-1~deb12u3 amd64 [upgradable from: 1:9.18.33-1~deb12u2]
bind9-libs/oldstable-security 1:9.18.49-1~deb12u3 amd64 [upgradable from: 1:9.18.33-1~deb12u2]
cups-bsd/oldstable,oldstable-security 2.4.2-3+deb12u9 amd64 [upgradable from: 2.4.2-3+deb12u8]
cups-client/oldstable,oldstable-security 2.4.2-3+deb12u9 amd64 [upgradable from: 2.4.2-3+deb12u8]
cups-common/oldstable,oldstable,oldstable-security,oldstable-security 2.4.2-3+deb12u9 all [upgradable from: 2.4.2-3+deb12u8]
cups-core-drivers/oldstable,oldstable-security 2.4.2-3+deb12u9 amd64 [upgradable from: 2.4.2-3+deb12u8]
```


<a id="11-logs-locations-size-rotation"></a>

## 11. LOGS - LOCATIONS, SIZE, ROTATION


### Log files

- Log file [access.log](file:///var/log/nginx/access.log) (`/var/log/nginx/access.log`) — size=4.0K mtime=2026-11-14 18:43:01
- Log file [nginx.localhost.com.access.log](file:///var/log/nginx/nginx.localhost.com.access.log) (`/var/log/nginx/nginx.localhost.com.access.log`) — size=4.0K mtime=2026-11-14 18:43:01
- Log file [error.log](file:///var/log/nginx/error.log) (`/var/log/nginx/error.log`) — size=0 mtime=2026-11-14 17:33:44
- Log file [nginx.localhost.com.error.log](file:///var/log/nginx/nginx.localhost.com.error.log) (`/var/log/nginx/nginx.localhost.com.error.log`) — size=0 mtime=2026-11-14 17:33:46
- Total /var/log/nginx size: 12K

### logrotate

- **[ OK ]** logrotate config present at [nginx](file:///etc/logrotate.d/nginx) (`/etc/logrotate.d/nginx`)

```text
/var/log/nginx/*.log {
	daily
	missingok
	rotate 14
	compress
	delaycompress
	notifempty
	create 0640 www-data adm
	sharedscripts
	prerotate
		if [ -d /etc/logrotate.d/httpd-prerotate ]; then \
			run-parts /etc/logrotate.d/httpd-prerotate; \
		fi \
	endscript
	postrotate
		invoke-rc.d nginx rotate >/dev/null 2>&1
	endscript
}
```


<a id="12-error-log-analysis"></a>

## 12. ERROR LOG ANALYSIS

- Cannot read error log [error.log](file:///var/log/nginx/error.log) (`/var/log/nginx/error.log`) (run with sudo to analyse error log contents)
- Analysing error log: [nginx.localhost.com.error.log](file:///var/log/nginx/nginx.localhost.com.error.log) (`/var/log/nginx/nginx.localhost.com.error.log`)
- **[ OK ]** Error log /var/log/nginx/nginx.localhost.com.error.log is empty (0 errors recorded)

<a id="13-access-log-traffic-analysis-assumes-combined-format"></a>

## 13. ACCESS LOG & TRAFFIC ANALYSIS (assumes combined format)

- Cannot read access log [access.log](file:///var/log/nginx/access.log) (`/var/log/nginx/access.log`) (run with sudo to analyse traffic)
- Analysing access log: [nginx.localhost.com.access.log](file:///var/log/nginx/nginx.localhost.com.access.log) (`/var/log/nginx/nginx.localhost.com.access.log`) (last 50000 of 7 lines)
- Time range: [14/Nov/2026:17:57:30 +0530]  ->  [14/Nov/2026:18:43:01 +0530]

### HTTP status code distribution


```text
      3 200
```


### Status classes


```text
2xx       3  (100.0%)
```


### Top 15 client IPs


```text
      7 127.0.0.1
```


### Top 15 requested URLs


```text
      4 400
      3 /
```


### Top 10 URLs returning 404


### Top 10 URLs returning 5xx


<a id="14-live-endpoint-checks-localhost"></a>

## 14. LIVE ENDPOINT CHECKS (localhost)

- Probing http://127.0.0.1 (Host: localhost, -k)

```text
(no response from http://127.0.0.1)
```

- Probing https://127.0.0.1 (Host: localhost, -k)

```text
(no response from https://127.0.0.1)
```


### Security headers on first named server over HTTPS

- Testing nginx.localhost.com via --resolve nginx.localhost.com:443:127.0.0.1
- No live HTTPS response on 127.0.0.1:443 for nginx.localhost.com (daemon stopped or port not listening)

### TLS handshake test on 127.0.0.1:443

- tls1 rejected or 127.0.0.1:443 not listening
- tls1_1 rejected or 127.0.0.1:443 not listening
- tls1_2 rejected or 127.0.0.1:443 not listening
- tls1_3 rejected or 127.0.0.1:443 not listening

<a id="15-performance-capacity-hints"></a>

## 15. PERFORMANCE & CAPACITY HINTS

- Theoretical max clients ~ worker_processes(2) x worker_connections(768) = 1536 (halve for reverse proxy)
- worker_rlimit_nofile not set - ensure ulimit >= 2 x worker_connections
- **[ OK ]** gzip compression enabled
- gzip_types not set (only text/html compressed by default)
- No proxy/fastcgi cache configured
- No expires/Cache-Control rules for static assets
- **[ OK ]** sendfile on

### nginx memory (RSS)


```text
total RSS: 0.0 MB across 0 processes
```


### Top 5 processes by memory


```text
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
ubuntu         1 19.7  3.5 2042168 142220 ?      Sl   19:02   0:00 /home/ubuntu/.gemini/bin/agy
ubuntu       830  0.0  0.1   8104  4272 pts/3    R+   19:02   0:00 ps aux --sort=-%mem
ubuntu        15  4.3  0.0  76892  3852 pts/3    S+   19:02   0:00 bash /home/ubuntu/code/github/raviautopilot/technical-notes/000_init/inst
ubuntu        13  0.0  0.0  76268  3324 pts/3    Ss+  19:02   0:00 bash -c /home/ubuntu/code/github/raviautopilot/technical-notes/000_init/i
ubuntu       829  0.0  0.0  76892  2056 pts/3    S+   19:02   0:00 bash /home/ubuntu/code/github/raviautopilot/technical-notes/000_init/inst
```


### Files/sockets open by nginx

- 0 open descriptors (lsof)

<a id="16-backends-related-services"></a>

## 16. BACKENDS & RELATED SERVICES


### Upstream/proxy targets reachability


### Common companion services


```text
docker             inactive (sysvinit)
```


### Cron jobs mentioning nginx / certbot

- No cron files mentioning nginx or certbot

<a id="17-config-backup-change-tracking"></a>

## 17. CONFIG BACKUP & CHANGE TRACKING

- 10 most recently modified files in /etc/nginx:
- 2026-11-14 17:57 — [nginx.localhost.com.conf](file:///etc/nginx/conf.d/nginx.localhost.com.conf) (`/etc/nginx/conf.d/nginx.localhost.com.conf`)
- 2026-07-18 21:48 — [win-utf](file:///etc/nginx/win-utf) (`/etc/nginx/win-utf`)
- 2026-07-18 21:48 — [uwsgi_params](file:///etc/nginx/uwsgi_params) (`/etc/nginx/uwsgi_params`)
- 2026-07-18 21:48 — [snakeoil.conf](file:///etc/nginx/snippets/snakeoil.conf) (`/etc/nginx/snippets/snakeoil.conf`)
- 2026-07-18 21:48 — [fastcgi-php.conf](file:///etc/nginx/snippets/fastcgi-php.conf) (`/etc/nginx/snippets/fastcgi-php.conf`)
- 2026-07-18 21:48 — [default](file:///etc/nginx/sites-available/default) (`/etc/nginx/sites-available/default`)
- 2026-07-18 21:48 — [scgi_params](file:///etc/nginx/scgi_params) (`/etc/nginx/scgi_params`)
- 2026-07-18 21:48 — [proxy_params](file:///etc/nginx/proxy_params) (`/etc/nginx/proxy_params`)
- 2026-07-18 21:48 — [nginx.conf](file:///etc/nginx/nginx.conf) (`/etc/nginx/nginx.conf`)
- 2026-07-18 21:48 — [mime.types](file:///etc/nginx/mime.types) (`/etc/nginx/mime.types`)
- Config not under version control (consider git or etckeeper in /etc/nginx)
