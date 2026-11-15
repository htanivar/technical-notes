# Nginx Server Diagnostic & Security Audit Report

| Property | Value |
| :--- | :--- |
| **Overall Health** | **NEEDS ATTENTION (15 WARN)** |
| **Checks Summary** | **OK:** `16` &nbsp; **WARN:** `15` &nbsp; **FAIL:** `0` |
| **Generated At** | `2026-11-15 12:47:37 IST` |
| **Host / OS** | `ravinath.prod` (Ubuntu 22.04.4 LTS) |
| **Nginx Version** | `nginx/1.18.0 (Ubuntu)` — Binary: [nginx](file:///usr/sbin/nginx) (`/usr/sbin/nginx`) |
| **Main Config** | [nginx.conf](file:///etc/nginx/nginx.conf) (`/etc/nginx/nginx.conf`) |
| **Audit Script** | [status_nginx.sh](file:///home/ravi_adm/code/technical-notes/000_init/install/nginx/status_nginx.sh) (`/home/ravi_adm/code/technical-notes/000_init/install/nginx/status_nginx.sh`) |

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

### Warnings (`[WARN]` — Recommended Hardening & Fixes)

| ID | Section | Warning Details | Where (File / Line Link) | Docs | How to Fix |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **WARN-1** | [7. SSL / TLS CERTIFICATES](#7-ssl-tls-certificates) | No ssl_certificate directives found - HTTPS is not configured | [default:21](file:///etc/nginx/sites-enabled/default#L21) (`/etc/nginx/sites-enabled/default:21`) | [Docs](https://nginx.org/en/docs/http/configuring_https_servers.html) | Configure TLS certificates (e.g. via Certbot: sudo certbot --nginx) and listen on 443 ssl |
| **WARN-2** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | server_tokens is not set to 'off' - Nginx version is exposed in HTTP headers and error pages | [nginx.conf:20](file:///etc/nginx/nginx.conf#L20) (`/etc/nginx/nginx.conf:20`) | [Docs](https://nginx.org/en/docs/http/ngx_http_core_module.html#server_tokens) | Uncomment or add 'server_tokens off;' inside the http {} block in /etc/nginx/nginx.conf |
| **WARN-3** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | ssl_session_cache is not configured (impacts TLS handshake performance) | [nginx.conf:11](file:///etc/nginx/nginx.conf#L11) (`/etc/nginx/nginx.conf:11`) | [Docs](https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_session_cache) | Add 'ssl_session_cache shared:SSL:10m; ssl_session_timeout 1d;' in http {} block of /etc/nginx/nginx.conf |
| **WARN-4** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | HTTP security header 'Strict-Transport-Security' is missing from configuration | [default:21](file:///etc/nginx/sites-enabled/default#L21) (`/etc/nginx/sites-enabled/default:21`) | [Docs](https://owasp.org/www-project-secure-headers/) | Add 'add_header Strict-Transport-Security "..." always;' to your server {} block or shared security snippet |
| **WARN-5** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | HTTP security header 'X-Frame-Options' is missing from configuration | [default:21](file:///etc/nginx/sites-enabled/default#L21) (`/etc/nginx/sites-enabled/default:21`) | [Docs](https://owasp.org/www-project-secure-headers/) | Add 'add_header X-Frame-Options "..." always;' to your server {} block or shared security snippet |
| **WARN-6** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | HTTP security header 'X-Content-Type-Options' is missing from configuration | [default:21](file:///etc/nginx/sites-enabled/default#L21) (`/etc/nginx/sites-enabled/default:21`) | [Docs](https://owasp.org/www-project-secure-headers/) | Add 'add_header X-Content-Type-Options "..." always;' to your server {} block or shared security snippet |
| **WARN-7** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | HTTP security header 'Content-Security-Policy' is missing from configuration | [default:21](file:///etc/nginx/sites-enabled/default#L21) (`/etc/nginx/sites-enabled/default:21`) | [Docs](https://owasp.org/www-project-secure-headers/) | Add 'add_header Content-Security-Policy "..." always;' to your server {} block or shared security snippet |
| **WARN-8** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | HTTP security header 'Referrer-Policy' is missing from configuration | [default:21](file:///etc/nginx/sites-enabled/default#L21) (`/etc/nginx/sites-enabled/default:21`) | [Docs](https://owasp.org/www-project-secure-headers/) | Add 'add_header Referrer-Policy "..." always;' to your server {} block or shared security snippet |
| **WARN-9** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | HTTP security header 'Permissions-Policy' is missing from configuration | [default:21](file:///etc/nginx/sites-enabled/default#L21) (`/etc/nginx/sites-enabled/default:21`) | [Docs](https://owasp.org/www-project-secure-headers/) | Add 'add_header Permissions-Policy "..." always;' to your server {} block or shared security snippet |
| **WARN-10** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | Port 80 is served without an automatic HTTP -> HTTPS redirect | [default:22](file:///etc/nginx/sites-enabled/default#L22) (`/etc/nginx/sites-enabled/default:22`) | [Docs](https://nginx.org/en/docs/http/ngx_http_rewrite_module.html#return) | Add 'return 301 https://$host$request_uri;' in the port 80 server {} block |
| **WARN-11** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | No limit_req_zone defined (no request rate limiting against brute-force/DDoS) | [nginx.conf:11](file:///etc/nginx/nginx.conf#L11) (`/etc/nginx/nginx.conf:11`) | [Docs](https://nginx.org/en/docs/http/ngx_http_limit_req_module.html#limit_req_zone) | Add 'limit_req_zone $binary_remote_addr zone=req_limit:10m rate=10r/s;' in http {} block of /etc/nginx/nginx.conf |
| **WARN-12** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | limit_req is not applied to any server or location context | [default:21](file:///etc/nginx/sites-enabled/default#L21) (`/etc/nginx/sites-enabled/default:21`) | [Docs](https://nginx.org/en/docs/http/ngx_http_limit_req_module.html#limit_req) | Apply 'limit_req zone=req_limit burst=20 nodelay;' inside sensitive server/location blocks |
| **WARN-13** | [8. SECURITY AUDIT (config-based)](#8-security-audit-config-based) | No location rule blocking hidden dotfiles (/.git, /.env, /.htpasswd) | [default:21](file:///etc/nginx/sites-enabled/default#L21) (`/etc/nginx/sites-enabled/default:21`) | [Docs](https://nginx.org/en/docs/http/ngx_http_core_module.html#location) | Add 'location ~ /\.(?!well-known).* { deny all; }' to server {} blocks |
| **WARN-14** | [10. SYSTEM-LEVEL HARDENING](#10-system-level-hardening) | fail2ban is not installed (recommended for nginx-http-auth and bot/scanner rate-banning) | [etc](file:///etc) (`/etc`) | [Docs](https://www.fail2ban.org/wiki/index.php/Main_Page) | Install fail2ban: sudo apt-get install -y fail2ban |
| **WARN-15** | [10. SYSTEM-LEVEL HARDENING](#10-system-level-hardening) | System reboot required to apply kernel/security updates | [reboot-required](file:///var/run/reboot-required) (`/var/run/reboot-required`) | [Docs](https://wiki.debian.org/UnattendedUpgrades) | Schedule a maintenance window and reboot the host: sudo reboot |

---


<a id="1-system-overview"></a>

## 1. SYSTEM OVERVIEW

- OS        : Ubuntu 22.04.4 LTS
- Kernel    : 5.15.0-198-generic  (x86_64)
- Uptime    : up 4 weeks, 3 days, 4 hours, 43 minutes
- Load avg  : 0.03 0.18 0.13   CPUs: 8

### Memory


```text
               total        used        free      shared  buff/cache   available
Mem:            17Gi       1.5Gi       7.7Gi       1.0Mi       8.3Gi        15Gi
Swap:             0B          0B          0B
```


### Disk usage


```text
Filesystem                        Type  Size  Used Avail Use% Mounted on
/dev/mapper/ubuntu--vg-ubuntu--lv ext4  235G   16G  210G   7% /
/dev/vda2                         ext4  1.7G  259M  1.4G  16% /boot
```


### Disk inodes


```text
Filesystem                          Inodes  IUsed    IFree IUse% Mounted on
/dev/mapper/ubuntu--vg-ubuntu--lv 15613952 243922 15370030    2% /
/dev/vda2                           114688    320   114368    1% /boot
```


### Public / local IPs


```text
enp1s0           UP             69.197.134.216/24 fe80::e8be:acff:fea2:23f6/64 
docker0          DOWN           172.17.0.1/16 
```


<a id="2-nginx-binary-build"></a>

## 2. NGINX BINARY & BUILD

- Binary    : [nginx](file:///usr/sbin/nginx) (`/usr/sbin/nginx`)
- Version   : 1.18.0 (Ubuntu)
- Config    : [nginx.conf](file:///etc/nginx/nginx.conf) (`/etc/nginx/nginx.conf`)

### Build info (nginx -V)


```text
nginx version: nginx/1.18.0 (Ubuntu)
built with OpenSSL 3.0.2 15 Mar 2022
TLS SNI support enabled
configure arguments:
    --with-cc-opt='-g -O2 -ffile-prefix-map=/build/nginx-ZjoGUf/nginx-1.18.0=. -flto=auto -ffat-lto-objects -flto=auto -ffat-lto-objects -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2'
    --with-ld-opt='-Wl,-Bsymbolic-functions -flto=auto -ffat-lto-objects -flto=auto -Wl,-z,relro -Wl,-z,now -fPIC'
    --prefix=/usr/share/nginx
    --conf-path=/etc/nginx/nginx.conf
    --http-log-path=/var/log/nginx/access.log
    --error-log-path=/var/log/nginx/error.log
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
    --add-dynamic-module=/build/nginx-ZjoGUf/nginx-1.18.0/debian/modules/http-geoip2
    --with-http_addition_module
    --with-http_gunzip_module
    --with-http_gzip_static_module
    --with-http_sub_module
```


### Modules compiled in / dynamic


```text
--add-dynamic-module=/build/nginx-ZjoGUf/nginx-1.18.0/debian/modules/http-geoip2
--with-http_addition_module
--with-http_auth_request_module
--with-http_dav_module
--with-http_gunzip_module
--with-http_gzip_static_module
--with-http_realip_module
--with-http_slice_module
--with-http_ssl_module
--with-http_stub_status_module
--with-http_sub_module
dynamic: 50-mod-http-geoip2.conf
dynamic: 50-mod-http-image-filter.conf
dynamic: 50-mod-http-xslt-filter.conf
dynamic: 50-mod-mail.conf
dynamic: 50-mod-stream.conf
dynamic: 70-mod-stream-geoip2.conf
load_module modules/ngx_http_geoip2_module.so;
load_module modules/ngx_http_image_filter_module.so;
load_module modules/ngx_http_xslt_filter_module.so;
load_module modules/ngx_mail_module.so;
load_module modules/ngx_stream_module.so;
load_module modules/ngx_stream_geoip2_module.so;
```


### Package info


```text
libnginx-mod-http-geoip2 1.18.0-6ubuntu14.22
libnginx-mod-http-image-filter 1.18.0-6ubuntu14.22
libnginx-mod-http-xslt-filter 1.18.0-6ubuntu14.22
libnginx-mod-mail 1.18.0-6ubuntu14.22
libnginx-mod-stream 1.18.0-6ubuntu14.22
libnginx-mod-stream-geoip2 1.18.0-6ubuntu14.22
nginx 1.18.0-6ubuntu14.22
nginx-common 1.18.0-6ubuntu14.22
nginx-core 1.18.0-6ubuntu14.22
```


### Update availability

- **[ OK ]** No nginx update pending (per local apt cache)
- Security Advisories: https://nginx.org/en/security_advisories.html

<a id="3-service-status-processes"></a>

## 3. SERVICE STATUS & PROCESSES

- **[ OK ]** nginx systemd service is ACTIVE
- **[ OK ]** nginx service is enabled at boot

```text
* nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
     Active: active (running) since Sun 2026-11-15 12:43:19 IST; 4min 19s ago
       Docs: man:nginx(8)
    Process: 1529774 ExecReload=/usr/sbin/nginx -g daemon on; master_process on; -s reload (code=exited, status=0/SUCCESS)
   Main PID: 1527287 (nginx)
      Tasks: 9 (limit: 21436)
     Memory: 7.8M
        CPU: 165ms
     CGroup: /system.slice/nginx.service
             |-1527287 "nginx: master process /usr/sbin/nginx -g daemon on; master_process on;"
             |-1529775 "nginx: worker process" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ""
             |-1529776 "nginx: worker process" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ""
             |-1529777 "nginx: worker process" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ""
             |-1529778 "nginx: worker process" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ""
```


### Recent service journal (last 10)


```text
Nov 15 12:34:25 ravinath.prod systemd[1]: nginx.service: Unit cannot be reloaded because it is inactive.
Nov 15 12:43:19 ravinath.prod systemd[1]: Starting A high performance web server and a reverse proxy server...
Nov 15 12:43:19 ravinath.prod systemd[1]: Started A high performance web server and a reverse proxy server.
Nov 15 12:47:11 ravinath.prod systemd[1]: Reloading A high performance web server and a reverse proxy server...
Nov 15 12:47:11 ravinath.prod systemd[1]: Reloaded A high performance web server and a reverse proxy server.
```


### Config syntax test (nginx -t)

- **[ OK ]** Configuration syntax OK (nginx -t passed)

### Processes


```text
    PID    PPID USER     %CPU %MEM   RSS     ELAPSED CMD
1527287       1 root      0.0  0.0 12264       04:20 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
1529775 1527287 www-data  0.0  0.0  5684       00:28 nginx: worker process
1529776 1527287 www-data  0.0  0.0  5684       00:28 nginx: worker process
1529777 1527287 www-data  0.0  0.0  5684       00:28 nginx: worker process
1529778 1527287 www-data  0.0  0.0  5684       00:28 nginx: worker process
1529779 1527287 www-data  0.0  0.0  5684       00:28 nginx: worker process
1529780 1527287 www-data  0.0  0.0  5684       00:28 nginx: worker process
1529781 1527287 www-data  0.0  0.0  5684       00:28 nginx: worker process
1529782 1527287 www-data  0.0  0.0  5684       00:28 nginx: worker process
```

- **[ OK ]** Master runs as root (normal, needed for ports <1024)
- **[ OK ]** Workers run as non-root user: www-data
- Active worker processes: 8   (CPU cores: 8)
- PID file configured: /run/nginx.pid

### Open-file limit of master


```text
Max open files            1024                 524288               files     
```

- Open FDs (master): 23

<a id="4-listening-ports-connections"></a>

## 4. LISTENING PORTS & CONNECTIONS


### Sockets owned by nginx


```text
tcp   LISTEN 0      511          0.0.0.0:80         0.0.0.0:*    users:(("nginx",pid=1529782,fd=6),("nginx",pid=1529781,fd=6),("nginx",pid=1529780,fd=6),("nginx",pid=1529779,fd=6),("nginx",pid=1529778,fd=6),("nginx",pid=1529777,fd=6),("nginx",pid=1529776,fd=6),("nginx",pid=1529775,fd=6),("nginx",pid=1527287,fd=6))
tcp   LISTEN 0      511             [::]:80            [::]:*    users:(("nginx",pid=1529782,fd=7),("nginx",pid=1529781,fd=7),("nginx",pid=1529780,fd=7),("nginx",pid=1529779,fd=7),("nginx",pid=1529778,fd=7),("nginx",pid=1529777,fd=7),("nginx",pid=1529776,fd=7),("nginx",pid=1529775,fd=7),("nginx",pid=1527287,fd=7))
```


### Ports declared in config


```text
      1 [::]:80 default_server
      1 80 default_server
```


### TCP connection states (all :80/:443 traffic)


```text
LISTEN         2
```


### Top 10 client IPs currently connected


```text
(none)
```


### Other services listening publicly (potential exposure)


```text
0.0.0.0:80
0.0.0.0:22
[::]:80
[::]:22
*:8080
```


<a id="5-configuration-files-layout"></a>

## 5. CONFIGURATION FILES & LAYOUT

- Main config dir: [nginx](file:///etc/nginx) (`/etc/nginx`)

### Files loaded

- Loaded: [mime.types](file:///etc/nginx/mime.types) (`/etc/nginx/mime.types`)
- Loaded: [50-mod-http-geoip2.conf](file:///etc/nginx/modules-enabled/50-mod-http-geoip2.conf) (`/etc/nginx/modules-enabled/50-mod-http-geoip2.conf`)
- Loaded: [50-mod-http-image-filter.conf](file:///etc/nginx/modules-enabled/50-mod-http-image-filter.conf) (`/etc/nginx/modules-enabled/50-mod-http-image-filter.conf`)
- Loaded: [50-mod-http-xslt-filter.conf](file:///etc/nginx/modules-enabled/50-mod-http-xslt-filter.conf) (`/etc/nginx/modules-enabled/50-mod-http-xslt-filter.conf`)
- Loaded: [50-mod-mail.conf](file:///etc/nginx/modules-enabled/50-mod-mail.conf) (`/etc/nginx/modules-enabled/50-mod-mail.conf`)
- Loaded: [50-mod-stream.conf](file:///etc/nginx/modules-enabled/50-mod-stream.conf) (`/etc/nginx/modules-enabled/50-mod-stream.conf`)
- Loaded: [70-mod-stream-geoip2.conf](file:///etc/nginx/modules-enabled/70-mod-stream-geoip2.conf) (`/etc/nginx/modules-enabled/70-mod-stream-geoip2.conf`)
- Loaded: [nginx.conf](file:///etc/nginx/nginx.conf) (`/etc/nginx/nginx.conf`)
- Loaded: [default](file:///etc/nginx/sites-enabled/default) (`/etc/nginx/sites-enabled/default`)

### Directory tree


```text
/etc/nginx/sites-available:
  -rw-r--r-- 1 root root 2412 May 30  2023 default
/etc/nginx/sites-enabled:
  lrwxrwxrwx 1 root root   34 Nov 15 12:43 default -> /etc/nginx/sites-available/default
/etc/nginx/conf.d:

/etc/nginx/snippets:
  -rw-r--r-- 1 root root  423 May 30  2023 fastcgi-php.conf
  -rw-r--r-- 1 root root  217 May 30  2023 snakeoil.conf
/etc/nginx/modules-enabled:
  lrwxrwxrwx 1 root root   55 Nov 15 12:43 50-mod-http-geoip2.conf -> /usr/share/nginx/modules-available/mod-http-geoip2.conf
  lrwxrwxrwx 1 root root   61 Nov 15 12:43 50-mod-http-image-filter.conf -> /usr/share/nginx/modules-available/mod-http-image-filter.conf
  lrwxrwxrwx 1 root root   60 Nov 15 12:43 50-mod-http-xslt-filter.conf -> /usr/share/nginx/modules-available/mod-http-xslt-filter.conf
  lrwxrwxrwx 1 root root   48 Nov 15 12:43 50-mod-mail.conf -> /usr/share/nginx/modules-available/mod-mail.conf
  lrwxrwxrwx 1 root root   50 Nov 15 12:43 50-mod-stream.conf -> /usr/share/nginx/modules-available/mod-stream.conf
  lrwxrwxrwx 1 root root   57 Nov 15 12:43 70-mod-stream-geoip2.conf -> /usr/share/nginx/modules-available/mod-stream-geoip2.conf
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
access_log /var/log/nginx/access.log;
```

- **[ OK ]** worker_processes auto

<a id="6-sites-virtual-hosts-parsed-from-effective-config"></a>

## 6. SITES / VIRTUAL HOSTS (parsed from effective config)


```text
[1] _
    file       : /etc/nginx/sites-enabled/default:21
    listen     : 80 default_server | [::]:80 default_server
    root       : /var/www/html
    locations  : 1     

Total server blocks: 1
```


### Domains (unique server_names)


```text
_
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
      1 location / {
```


### Web root(s): size & owner

- Web root [html](file:///var/www/html) (`/var/www/html`) — size=8.0K owner=root:root perms=755

<a id="7-ssl-tls-certificates"></a>

## 7. SSL / TLS CERTIFICATES

- **[WARN] (`WARN-1`)** No ssl_certificate directives found - HTTPS is not configured
  - **Where**: [default:21](file:///etc/nginx/sites-enabled/default#L21) (`/etc/nginx/sites-enabled/default:21`)
  - **Reference**: <https://nginx.org/en/docs/http/configuring_https_servers.html>
  - **How to Fix**: Configure TLS certificates (e.g. via Certbot: sudo certbot --nginx) and listen on 443 ssl

### Certbot certificates


```text

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
No certificates found.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

- Let's Encrypt live dir: README 
- certbot cron present: [certbot](file:///etc/cron.d/certbot) (`/etc/cron.d/certbot`)

<a id="8-security-audit-config-based"></a>

## 8. SECURITY AUDIT (config-based)


### Information disclosure

- **[WARN] (`WARN-2`)** server_tokens is not set to 'off' - Nginx version is exposed in HTTP headers and error pages
  - **Where**: [nginx.conf:20](file:///etc/nginx/nginx.conf#L20) (`/etc/nginx/nginx.conf:20`)
  - **Reference**: <https://nginx.org/en/docs/http/ngx_http_core_module.html#server_tokens>
  - **How to Fix**: Uncomment or add 'server_tokens off;' inside the http {} block in /etc/nginx/nginx.conf
- Consider adding: proxy_hide_header X-Powered-By;

### TLS protocol & cipher policy

- ssl_protocols configured: TLSv1.2 TLSv1.3  
- **[ OK ]** No legacy SSL/TLSv1.0/TLSv1.1 protocols enabled
- **[ OK ]** TLSv1.3 enabled
- ssl_ciphers not explicitly set (OpenSSL defaults used)
- **[WARN] (`WARN-3`)** ssl_session_cache is not configured (impacts TLS handshake performance)
  - **Where**: [nginx.conf:11](file:///etc/nginx/nginx.conf#L11) (`/etc/nginx/nginx.conf:11`)
  - **Reference**: <https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_session_cache>
  - **How to Fix**: Add 'ssl_session_cache shared:SSL:10m; ssl_session_timeout 1d;' in http {} block of /etc/nginx/nginx.conf

### Security headers (add_header)

- **[WARN] (`WARN-4`)** HTTP security header 'Strict-Transport-Security' is missing from configuration
  - **Where**: [default:21](file:///etc/nginx/sites-enabled/default#L21) (`/etc/nginx/sites-enabled/default:21`)
  - **Reference**: <https://owasp.org/www-project-secure-headers/>
  - **How to Fix**: Add 'add_header Strict-Transport-Security "..." always;' to your server {} block or shared security snippet
- **[WARN] (`WARN-5`)** HTTP security header 'X-Frame-Options' is missing from configuration
  - **Where**: [default:21](file:///etc/nginx/sites-enabled/default#L21) (`/etc/nginx/sites-enabled/default:21`)
  - **Reference**: <https://owasp.org/www-project-secure-headers/>
  - **How to Fix**: Add 'add_header X-Frame-Options "..." always;' to your server {} block or shared security snippet
- **[WARN] (`WARN-6`)** HTTP security header 'X-Content-Type-Options' is missing from configuration
  - **Where**: [default:21](file:///etc/nginx/sites-enabled/default#L21) (`/etc/nginx/sites-enabled/default:21`)
  - **Reference**: <https://owasp.org/www-project-secure-headers/>
  - **How to Fix**: Add 'add_header X-Content-Type-Options "..." always;' to your server {} block or shared security snippet
- **[WARN] (`WARN-7`)** HTTP security header 'Content-Security-Policy' is missing from configuration
  - **Where**: [default:21](file:///etc/nginx/sites-enabled/default#L21) (`/etc/nginx/sites-enabled/default:21`)
  - **Reference**: <https://owasp.org/www-project-secure-headers/>
  - **How to Fix**: Add 'add_header Content-Security-Policy "..." always;' to your server {} block or shared security snippet
- **[WARN] (`WARN-8`)** HTTP security header 'Referrer-Policy' is missing from configuration
  - **Where**: [default:21](file:///etc/nginx/sites-enabled/default#L21) (`/etc/nginx/sites-enabled/default:21`)
  - **Reference**: <https://owasp.org/www-project-secure-headers/>
  - **How to Fix**: Add 'add_header Referrer-Policy "..." always;' to your server {} block or shared security snippet
- **[WARN] (`WARN-9`)** HTTP security header 'Permissions-Policy' is missing from configuration
  - **Where**: [default:21](file:///etc/nginx/sites-enabled/default#L21) (`/etc/nginx/sites-enabled/default:21`)
  - **Reference**: <https://owasp.org/www-project-secure-headers/>
  - **How to Fix**: Add 'add_header Permissions-Policy "..." always;' to your server {} block or shared security snippet

### HTTP -> HTTPS redirection

- **[WARN] (`WARN-10`)** Port 80 is served without an automatic HTTP -> HTTPS redirect
  - **Where**: [default:22](file:///etc/nginx/sites-enabled/default#L22) (`/etc/nginx/sites-enabled/default:22`)
  - **Reference**: <https://nginx.org/en/docs/http/ngx_http_rewrite_module.html#return>
  - **How to Fix**: Add 'return 301 https://$host$request_uri;' in the port 80 server {} block
- HTTP/2 not enabled (consider adding 'http2' to listen 443)

### Rate limiting / DoS protection

- **[WARN] (`WARN-11`)** No limit_req_zone defined (no request rate limiting against brute-force/DDoS)
  - **Where**: [nginx.conf:11](file:///etc/nginx/nginx.conf#L11) (`/etc/nginx/nginx.conf:11`)
  - **Reference**: <https://nginx.org/en/docs/http/ngx_http_limit_req_module.html#limit_req_zone>
  - **How to Fix**: Add 'limit_req_zone $binary_remote_addr zone=req_limit:10m rate=10r/s;' in http {} block of /etc/nginx/nginx.conf
- **[WARN] (`WARN-12`)** limit_req is not applied to any server or location context
  - **Where**: [default:21](file:///etc/nginx/sites-enabled/default#L21) (`/etc/nginx/sites-enabled/default:21`)
  - **Reference**: <https://nginx.org/en/docs/http/ngx_http_limit_req_module.html#limit_req>
  - **How to Fix**: Apply 'limit_req zone=req_limit burst=20 nodelay;' inside sensitive server/location blocks
- client_max_body_size default (1m)

### Dangerous / risky patterns

- **[WARN] (`WARN-13`)** No location rule blocking hidden dotfiles (/.git, /.env, /.htpasswd)
  - **Where**: [default:21](file:///etc/nginx/sites-enabled/default#L21) (`/etc/nginx/sites-enabled/default:21`)
  - **Reference**: <https://nginx.org/en/docs/http/ngx_http_core_module.html#location>
  - **How to Fix**: Add 'location ~ /\.(?!well-known).* { deny all; }' to server {} blocks

### Access control

- auth_basic protected locations: 0
0

### ModSecurity / WAF

- ModSecurity/WAF not detected in nginx

<a id="9-file-directory-permissions"></a>

## 9. FILE & DIRECTORY PERMISSIONS

- [nginx.conf](file:///etc/nginx/nginx.conf) (`/etc/nginx/nginx.conf`)  perms=644 owner=root:root
- **[ OK ]** No world-writable config files in /etc/nginx

### Web roots - world-writable & sensitive files

- **[ OK ]** Web root /var/www/html has no world-writable files

### Log dir permissions


```text
drwxr-xr-x 2 root adm 4096 Nov 15 12:43 /var/log/nginx
```


<a id="10-system-level-hardening"></a>

## 10. SYSTEM-LEVEL HARDENING


### Firewall


```text
Status: inactive
```


### Fail2ban

- **[WARN] (`WARN-14`)** fail2ban is not installed (recommended for nginx-http-auth and bot/scanner rate-banning)
  - **Where**: [etc](file:///etc) (`/etc`)
  - **Reference**: <https://www.fail2ban.org/wiki/index.php/Main_Page>
  - **How to Fix**: Install fail2ban: sudo apt-get install -y fail2ban

### SELinux / AppArmor


```text
31 profiles are loaded.
```


### Kernel network tunables relevant to web servers


```text
net.core.somaxconn                   4096
net.ipv4.tcp_max_syn_backlog         2048
net.ipv4.tcp_syncookies              1
net.ipv4.ip_local_port_range         32768	60999
net.ipv4.tcp_tw_reuse                2
fs.file-max                          9223372036854775807
```


### Auto security updates


```text
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
```


### Pending security updates

- **[WARN] (`WARN-15`)** System reboot required to apply kernel/security updates
  - **Where**: [reboot-required](file:///var/run/reboot-required) (`/var/run/reboot-required`)
  - **Reference**: <https://wiki.debian.org/UnattendedUpgrades>
  - **How to Fix**: Schedule a maintenance window and reboot the host: sudo reboot

<a id="11-logs-locations-size-rotation"></a>

## 11. LOGS - LOCATIONS, SIZE, ROTATION


### Log files

- Log file [access.log](file:///var/log/nginx/access.log) (`/var/log/nginx/access.log`) — size=4.0K mtime=2026-11-15 12:44:25
- Log file [error.log](file:///var/log/nginx/error.log) (`/var/log/nginx/error.log`) — size=4.0K mtime=2026-11-15 12:47:11
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

- Analysing error log: [error.log](file:///var/log/nginx/error.log) (`/var/log/nginx/error.log`)

### Entries by severity (last 50000 lines)


```text
      2 [notice]
```


### Top 10 error messages


```text
      1 [notice] 1529774#1529774: signal process started
      1 [notice] 1527287#1527287: using inherited sockets from "6;7;"
```


### Last 15 error/crit entries


<a id="13-access-log-traffic-analysis-assumes-combined-format"></a>

## 13. ACCESS LOG & TRAFFIC ANALYSIS (assumes combined format)

- Analysing access log: [access.log](file:///var/log/nginx/access.log) (`/var/log/nginx/access.log`) (last 50000 of 1 lines)
- Time range: [15/Nov/2026:12:44:25 +0530]  ->  [15/Nov/2026:12:44:25 +0530]

### HTTP status code distribution


```text
      1 200
```


### Status classes


```text
2xx       1  (100.0%)
```


### Top 15 client IPs


```text
      1 127.0.0.1
```


### Top 15 requested URLs


```text
      1 /
```


### Top 10 URLs returning 404


### Top 10 URLs returning 5xx


<a id="14-live-endpoint-checks-localhost"></a>

## 14. LIVE ENDPOINT CHECKS (localhost)

- Probing http://127.0.0.1 (Host: localhost, -k)

```text
HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Date: Sun, 15 Nov 2026 07:17:41 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Sun, 15 Nov 2026 07:13:18 GMT
Connection: keep-alive
ETag: "6af95b8e-264"
Accept-Ranges: bytes

```

- Probing https://127.0.0.1 (Host: localhost, -k)

```text
(no response from https://127.0.0.1)
```


### Security headers on first named server over HTTPS


### TLS handshake test on 127.0.0.1:443

- tls1 rejected or 127.0.0.1:443 not listening
- tls1_1 rejected or 127.0.0.1:443 not listening
- tls1_2 rejected or 127.0.0.1:443 not listening
- tls1_3 rejected or 127.0.0.1:443 not listening

<a id="15-performance-capacity-hints"></a>

## 15. PERFORMANCE & CAPACITY HINTS

- Theoretical max clients ~ worker_processes(8) x worker_connections(768) = 6144 (halve for reverse proxy)
- worker_rlimit_nofile not set - ensure ulimit >= 2 x worker_connections
- **[ OK ]** gzip compression enabled
- gzip_types not set (only text/html compressed by default)
- No proxy/fastcgi cache configured
- No expires/Cache-Control rules for static assets
- **[ OK ]** sendfile on

### nginx memory (RSS)


```text
total RSS: 56.4 MB across 9 processes
```


### Top 5 processes by memory


```text
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
artravi   940108  0.5  4.5 10153452 839400 ?     Sl   Oct23 172:48 java -jar smartapi-0.0.4-SNAPSHOT.jar
mysql    1038809  0.8  2.1 2375100 396180 ?      Ssl  Nov13  28:43 /usr/sbin/mysqld
root      106042  0.0  0.8 269112 165444 ?       S<s  Oct16  33:31 /lib/systemd/systemd-journald
root         995  0.0  0.4 2431508 86312 ?       Ssl  Oct15  15:25 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
root         817  0.0  0.2 2089132 46988 ?       Ssl  Oct15  44:36 /usr/bin/containerd
```


### Files/sockets open by nginx

- 618 open descriptors (lsof)

<a id="16-backends-related-services"></a>

## 16. BACKENDS & RELATED SERVICES


### Upstream/proxy targets reachability


### Common companion services


```text
mysql              active
docker             active
certbot.timer      active
```


### Cron jobs mentioning nginx / certbot

- Cron file: [certbot](file:///etc/cron.d/certbot) (`/etc/cron.d/certbot`)

<a id="17-config-backup-change-tracking"></a>

## 17. CONFIG BACKUP & CHANGE TRACKING

- 10 most recently modified files in /etc/nginx:
- 2026-11-15 12:46 — [nginx.conf](file:///etc/nginx/nginx.conf) (`/etc/nginx/nginx.conf`)
- 2023-05-30 23:01 — [win-utf](file:///etc/nginx/win-utf) (`/etc/nginx/win-utf`)
- 2023-05-30 23:01 — [uwsgi_params](file:///etc/nginx/uwsgi_params) (`/etc/nginx/uwsgi_params`)
- 2023-05-30 23:01 — [snakeoil.conf](file:///etc/nginx/snippets/snakeoil.conf) (`/etc/nginx/snippets/snakeoil.conf`)
- 2023-05-30 23:01 — [fastcgi-php.conf](file:///etc/nginx/snippets/fastcgi-php.conf) (`/etc/nginx/snippets/fastcgi-php.conf`)
- 2023-05-30 23:01 — [default](file:///etc/nginx/sites-available/default) (`/etc/nginx/sites-available/default`)
- 2023-05-30 23:01 — [scgi_params](file:///etc/nginx/scgi_params) (`/etc/nginx/scgi_params`)
- 2023-05-30 23:01 — [proxy_params](file:///etc/nginx/proxy_params) (`/etc/nginx/proxy_params`)
- 2023-05-30 23:01 — [mime.types](file:///etc/nginx/mime.types) (`/etc/nginx/mime.types`)
- 2023-05-30 23:01 — [koi-win](file:///etc/nginx/koi-win) (`/etc/nginx/koi-win`)
- Config not under version control (consider git or etckeeper in /etc/nginx)
