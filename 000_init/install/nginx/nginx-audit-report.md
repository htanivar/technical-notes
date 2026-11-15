# Nginx Server Diagnostic & Security Audit Report

| Property | Value |
| :--- | :--- |
| **Overall Health** | **CRITICAL (2 FAIL, 1 WARN)** |
| **Checks Summary** | **OK:** `38` &nbsp; **WARN:** `1` &nbsp; **FAIL:** `2` |
| **Generated At** | `2026-11-15 13:16:12 IST` |
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

### Critical Failures (`[FAIL]` — Fix Immediately)

| ID | Section | What Is Wrong | Where (File / Line Link) | Docs | How to Fix |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FAIL-1** | [13. ACCESS LOG & TRAFFIC ANALYSIS (assumes combined format)](#13-access-log-traffic-analysis-assumes-combined-format) | High HTTP 5xx error rate >= 5% (24 of 24 requests) in /var/log/nginx/github.jaganathan.co.uk.access.log | [github.jaganathan.co.uk.access.log](file:///var/log/nginx/github.jaganathan.co.uk.access.log) (`/var/log/nginx/github.jaganathan.co.uk.access.log`) | [Docs](https://docs.nginx.com/nginx/admin-guide/monitoring/logging/) | Inspect top 5xx URLs in /var/log/nginx/github.jaganathan.co.uk.access.log and correlate with /var/log/nginx/error.log |
| **FAIL-2** | [16. BACKENDS & RELATED SERVICES](#16-backends-related-services) | Upstream backend 127.0.0.1:3000 is NOT reachable (configured at github.jaganathan.co.uk.conf) | [github.jaganathan.co.uk.conf:58](file:///etc/nginx/conf.d/github.jaganathan.co.uk.conf#L58) (`/etc/nginx/conf.d/github.jaganathan.co.uk.conf:58`) | [Docs](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_pass) | Verify the backend application listening on 127.0.0.1:3000 is running and check its logs |

### Warnings (`[WARN]` — Recommended Hardening & Fixes)

| ID | Section | Warning Details | Where (File / Line Link) | Docs | How to Fix |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **WARN-1** | [12. ERROR LOG ANALYSIS](#12-error-log-analysis) | Upstream/backend connection errors found in /var/log/nginx/github.jaganathan.co.uk.error.log | [github.jaganathan.co.uk.error.log](file:///var/log/nginx/github.jaganathan.co.uk.error.log) (`/var/log/nginx/github.jaganathan.co.uk.error.log`) | [Docs](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_read_timeout) | Check backend service health and inspect recent lines in /var/log/nginx/github.jaganathan.co.uk.error.log |

---


<a id="1-system-overview"></a>

## 1. SYSTEM OVERVIEW

- OS        : Ubuntu 22.04.4 LTS
- Kernel    : 5.15.0-203-generic  (x86_64)
- Uptime    : up 14 minutes
- Load avg  : 0.10 0.13 0.07   CPUs: 8

### Memory


```text
               total        used        free      shared  buff/cache   available
Mem:            17Gi       661Mi        15Gi       1.0Mi       1.2Gi        16Gi
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
/dev/mapper/ubuntu--vg-ubuntu--lv 15613952 244520 15369432    2% /
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
     Active: active (running) since Sun 2026-11-15 13:02:04 IST; 14min ago
       Docs: man:nginx(8)
    Process: 5616 ExecReload=/usr/sbin/nginx -g daemon on; master_process on; -s reload (code=exited, status=0/SUCCESS)
   Main PID: 860 (nginx)
      Tasks: 9 (limit: 21436)
     Memory: 19.3M
        CPU: 580ms
     CGroup: /system.slice/nginx.service
             |- 860 "nginx: master process /usr/sbin/nginx -g daemon on; master_process on;"
             |-5625 "nginx: worker process" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ""
             |-5626 "nginx: worker process" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ""
             |-5627 "nginx: worker process" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ""
             |-5629 "nginx: worker process" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ""
```


### Recent service journal (last 10)


```text
Nov 15 13:01:14 ravinath.prod systemd[1]: Reloaded A high performance web server and a reverse proxy server.
Nov 15 13:01:29 ravinath.prod systemd[1]: Stopping A high performance web server and a reverse proxy server...
Nov 15 13:01:29 ravinath.prod systemd[1]: nginx.service: Deactivated successfully.
Nov 15 13:01:29 ravinath.prod systemd[1]: Stopped A high performance web server and a reverse proxy server.
-- Boot caa9102e01de4d859337acecfc5b0412 --
Nov 15 13:02:04 ravinath.prod systemd[1]: Starting A high performance web server and a reverse proxy server...
Nov 15 13:02:04 ravinath.prod systemd[1]: Started A high performance web server and a reverse proxy server.
Nov 15 13:12:43 ravinath.prod systemd[1]: Reloading A high performance web server and a reverse proxy server...
Nov 15 13:12:43 ravinath.prod systemd[1]: Reloaded A high performance web server and a reverse proxy server.
Nov 15 13:14:51 ravinath.prod systemd[1]: Reloading A high performance web server and a reverse proxy server...
Nov 15 13:14:51 ravinath.prod systemd[1]: Reloaded A high performance web server and a reverse proxy server.
```


### Config syntax test (nginx -t)

- **[ OK ]** Configuration syntax OK (nginx -t passed)

### Processes


```text
    PID    PPID USER     %CPU %MEM   RSS     ELAPSED CMD
    860       1 root      0.0  0.0 10428       14:10 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
   5625     860 www-data  0.0  0.0  6432       01:24 nginx: worker process
   5626     860 www-data  0.0  0.0  6432       01:24 nginx: worker process
   5627     860 www-data  0.0  0.0 10480       01:24 nginx: worker process
   5629     860 www-data  0.0  0.0  6432       01:24 nginx: worker process
   5630     860 www-data  0.0  0.0  6432       01:24 nginx: worker process
   5631     860 www-data  0.0  0.0  6432       01:24 nginx: worker process
   5632     860 www-data  0.0  0.0  6432       01:24 nginx: worker process
   5633     860 www-data  0.0  0.0  6432       01:24 nginx: worker process
```

- **[ OK ]** Master runs as root (normal, needed for ports <1024)
- **[ OK ]** Workers run as non-root user: www-data
- Active worker processes: 8   (CPU cores: 8)
- PID file configured: /run/nginx.pid

### Open-file limit of master


```text
Max open files            1024                 524288               files     
```

- Open FDs (master): 27

<a id="4-listening-ports-connections"></a>

## 4. LISTENING PORTS & CONNECTIONS


### Sockets owned by nginx


```text
tcp   LISTEN 0      511          0.0.0.0:443        0.0.0.0:*    users:(("nginx",pid=5633,fd=8),("nginx",pid=5632,fd=8),("nginx",pid=5631,fd=8),("nginx",pid=5630,fd=8),("nginx",pid=5629,fd=8),("nginx",pid=5627,fd=8),("nginx",pid=5626,fd=8),("nginx",pid=5625,fd=8),("nginx",pid=860,fd=8))
tcp   LISTEN 0      511          0.0.0.0:80         0.0.0.0:*    users:(("nginx",pid=5633,fd=6),("nginx",pid=5632,fd=6),("nginx",pid=5631,fd=6),("nginx",pid=5630,fd=6),("nginx",pid=5629,fd=6),("nginx",pid=5627,fd=6),("nginx",pid=5626,fd=6),("nginx",pid=5625,fd=6),("nginx",pid=860,fd=6))
tcp   LISTEN 0      511             [::]:443           [::]:*    users:(("nginx",pid=5633,fd=9),("nginx",pid=5632,fd=9),("nginx",pid=5631,fd=9),("nginx",pid=5630,fd=9),("nginx",pid=5629,fd=9),("nginx",pid=5627,fd=9),("nginx",pid=5626,fd=9),("nginx",pid=5625,fd=9),("nginx",pid=860,fd=9))
tcp   LISTEN 0      511             [::]:80            [::]:*    users:(("nginx",pid=5633,fd=7),("nginx",pid=5632,fd=7),("nginx",pid=5631,fd=7),("nginx",pid=5630,fd=7),("nginx",pid=5629,fd=7),("nginx",pid=5627,fd=7),("nginx",pid=5626,fd=7),("nginx",pid=5625,fd=7),("nginx",pid=860,fd=7))
```


### Ports declared in config


```text
      1 [::]:80 default_server
      1 [::]:80
      1 [::]:443 ssl http2 default_server
      1 [::]:443 ssl http2
      1 80 default_server
      1 80
      1 443 ssl http2 default_server
      1 443 ssl http2
```


### TCP connection states (all :80/:443 traffic)


```text
LISTEN         4
TIME-WAIT      3
```


### Top 10 client IPs currently connected


```text
(none)
```


### Other services listening publicly (potential exposure)


```text
0.0.0.0:443
0.0.0.0:22
0.0.0.0:80
[::]:443
[::]:22
[::]:80
```


<a id="5-configuration-files-layout"></a>

## 5. CONFIGURATION FILES & LAYOUT

- Main config dir: [nginx](file:///etc/nginx) (`/etc/nginx`)

### Files loaded

- Loaded: [00-production-hardening.conf](file:///etc/nginx/conf.d/00-production-hardening.conf) (`/etc/nginx/conf.d/00-production-hardening.conf`)
- Loaded: [00-security.conf](file:///etc/nginx/conf.d/00-security.conf) (`/etc/nginx/conf.d/00-security.conf`)
- Loaded: [github.jaganathan.co.uk.conf](file:///etc/nginx/conf.d/github.jaganathan.co.uk.conf) (`/etc/nginx/conf.d/github.jaganathan.co.uk.conf`)
- Loaded: [mime.types](file:///etc/nginx/mime.types) (`/etc/nginx/mime.types`)
- Loaded: [50-mod-http-geoip2.conf](file:///etc/nginx/modules-enabled/50-mod-http-geoip2.conf) (`/etc/nginx/modules-enabled/50-mod-http-geoip2.conf`)
- Loaded: [50-mod-http-image-filter.conf](file:///etc/nginx/modules-enabled/50-mod-http-image-filter.conf) (`/etc/nginx/modules-enabled/50-mod-http-image-filter.conf`)
- Loaded: [50-mod-http-xslt-filter.conf](file:///etc/nginx/modules-enabled/50-mod-http-xslt-filter.conf) (`/etc/nginx/modules-enabled/50-mod-http-xslt-filter.conf`)
- Loaded: [50-mod-mail.conf](file:///etc/nginx/modules-enabled/50-mod-mail.conf) (`/etc/nginx/modules-enabled/50-mod-mail.conf`)
- Loaded: [50-mod-stream.conf](file:///etc/nginx/modules-enabled/50-mod-stream.conf) (`/etc/nginx/modules-enabled/50-mod-stream.conf`)
- Loaded: [70-mod-stream-geoip2.conf](file:///etc/nginx/modules-enabled/70-mod-stream-geoip2.conf) (`/etc/nginx/modules-enabled/70-mod-stream-geoip2.conf`)
- Loaded: [nginx.conf](file:///etc/nginx/nginx.conf) (`/etc/nginx/nginx.conf`)
- Loaded: [default](file:///etc/nginx/sites-enabled/default) (`/etc/nginx/sites-enabled/default`)
- Loaded: [security-headers.conf](file:///etc/nginx/snippets/security-headers.conf) (`/etc/nginx/snippets/security-headers.conf`)
- Loaded: [security-server.conf](file:///etc/nginx/snippets/security-server.conf) (`/etc/nginx/snippets/security-server.conf`)

### Directory tree


```text
/etc/nginx/sites-available:
  -rw-r--r-- 1 root root  805 Nov 15 13:12 default
/etc/nginx/sites-enabled:
  lrwxrwxrwx 1 root root   34 Nov 15 13:12 default -> /etc/nginx/sites-available/default
/etc/nginx/conf.d:
  -rw-r--r-- 1 root root  316 Nov 15 13:14 00-production-hardening.conf
  -rw-r--r-- 1 root root  874 Nov 15 13:12 00-security.conf
  -rw-r--r-- 1 root root 3389 Nov 15 13:14 github.jaganathan.co.uk.conf
/etc/nginx/snippets:
  -rw-r--r-- 1 root root  423 May 30  2023 fastcgi-php.conf
  -rw-r--r-- 1 root root  582 Nov 15 13:12 security-headers.conf
  -rw-r--r-- 1 root root  239 Nov 15 13:12 security-server.conf
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
client_max_body_size  10m;
client_max_body_size 25m;
client_body_timeout   10s;
client_body_timeout 30s;
client_header_timeout 10s;
client_header_timeout 30s;
send_timeout          10s;
send_timeout 30s;
gzip on;
error_log /var/log/nginx/error.log;
error_log /var/log/nginx/github.jaganathan.co.uk.error.log warn;
access_log /var/log/nginx/access.log;
access_log /var/log/nginx/github.jaganathan.co.uk.access.log;
access_log off;
```

- **[ OK ]** worker_processes auto

<a id="6-sites-virtual-hosts-parsed-from-effective-config"></a>

## 6. SITES / VIRTUAL HOSTS (parsed from effective config)


```text
[1] github.jaganathan.co.uk
    file       : /etc/nginx/conf.d/github.jaganathan.co.uk.conf:7
    listen     : 80 | [::]:80
    return     : 301 https://$host$request_uri
    locations  : 0     

[2] github.jaganathan.co.uk
    file       : /etc/nginx/conf.d/github.jaganathan.co.uk.conf:16
    listen     : 443 ssl http2 | [::]:443 ssl http2
    proxy_pass : http://127.0.0.1:3000
    return     : 200 "OK\n"
    ssl cert   : /etc/letsencrypt/live/github.jaganathan.co.uk/fullchain.pem
    ssl key    : /etc/letsencrypt/live/github.jaganathan.co.uk/privkey.pem
    access_log : off
    locations  : 4    [ip-acl] 

[3] _
    file       : /etc/nginx/sites-enabled/default:3
    listen     : 80 default_server | [::]:80 default_server
    return     : 301 https://$host$request_uri
    locations  : 0     

[4] _
    file       : /etc/nginx/sites-enabled/default:14
    listen     : 443 ssl http2 default_server | [::]:443 ssl http2 default_server
    root       : /var/www/html
    ssl cert   : /etc/ssl/nginx-default/default.crt
    ssl key    : /etc/ssl/nginx-default/default.key
    locations  : 1     

Total server blocks: 4
```


### Domains (unique server_names)


```text
_
github.jaganathan.co.uk
```


### Default servers

- **[ OK ]** Explicit default_server configured

```text
    listen 80 default_server;
    listen [::]:80 default_server;
    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;
```


### Upstream blocks


```text
(no upstream blocks defined)
```


### Location blocks summary


```text
      2 location ~ /\.(?!well-known).* {
      2 location / {
      1 location ~* \.(?:bak|sql|old|swp|orig|save|env)$ {
      1 location = /healthz {
```


### Web root(s): size & owner

- Web root [html](file:///var/www/html) (`/var/www/html`) — size=8.0K owner=root:root perms=755

<a id="7-ssl-tls-certificates"></a>

## 7. SSL / TLS CERTIFICATES

- Certificate : [fullchain.pem](file:///etc/letsencrypt/live/github.jaganathan.co.uk/fullchain.pem) (`/etc/letsencrypt/live/github.jaganathan.co.uk/fullchain.pem`) (configured at [github.jaganathan.co.uk.conf:23](file:///etc/nginx/conf.d/github.jaganathan.co.uk.conf#L23) (`/etc/nginx/conf.d/github.jaganathan.co.uk.conf:23`))
-   Subject   : CN = github.jaganathan.co.uk
-   Issuer    : C = US, O = Let's Encrypt, CN = YR1
-   SANs      : DNS:github.jaganathan.co.uk
-   Expires   : Feb 13 06:46:17 2027 GMT (89 days remaining)
-   Key / Sig : 2048 bit / sha256WithRSAEncryption
- **[ OK ]** Certificate /etc/letsencrypt/live/github.jaganathan.co.uk/fullchain.pem validity OK (89 days remaining)
- Certificate : [default.crt](file:///etc/ssl/nginx-default/default.crt) (`/etc/ssl/nginx-default/default.crt`) (configured at [default:20](file:///etc/nginx/sites-enabled/default#L20) (`/etc/nginx/sites-enabled/default:20`))
-   Subject   : CN = localhost
-   Issuer    : CN = localhost
-   SANs      : n/a
-   Expires   : Nov 12 07:31:12 2036 GMT (3649 days remaining)
-   Key / Sig : 256 bit / ecdsa-with-SHA256
- **[ OK ]** Certificate /etc/ssl/nginx-default/default.crt validity OK (3649 days remaining)

### Private key permissions

- **[ OK ]** Private key /etc/letsencrypt/live/github.jaganathan.co.uk/privkey.pem permissions OK (600 root:root)
- **[ OK ]** Private key /etc/ssl/nginx-default/default.key permissions OK (600 root:root)

### Certbot certificates


```text

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Found the following certs:
  Certificate Name: github.jaganathan.co.uk
    Serial Number: 60d995c183d6688a6b698ed7fa1ce8216a1
    Key Type: RSA
    Domains: github.jaganathan.co.uk
    Expiry Date: 2027-02-13 06:46:17+00:00 (VALID: 89 days)
    Certificate Path: /etc/letsencrypt/live/github.jaganathan.co.uk/fullchain.pem
    Private Key Path: /etc/letsencrypt/live/github.jaganathan.co.uk/privkey.pem
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

- Let's Encrypt live dir: README github.jaganathan.co.uk 
- certbot cron present: [certbot](file:///etc/cron.d/certbot) (`/etc/cron.d/certbot`)

<a id="8-security-audit-config-based"></a>

## 8. SECURITY AUDIT (config-based)


### Information disclosure

- **[ OK ]** server_tokens off (Nginx version hidden)
- **[ OK ]** X-Powered-By hidden from upstreams

### TLS protocol & cipher policy

- ssl_protocols configured: TLSv1.2 TLSv1.3 
- **[ OK ]** No legacy SSL/TLSv1.0/TLSv1.1 protocols enabled
- **[ OK ]** TLSv1.3 enabled
- ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305;
- **[ OK ]** ssl_session_cache configured

### Security headers (add_header)

- **[ OK ]** Security header Strict-Transport-Security configured
- **[ OK ]** Security header X-Frame-Options configured
- **[ OK ]** Security header X-Content-Type-Options configured
- **[ OK ]** Security header Content-Security-Policy configured
- **[ OK ]** Security header Referrer-Policy configured
- **[ OK ]** Security header Permissions-Policy configured

### HTTP -> HTTPS redirection

- **[ OK ]** HTTP -> HTTPS redirect present
- **[ OK ]** HTTP/2 enabled

### Rate limiting / DoS protection

- **[ OK ]** limit_req_zone defined
- **[ OK ]** limit_req applied
- client_max_body_size: 10m 25m 

### Dangerous / risky patterns

- **[ OK ]** Dotfile (/.git, /.env) blocking location rule present

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
drwxr-xr-x 2 root adm 4096 Nov 15 13:14 /var/log/nginx
```


<a id="10-system-level-hardening"></a>

## 10. SYSTEM-LEVEL HARDENING


### Firewall


```text
Status: inactive
```


### Fail2ban

- **[ OK ]** fail2ban service is active

### SELinux / AppArmor


```text
30 profiles are loaded.
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


<a id="11-logs-locations-size-rotation"></a>

## 11. LOGS - LOCATIONS, SIZE, ROTATION


### Log files

- Log file [access.log](file:///var/log/nginx/access.log) (`/var/log/nginx/access.log`) — size=40K mtime=2026-11-15 13:15:56
- Log file [github.jaganathan.co.uk.access.log](file:///var/log/nginx/github.jaganathan.co.uk.access.log) (`/var/log/nginx/github.jaganathan.co.uk.access.log`) — size=4.0K mtime=2026-11-15 13:16:05
- Log file [error.log](file:///var/log/nginx/error.log) (`/var/log/nginx/error.log`) — size=4.0K mtime=2026-11-15 13:14:51
- Log file [github.jaganathan.co.uk.error.log](file:///var/log/nginx/github.jaganathan.co.uk.error.log) (`/var/log/nginx/github.jaganathan.co.uk.error.log`) — size=12K mtime=2026-11-15 13:16:05
- Total /var/log/nginx size: 64K

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
      8 [notice]
      1 [emerg]
```


### Top 10 error messages


```text
      1 [notice] 5616#5616: signal process started
      1 [notice] 5458#5458: signal process started
      1 [notice] 5443#5443: signal process started
      1 [notice] 3991#3991: signal process started
      1 [notice] 1536322#1536322: signal process started
      1 [notice] 1530870#1530870: signal process started
      1 [notice] 1529774#1529774: signal process started
      1 [notice] 1527287#1527287: using inherited sockets from "6;7;"
      1 [emerg] 2840#2840: "server_tokens" directive is duplicate in /etc/nginx/conf.d/00-security.conf:4
```


### Last 15 error/crit entries


```text
2026/11/15 13:05:56 [emerg] 2840#2840: "server_tokens" directive is duplicate in /etc/nginx/conf.d/00-security.conf:4
```

- Analysing error log: [github.jaganathan.co.uk.error.log](file:///var/log/nginx/github.jaganathan.co.uk.error.log) (`/var/log/nginx/github.jaganathan.co.uk.error.log`)

### Entries by severity (last 50000 lines)


```text
     38 [error]
```


### Top 10 error messages


```text
     24 connect() failed (111: Unknown error) while connecting to upstream, client: X, server: github.jaganathan.co.uk, request:
     14 access forbidden by rule, client: X, server: github.jaganathan.co.uk, request: "..."
```


### Last 15 error/crit entries


```text
2026/11/15 13:15:27 [error] 5627#5627: *39 connect() failed (111: Unknown error) while connecting to upstream, client: 91.148.244.131, server: github.jaganathan.co.uk, request: "GET /_vti_pvt/service.pwd HTTP/2.0", upstr
2026/11/15 13:15:27 [error] 5627#5627: *39 connect() failed (111: Unknown error) while connecting to upstream, client: 91.148.244.131, server: github.jaganathan.co.uk, request: "GET /wp-admin/setup-config.php HTTP/2.0", 
2026/11/15 13:15:27 [error] 5627#5627: *39 access forbidden by rule, client: 91.148.244.131, server: github.jaganathan.co.uk, request: "GET /.git/HEAD HTTP/2.0", host: "github.jaganathan.co.uk"
2026/11/15 13:15:27 [error] 5627#5627: *39 access forbidden by rule, client: 91.148.244.131, server: github.jaganathan.co.uk, request: "GET /.env.production HTTP/2.0", host: "github.jaganathan.co.uk"
2026/11/15 13:15:27 [error] 5627#5627: *39 access forbidden by rule, client: 91.148.244.131, server: github.jaganathan.co.uk, request: "GET /.npmrc HTTP/2.0", host: "github.jaganathan.co.uk"
2026/11/15 13:15:27 [error] 5627#5627: *39 access forbidden by rule, client: 91.148.244.131, server: github.jaganathan.co.uk, request: "GET /database.sql HTTP/2.0", host: "github.jaganathan.co.uk"
2026/11/15 13:15:27 [error] 5627#5627: *39 access forbidden by rule, client: 91.148.244.131, server: github.jaganathan.co.uk, request: "GET /.bash_history HTTP/2.0", host: "github.jaganathan.co.uk"
2026/11/15 13:15:27 [error] 5627#5627: *39 connect() failed (111: Unknown error) while connecting to upstream, client: 91.148.244.131, server: github.jaganathan.co.uk, request: "GET /docker-compose.yml HTTP/2.0", upstrea
2026/11/15 13:15:27 [error] 5627#5627: *39 access forbidden by rule, client: 91.148.244.131, server: github.jaganathan.co.uk, request: "GET /.vscode/sftp.json HTTP/2.0", host: "github.jaganathan.co.uk"
2026/11/15 13:15:27 [error] 5627#5627: *39 connect() failed (111: Unknown error) while connecting to upstream, client: 91.148.244.131, server: github.jaganathan.co.uk, request: "GET /user_secrets.yml HTTP/2.0", upstream:
2026/11/15 13:15:27 [error] 5627#5627: *39 connect() failed (111: Unknown error) while connecting to upstream, client: 91.148.244.131, server: github.jaganathan.co.uk, request: "GET /secrets.json HTTP/2.0", upstream: "ht
2026/11/15 13:15:27 [error] 5627#5627: *39 connect() failed (111: Unknown error) while connecting to upstream, client: 91.148.244.131, server: github.jaganathan.co.uk, request: "GET /server.key HTTP/2.0", upstream: "http
2026/11/15 13:15:37 [error] 5627#5627: *58 connect() failed (111: Unknown error) while connecting to upstream, client: 162.252.199.71, server: github.jaganathan.co.uk, request: "GET / HTTP/1.1", upstream: "http://127.0.0
2026/11/15 13:15:56 [error] 5627#5627: *61 connect() failed (111: Unknown error) while connecting to upstream, client: 185.242.177.69, server: github.jaganathan.co.uk, request: "GET / HTTP/1.1", upstream: "http://127.0.0
2026/11/15 13:16:05 [error] 5627#5627: *64 connect() failed (111: Unknown error) while connecting to upstream, client: 127.0.0.1, server: github.jaganathan.co.uk, request: "GET / HTTP/2.0", upstream: "http://127.0.0.1:30
```

- **[WARN] (`WARN-1`)** Upstream/backend connection errors found in /var/log/nginx/github.jaganathan.co.uk.error.log
  - **Where**: [github.jaganathan.co.uk.error.log](file:///var/log/nginx/github.jaganathan.co.uk.error.log) (`/var/log/nginx/github.jaganathan.co.uk.error.log`)
  - **Reference**: <https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_read_timeout>
  - **How to Fix**: Check backend service health and inspect recent lines in /var/log/nginx/github.jaganathan.co.uk.error.log

<a id="13-access-log-traffic-analysis-assumes-combined-format"></a>

## 13. ACCESS LOG & TRAFFIC ANALYSIS (assumes combined format)

- Analysing access log: [access.log](file:///var/log/nginx/access.log) (`/var/log/nginx/access.log`) (last 50000 of 203 lines)
- Time range: [15/Nov/2026:12:44:25 +0530]  ->  [15/Nov/2026:13:15:56 +0530]

### HTTP status code distribution


```text
    165 404
     16 200
     13 301
      1 405
```


### Status classes


```text
2xx      16  (8.2%)
3xx      13  (6.7%)
4xx     166  (85.1%)
```


### Top 15 client IPs


```text
     94 104.22.20.124
     73 104.22.20.54
     16 127.0.0.1
      3 162.158.179.51
      2 172.70.142.167
      1 56.124.83.188
      1 35.240.6.16
      1 23.178.112.212
      1 185.242.177.69
      1 18.220.206.63
      1 172.71.81.229
      1 162.158.88.161
      1 162.158.193.102
      1 162.158.114.209
      1 16.192.127.209
```


### Top 15 requested URLs


```text
     23 /
      8 400
      7 /.well-known/acme-challenge/gVs8SrpXKBnS1AU8q66DTDnIn1RUJcL_RnvdzY0XSrk
      1 /www/.env
      1 /wp/.env
      1 /wordpress/.env
      1 /webroot/index.php/_environment
      1 /webmail/phpinfo.php
      1 /web/.env
      1 /vendor/.env
      1 /v3/.env
      1 /v2/.env
      1 /v1/.env
      1 /uploads/.env
      1 /transactional/.env
```


### Top 10 URLs returning 404


```text
      1 /www/.env
      1 /wp/.env
      1 /wordpress/.env
      1 /webroot/index.php/_environment
      1 /webmail/phpinfo.php
      1 /web/.env
      1 /vendor/.env
      1 /v3/.env
      1 /v2/.env
      1 /v1/.env
```


### Top 10 URLs returning 5xx

- Analysing access log: [github.jaganathan.co.uk.access.log](file:///var/log/nginx/github.jaganathan.co.uk.access.log) (`/var/log/nginx/github.jaganathan.co.uk.access.log`) (last 50000 of 24 lines)
- Time range: [15/Nov/2026:13:14:52 +0530]  ->  [15/Nov/2026:13:16:05 +0530]

### HTTP status code distribution


```text
     24 502
```


### Status classes


```text
5xx      24  (100.0%)
```

- **[FAIL] (`FAIL-1`)** High HTTP 5xx error rate >= 5% (24 of 24 requests) in /var/log/nginx/github.jaganathan.co.uk.access.log
  - **Where**: [github.jaganathan.co.uk.access.log](file:///var/log/nginx/github.jaganathan.co.uk.access.log) (`/var/log/nginx/github.jaganathan.co.uk.access.log`)
  - **Reference**: <https://docs.nginx.com/nginx/admin-guide/monitoring/logging/>
  - **How to Fix**: Inspect top 5xx URLs in /var/log/nginx/github.jaganathan.co.uk.access.log and correlate with /var/log/nginx/error.log
/var/log/nginx/github.jaganathan.co.uk.error.log

### Top 15 client IPs


```text
     17 91.148.244.131
      1 74.208.226.173
      1 5.78.201.227
      1 5.78.158.121
      1 185.242.177.69
      1 162.252.199.71
      1 133.32.165.184
      1 127.0.0.1
```


### Top 15 requested URLs


```text
     10 /
      1 /wp-config.php
      1 /wp-admin/setup-config.php
      1 /user_secrets.yml
      1 /storage/logs/laravel.log
      1 /server.key
      1 /secrets.json
      1 /phpinfo.php
      1 /docker-compose.yml
      1 /config.xml
      1 /config.php
      1 /backup.zip
      1 /backup.tar.gz
      1 /actuator/heapdump
      1 /_vti_pvt/service.pwd
```


### Top 10 URLs returning 404


### Top 10 URLs returning 5xx


```text
     10 502 /
      1 502 /wp-config.php
      1 502 /wp-admin/setup-config.php
      1 502 /user_secrets.yml
      1 502 /storage/logs/laravel.log
      1 502 /server.key
      1 502 /secrets.json
      1 502 /phpinfo.php
      1 502 /docker-compose.yml
      1 502 /config.xml
```


<a id="14-live-endpoint-checks-localhost"></a>

## 14. LIVE ENDPOINT CHECKS (localhost)

- Probing http://127.0.0.1 (Host: localhost, -k)

```text
HTTP/1.1 301 Moved Permanently
Server: nginx
Date: Sun, 15 Nov 2026 07:46:17 GMT
Content-Type: text/html
Content-Length: 162
Connection: keep-alive
Location: https://127.0.0.1/
Strict-Transport-Security: max-age=31536000
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
Content-Security-Policy: default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self'; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'self'
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()

```

- Probing https://127.0.0.1 (Host: localhost, -k)

```text
HTTP/2 200 
server: nginx
date: Sun, 15 Nov 2026 07:46:17 GMT
content-type: text/html
content-length: 612
last-modified: Sun, 15 Nov 2026 07:13:18 GMT
etag: "6af95b8e-264"
strict-transport-security: max-age=31536000
x-frame-options: SAMEORIGIN
x-content-type-options: nosniff
content-security-policy: default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self'; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'self'
referrer-policy: strict-origin-when-cross-origin
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
accept-ranges: bytes

```


### Security headers on first named server over HTTPS

- Testing github.jaganathan.co.uk via --resolve github.jaganathan.co.uk:443:127.0.0.1

```text
HTTP/2 502 
server: nginx
date: Sun, 15 Nov 2026 07:46:17 GMT
content-type: text/html
content-length: 150
strict-transport-security: max-age=63072000; includeSubDomains
x-frame-options: SAMEORIGIN
x-content-type-options: nosniff
referrer-policy: strict-origin-when-cross-origin
permissions-policy: geolocation=(), microphone=(), camera=()
content-security-policy: default-src 'self' 'unsafe-inline' data: https:;

```

- **[ OK ]** Live HTTPS response includes HSTS header

### TLS handshake test on 127.0.0.1:443

- tls1 rejected or 127.0.0.1:443 not listening
- tls1_1 rejected or 127.0.0.1:443 not listening
- **[ OK ]** Live endpoint accepted tls1_2
- **[ OK ]** Live endpoint accepted tls1_3

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
total RSS: 64.4 MB across 9 processes
```


### Top 5 processes by memory


```text
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
mysql        935  1.0  2.1 2374068 395360 ?      Ssl  13:02   0:09 /usr/sbin/mysqld
root         465  0.1  0.4 191816 89504 ?        S<s  13:01   0:01 /lib/systemd/systemd-journald
root         967  0.0  0.4 2210312 81236 ?       Ssl  13:02   0:00 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
root         787  0.1  0.2 2089132 43864 ?       Ssl  13:02   0:00 /usr/bin/containerd
root         779  0.1  0.2 2223764 40768 ?       Ssl  13:02   0:01 /snap/snapd/current/usr/lib/snapd/snapd
```


### Files/sockets open by nginx

- 681 open descriptors (lsof)

<a id="16-backends-related-services"></a>

## 16. BACKENDS & RELATED SERVICES


### Upstream/proxy targets reachability

- **[FAIL] (`FAIL-2`)** Upstream backend 127.0.0.1:3000 is NOT reachable (configured at github.jaganathan.co.uk.conf)
  - **Where**: [github.jaganathan.co.uk.conf:58](file:///etc/nginx/conf.d/github.jaganathan.co.uk.conf#L58) (`/etc/nginx/conf.d/github.jaganathan.co.uk.conf:58`)
  - **Reference**: <https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_pass>
  - **How to Fix**: Verify the backend application listening on 127.0.0.1:3000 is running and check its logs

### Common companion services


```text
mysql              active
docker             active
fail2ban           active
certbot.timer      active
```


### Cron jobs mentioning nginx / certbot

- Cron file: [certbot](file:///etc/cron.d/certbot) (`/etc/cron.d/certbot`)

<a id="17-config-backup-change-tracking"></a>

## 17. CONFIG BACKUP & CHANGE TRACKING

- 10 most recently modified files in /etc/nginx:
- 2026-11-15 13:14 — [github.jaganathan.co.uk.conf](file:///etc/nginx/conf.d/github.jaganathan.co.uk.conf) (`/etc/nginx/conf.d/github.jaganathan.co.uk.conf`)
- 2026-11-15 13:14 — [00-production-hardening.conf](file:///etc/nginx/conf.d/00-production-hardening.conf) (`/etc/nginx/conf.d/00-production-hardening.conf`)
- 2026-11-15 13:12 — [security-server.conf](file:///etc/nginx/snippets/security-server.conf) (`/etc/nginx/snippets/security-server.conf`)
- 2026-11-15 13:12 — [security-headers.conf](file:///etc/nginx/snippets/security-headers.conf) (`/etc/nginx/snippets/security-headers.conf`)
- 2026-11-15 13:12 — [default](file:///etc/nginx/sites-available/default) (`/etc/nginx/sites-available/default`)
- 2026-11-15 13:12 — [nginx.conf](file:///etc/nginx/nginx.conf) (`/etc/nginx/nginx.conf`)
- 2026-11-15 13:12 — [00-security.conf](file:///etc/nginx/conf.d/00-security.conf) (`/etc/nginx/conf.d/00-security.conf`)
- 2023-05-30 23:01 — [win-utf](file:///etc/nginx/win-utf) (`/etc/nginx/win-utf`)
- 2023-05-30 23:01 — [uwsgi_params](file:///etc/nginx/uwsgi_params) (`/etc/nginx/uwsgi_params`)
- 2023-05-30 23:01 — [snakeoil.conf](file:///etc/nginx/snippets/snakeoil.conf) (`/etc/nginx/snippets/snakeoil.conf`)
- Config not under version control (consider git or etckeeper in /etc/nginx)
