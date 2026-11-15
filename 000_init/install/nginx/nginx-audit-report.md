# Nginx Server Diagnostic & Security Audit Report

| Property | Value |
| :--- | :--- |
| **Overall Health** | **CRITICAL (2 FAIL, 5 WARN)** |
| **Checks Summary** | **OK:** `37` &nbsp; **WARN:** `5` &nbsp; **FAIL:** `2` |
| **Generated At** | `2026-11-14 20:46:55 IST` |
| **Host / OS** | `antigravity` (Debian GNU/Linux 12 (bookworm)) |
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
| **FAIL-1** | [13. ACCESS LOG & TRAFFIC ANALYSIS (assumes combined format)](#13-access-log-traffic-analysis-assumes-combined-format) | High HTTP 5xx error rate >= 5% (1 of 1 requests) in /var/log/nginx/github.jaganathan.co.uk.access.log | [github.jaganathan.co.uk.access.log](file:///var/log/nginx/github.jaganathan.co.uk.access.log) (`/var/log/nginx/github.jaganathan.co.uk.access.log`) | [Docs](https://docs.nginx.com/nginx/admin-guide/monitoring/logging/) | Inspect top 5xx URLs in /var/log/nginx/github.jaganathan.co.uk.access.log and correlate with /var/log/nginx/error.log |
| **FAIL-2** | [16. BACKENDS & RELATED SERVICES](#16-backends-related-services) | Upstream backend 127.0.0.1:3000 is NOT reachable (configured at github.jaganathan.co.uk.conf) | [github.jaganathan.co.uk.conf:57](file:///etc/nginx/conf.d/github.jaganathan.co.uk.conf#L57) (`/etc/nginx/conf.d/github.jaganathan.co.uk.conf:57`) | [Docs](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_pass) | Verify the backend application listening on 127.0.0.1:3000 is running and check its logs |

### Warnings (`[WARN]` — Recommended Hardening & Fixes)

| ID | Section | Warning Details | Where (File / Line Link) | Docs | How to Fix |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **WARN-1** | [3. SERVICE STATUS & PROCESSES](#3-service-status-processes) | Nginx init script not enabled in default runlevels | [nginx](file:///etc/init.d/nginx) (`/etc/init.d/nginx`) | [Docs](https://manpages.debian.org/bookworm/init-system-helpers/update-rc.d.8.en.html) | Enable at boot: sudo update-rc.d nginx defaults |
| **WARN-2** | [3. SERVICE STATUS & PROCESSES](#3-service-status-processes) | nginx -t could not read restricted file '/etc/ssl/certs/nginx/github.jaganathan.co.uk.key' as non-root user | [github.jaganathan.co.uk.conf:23](file:///etc/nginx/conf.d/github.jaganathan.co.uk.conf#L23) (`/etc/nginx/conf.d/github.jaganathan.co.uk.conf:23`) | [Docs](https://nginx.org/en/docs/switches.html) | Run audit or syntax test with root privileges: sudo ./status_nginx.sh (or sudo nginx -t) |
| **WARN-3** | [10. SYSTEM-LEVEL HARDENING](#10-system-level-hardening) | No active host firewall rules detected ( or requires root to inspect iptables/nftables ) | [etc](file:///etc) (`/etc`) | [Docs](https://wiki.debian.org/Uncomplicated%20Firewall%20%28ufw%29) | Enable host firewall (e.g. sudo ufw allow 'Nginx Full' && sudo ufw enable) or run audit with sudo |
| **WARN-4** | [10. SYSTEM-LEVEL HARDENING](#10-system-level-hardening) | fail2ban is not installed (recommended for nginx-http-auth and bot/scanner rate-banning) | [etc](file:///etc) (`/etc`) | [Docs](https://www.fail2ban.org/wiki/index.php/Main_Page) | Install fail2ban: sudo apt-get install -y fail2ban |
| **WARN-5** | [12. ERROR LOG ANALYSIS](#12-error-log-analysis) | Upstream/backend connection errors found in /var/log/nginx/github.jaganathan.co.uk.error.log | [github.jaganathan.co.uk.error.log](file:///var/log/nginx/github.jaganathan.co.uk.error.log) (`/var/log/nginx/github.jaganathan.co.uk.error.log`) | [Docs](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_read_timeout) | Check backend service health and inspect recent lines in /var/log/nginx/github.jaganathan.co.uk.error.log |

---


<a id="1-system-overview"></a>

## 1. SYSTEM OVERVIEW

- OS        : Debian GNU/Linux 12 (bookworm)
- Kernel    : 6.14.2-1-liquorix-amd64  (x86_64)
- Uptime    : up 5 hours, 18 minutes
- Load avg  : 2.18 1.10 0.68   CPUs: 2

### Memory


```text
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       2.2Gi       803Mi        80Mi       1.2Gi       1.7Gi
Swap:          7.0Gi       488Mi       6.5Gi
```


### Disk usage


```text
Filesystem     Type    Size  Used Avail Use% Mounted on
/dev/sda1      ext4     98G   25G   69G  27% /
apps           vboxsf  196G   94G  103G  48% /apps
code           vboxsf  196G   94G  103G  48% /code
```


### Disk inodes


```text
Filesystem      Inodes   IUsed   IFree IUse% Mounted on
/dev/sda1      6553600  460589 6093011    8% /
apps              1000 -999000 1000000     - /apps
code              1000 -999000 1000000     - /code
```


### Public / local IPs


```text
eth0             UP             192.168.1.2/24 2401:4900:8826:ed64:8616:74bc:c27b:c34d/64 fe80::6823:ef1d:db2c:2b06/64 
docker0          DOWN           172.17.0.1/16 
```


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

- **[ OK ]** nginx process is running (non-systemd init)
- **[WARN] (`WARN-1`)** Nginx init script not enabled in default runlevels
  - **Where**: [nginx](file:///etc/init.d/nginx) (`/etc/init.d/nginx`)
  - **Reference**: <https://manpages.debian.org/bookworm/init-system-helpers/update-rc.d.8.en.html>
  - **How to Fix**: Enable at boot: sudo update-rc.d nginx defaults

### Config syntax test (nginx -t)

- **[WARN] (`WARN-2`)** nginx -t could not read restricted file '/etc/ssl/certs/nginx/github.jaganathan.co.uk.key' as non-root user
  - **Where**: [github.jaganathan.co.uk.conf:23](file:///etc/nginx/conf.d/github.jaganathan.co.uk.conf#L23) (`/etc/nginx/conf.d/github.jaganathan.co.uk.conf:23`)
  - **Reference**: <https://nginx.org/en/docs/switches.html>
  - **How to Fix**: Run audit or syntax test with root privileges: sudo ./status_nginx.sh (or sudo nginx -t)

```text
2026/11/14 20:46:55 [warn] 81364#81364: the "user" directive makes sense only if the master process runs with super-user privileges, ignored in /etc/nginx/nginx.conf:1
2026/11/14 20:46:55 [emerg] 81364#81364: cannot load certificate key "/etc/ssl/certs/nginx/github.jaganathan.co.uk.key": BIO_new_file() failed (SSL: error:8000000D:system library::Permission denied:calling fopen(/etc/ssl/certs/nginx/github.jaganathan.co.uk.key, r) error:10080002:BIO routines::system lib)
nginx: configuration file /etc/nginx/nginx.conf test failed
```

- Note: Effective config was loaded via direct file inclusion because 'nginx -T' exited non-zero.

### Processes


```text
    PID    PPID USER     %CPU %MEM   RSS     ELAPSED CMD
  33805       1 root      0.0  0.1  6448    02:49:26 nginx: master process /usr/sbin/nginx
  76483   33805 www-data  0.0  0.1  6248       12:52 nginx: worker process
  76484   33805 www-data  0.0  0.0  1864       12:52 nginx: worker process
```

- **[ OK ]** Master runs as root (normal, needed for ports <1024)
- **[ OK ]** Workers run as non-root user: www-data
- Active worker processes: 2   (CPU cores: 2)
- PID file configured: /run/nginx.pid

### Open-file limit of master


```text
Max open files            1024                 4096                 files     
```

- Open FDs (master): 0

<a id="4-listening-ports-connections"></a>

## 4. LISTENING PORTS & CONNECTIONS


### Sockets owned by nginx


```text
(no active sockets owned by nginx)
```


### Ports declared in config


```text
      2 80
      1 [::]:80 default_server
      1 [::]:80
      1 [::]:443 ssl http2
      1 80 default_server
      1 443 ssl http2
      1 443 ssl
```


### TCP connection states (all :80/:443 traffic)


```text
LISTEN         4
```


### Top 10 client IPs currently connected


```text
(none)
```


### Other services listening publicly (potential exposure)


```text
0.0.0.0:445
0.0.0.0:443
0.0.0.0:111
0.0.0.0:80
0.0.0.0:22
0.0.0.0:139
0.0.0.0:42607
[::]:445
[::]:443
*:6566
[::]:41345
[::]:111
[::]:80
[::]:22
[::]:139
```


<a id="5-configuration-files-layout"></a>

## 5. CONFIGURATION FILES & LAYOUT

- Main config dir: [nginx](file:///etc/nginx) (`/etc/nginx`)

### Files loaded

- Loaded: [00-production-hardening.conf](file:///etc/nginx/conf.d/00-production-hardening.conf) (`/etc/nginx/conf.d/00-production-hardening.conf`)
- Loaded: [github.jaganathan.co.uk.conf](file:///etc/nginx/conf.d/github.jaganathan.co.uk.conf) (`/etc/nginx/conf.d/github.jaganathan.co.uk.conf`)
- Loaded: [nginx.localhost.com.conf](file:///etc/nginx/conf.d/nginx.localhost.com.conf) (`/etc/nginx/conf.d/nginx.localhost.com.conf`)
- Loaded: [nginx.conf](file:///etc/nginx/nginx.conf) (`/etc/nginx/nginx.conf`)
- Loaded: [default](file:///etc/nginx/sites-enabled/default) (`/etc/nginx/sites-enabled/default`)

### Directory tree


```text
/etc/nginx/sites-available:
  -rw-r--r-- 1 root root 2412 Jul 18 21:48 default
/etc/nginx/sites-enabled:
  lrwxrwxrwx 1 root root   34 Nov 14 17:33 default -> /etc/nginx/sites-available/default
/etc/nginx/conf.d:
  -rw-r--r-- 1 root root  399 Nov 14 20:34 00-production-hardening.conf
  -rw-r--r-- 1 root root 3364 Nov 14 20:34 github.jaganathan.co.uk.conf
  -rw-r--r-- 1 root root  748 Nov 14 17:57 nginx.localhost.com.conf
/etc/nginx/snippets:
  -rw-r--r-- 1 root root  423 Jul 18 21:48 fastcgi-php.conf
  -rw-r--r-- 1 root root  217 Jul 18 21:48 snakeoil.conf
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
client_max_body_size 25m;
client_body_timeout 30s;
client_header_timeout 30s;
send_timeout 30s;
gzip on;
error_log /var/log/nginx/error.log;
error_log /var/log/nginx/github.jaganathan.co.uk.error.log warn;
error_log /var/log/nginx/nginx.localhost.com.error.log;
access_log /var/log/nginx/access.log;
access_log /var/log/nginx/github.jaganathan.co.uk.access.log;
access_log /var/log/nginx/nginx.localhost.com.access.log;
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
    ssl cert   : /etc/ssl/certs/nginx/github.jaganathan.co.uk.crt
    ssl key    : /etc/ssl/certs/nginx/github.jaganathan.co.uk.key
    access_log : off
    locations  : 4    [ip-acl] 

[3] nginx.localhost.com
    file       : /etc/nginx/conf.d/nginx.localhost.com.conf:1
    listen     : 80
    return     : 301 https://$host$request_uri
    locations  : 0     

[4] nginx.localhost.com
    file       : /etc/nginx/conf.d/nginx.localhost.com.conf:8
    listen     : 443 ssl
    root       : /var/www/html/nginx.localhost.com
    ssl cert   : /etc/ssl/certs/nginx/nginx.crt
    ssl key    : /etc/ssl/certs/nginx/nginx.key
    access_log : /var/log/nginx/nginx.localhost.com.access.log
    locations  : 1     

[5] _
    file       : /etc/nginx/sites-enabled/default:21
    listen     : 80 default_server | [::]:80 default_server
    root       : /var/www/html
    locations  : 1     

Total server blocks: 5
```


### Domains (unique server_names)


```text
_
github.jaganathan.co.uk
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
      3 location / {
      1 location ~* \.(?:bak|sql|old|swp|orig|save|env)$ {
      1 location ~ /\.(?!well-known).* {
      1 location = /healthz {
```


### Web root(s): size & owner

- Web root [html](file:///var/www/html) (`/var/www/html`) — size=16K owner=root:root perms=755
- Web root [nginx.localhost.com](file:///var/www/html/nginx.localhost.com) (`/var/www/html/nginx.localhost.com`) — size=8.0K owner=root:root perms=755

<a id="7-ssl-tls-certificates"></a>

## 7. SSL / TLS CERTIFICATES

- Certificate : [github.jaganathan.co.uk.crt](file:///etc/ssl/certs/nginx/github.jaganathan.co.uk.crt) (`/etc/ssl/certs/nginx/github.jaganathan.co.uk.crt`) (configured at [github.jaganathan.co.uk.conf:22](file:///etc/nginx/conf.d/github.jaganathan.co.uk.conf#L22) (`/etc/nginx/conf.d/github.jaganathan.co.uk.conf:22`))
-   Subject   : C = US, ST = State, L = City, O = ProductionNginx, CN = github.jaganathan.co.uk
-   Issuer    : C = US, ST = State, L = City, O = ProductionNginx, CN = github.jaganathan.co.uk
-   SANs      : DNS:github.jaganathan.co.uk,DNS:localhost,IPAddress:127.0.0.1
-   Expires   : Nov 14 15:04:03 2027 GMT (364 days remaining)
-   Key / Sig : 2048 bit / sha256WithRSAEncryption
- **[ OK ]** Certificate /etc/ssl/certs/nginx/github.jaganathan.co.uk.crt validity OK (364 days remaining)
- Certificate : [nginx.crt](file:///etc/ssl/certs/nginx/nginx.crt) (`/etc/ssl/certs/nginx/nginx.crt`) (configured at [nginx.localhost.com.conf:13](file:///etc/nginx/conf.d/nginx.localhost.com.conf#L13) (`/etc/nginx/conf.d/nginx.localhost.com.conf:13`))
-   Subject   : C = US, ST = State, L = City, O = LocalHost, CN = nginx.localhost.com
-   Issuer    : C = US, ST = State, L = City, O = LocalHost, CN = nginx.localhost.com
-   SANs      : n/a
-   Expires   : Nov 14 12:27:30 2027 GMT (364 days remaining)
-   Key / Sig : 2048 bit / sha256WithRSAEncryption
- **[ OK ]** Certificate /etc/ssl/certs/nginx/nginx.crt validity OK (364 days remaining)

### Private key permissions

- **[ OK ]** Private key /etc/ssl/certs/nginx/github.jaganathan.co.uk.key permissions OK (600 root:root)
- **[ OK ]** Private key /etc/ssl/certs/nginx/nginx.key permissions OK (600 root:root)

<a id="8-security-audit-config-based"></a>

## 8. SECURITY AUDIT (config-based)


### Information disclosure

- **[ OK ]** server_tokens off (Nginx version hidden)
- **[ OK ]** X-Powered-By hidden from upstreams

### TLS protocol & cipher policy

- ssl_protocols configured: TLSv1.2 TLSv1.3 TLSv1.2 TLSv1.3  
- **[ OK ]** No legacy SSL/TLSv1.0/TLSv1.1 protocols enabled
- **[ OK ]** TLSv1.3 enabled
- ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
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
- client_max_body_size: 25m 

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
- **[ OK ]** Web root /var/www/html/nginx.localhost.com has no world-writable files

### Log dir permissions


```text
drwxr-xr-x 2 root adm 4096 Nov 14 20:34 /var/log/nginx
```


<a id="10-system-level-hardening"></a>

## 10. SYSTEM-LEVEL HARDENING


### Firewall

- **[WARN] (`WARN-3`)** No active host firewall rules detected ( or requires root to inspect iptables/nftables )
  - **Where**: [etc](file:///etc) (`/etc`)
  - **Reference**: <https://wiki.debian.org/Uncomplicated%20Firewall%20%28ufw%29>
  - **How to Fix**: Enable host firewall (e.g. sudo ufw allow 'Nginx Full' && sudo ufw enable) or run audit with sudo

### Fail2ban

- **[WARN] (`WARN-4`)** fail2ban is not installed (recommended for nginx-http-auth and bot/scanner rate-banning)
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
- Log file [github.jaganathan.co.uk.access.log](file:///var/log/nginx/github.jaganathan.co.uk.access.log) (`/var/log/nginx/github.jaganathan.co.uk.access.log`) — size=4.0K mtime=2026-11-14 20:34:29
- Log file [nginx.localhost.com.access.log](file:///var/log/nginx/nginx.localhost.com.access.log) (`/var/log/nginx/nginx.localhost.com.access.log`) — size=4.0K mtime=2026-11-14 18:43:01
- Log file [error.log](file:///var/log/nginx/error.log) (`/var/log/nginx/error.log`) — size=0 mtime=2026-11-14 17:33:44
- Log file [github.jaganathan.co.uk.error.log](file:///var/log/nginx/github.jaganathan.co.uk.error.log) (`/var/log/nginx/github.jaganathan.co.uk.error.log`) — size=4.0K mtime=2026-11-14 20:34:29
- Log file [nginx.localhost.com.error.log](file:///var/log/nginx/nginx.localhost.com.error.log) (`/var/log/nginx/nginx.localhost.com.error.log`) — size=0 mtime=2026-11-14 17:33:46
- Total /var/log/nginx size: 20K

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
- Analysing error log: [github.jaganathan.co.uk.error.log](file:///var/log/nginx/github.jaganathan.co.uk.error.log) (`/var/log/nginx/github.jaganathan.co.uk.error.log`)

### Entries by severity (last 50000 lines)


```text
      1 [error]
```


### Top 10 error messages


```text
      1 connect() failed (111: Connection refused) while connecting to upstream, client: X, server: github.jaganathan.co.uk, req
```


### Last 15 error/crit entries


```text
2026/11/14 20:34:29 [error] 76483#76483: *14 connect() failed (111: Connection refused) while connecting to upstream, client: 127.0.0.1, server: github.jaganathan.co.uk, request: "GET / HTTP/2.0", upstream: "http://127.0
```

- **[WARN] (`WARN-5`)** Upstream/backend connection errors found in /var/log/nginx/github.jaganathan.co.uk.error.log
  - **Where**: [github.jaganathan.co.uk.error.log](file:///var/log/nginx/github.jaganathan.co.uk.error.log) (`/var/log/nginx/github.jaganathan.co.uk.error.log`)
  - **Reference**: <https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_read_timeout>
  - **How to Fix**: Check backend service health and inspect recent lines in /var/log/nginx/github.jaganathan.co.uk.error.log
- Analysing error log: [nginx.localhost.com.error.log](file:///var/log/nginx/nginx.localhost.com.error.log) (`/var/log/nginx/nginx.localhost.com.error.log`)
- **[ OK ]** Error log /var/log/nginx/nginx.localhost.com.error.log is empty (0 errors recorded)

<a id="13-access-log-traffic-analysis-assumes-combined-format"></a>

## 13. ACCESS LOG & TRAFFIC ANALYSIS (assumes combined format)

- Cannot read access log [access.log](file:///var/log/nginx/access.log) (`/var/log/nginx/access.log`) (run with sudo to analyse traffic)
- Analysing access log: [github.jaganathan.co.uk.access.log](file:///var/log/nginx/github.jaganathan.co.uk.access.log) (`/var/log/nginx/github.jaganathan.co.uk.access.log`) (last 50000 of 1 lines)
- Time range: [14/Nov/2026:20:34:29 +0530]  ->  [14/Nov/2026:20:34:29 +0530]

### HTTP status code distribution


```text
      1 502
```


### Status classes


```text
5xx       1  (100.0%)
```

- **[FAIL] (`FAIL-1`)** High HTTP 5xx error rate >= 5% (1 of 1 requests) in /var/log/nginx/github.jaganathan.co.uk.access.log
  - **Where**: [github.jaganathan.co.uk.access.log](file:///var/log/nginx/github.jaganathan.co.uk.access.log) (`/var/log/nginx/github.jaganathan.co.uk.access.log`)
  - **Reference**: <https://docs.nginx.com/nginx/admin-guide/monitoring/logging/>
  - **How to Fix**: Inspect top 5xx URLs in /var/log/nginx/github.jaganathan.co.uk.access.log and correlate with /var/log/nginx/error.log
/var/log/nginx/github.jaganathan.co.uk.error.log
/var/log/nginx/nginx.localhost.com.error.log

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


```text
      1 502 /
```

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
HTTP/1.1 200 OK
Server: nginx
Date: Sat, 14 Nov 2026 15:16:58 GMT
Content-Type: text/html
Content-Length: 615
Last-Modified: Sat, 14 Nov 2026 12:03:44 GMT
Connection: keep-alive
ETag: "6af84e20-267"
Accept-Ranges: bytes

```

- Probing https://127.0.0.1 (Host: localhost, -k)

```text
HTTP/2 502 
server: nginx
date: Sat, 14 Nov 2026 15:16:58 GMT
content-type: text/html
content-length: 150
strict-transport-security: max-age=63072000; includeSubDomains
x-frame-options: SAMEORIGIN
x-content-type-options: nosniff
referrer-policy: strict-origin-when-cross-origin
permissions-policy: geolocation=(), microphone=(), camera=()
content-security-policy: default-src 'self' 'unsafe-inline' data: https:;

```


### Security headers on first named server over HTTPS

- Testing github.jaganathan.co.uk via --resolve github.jaganathan.co.uk:443:127.0.0.1

```text
HTTP/2 502 
server: nginx
date: Sat, 14 Nov 2026 15:16:58 GMT
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

- Theoretical max clients ~ worker_processes(2) x worker_connections(768) = 1536 (halve for reverse proxy)
- worker_rlimit_nofile not set - ensure ulimit >= 2 x worker_connections
- **[ OK ]** gzip compression enabled
- gzip_types not set (only text/html compressed by default)
- No proxy/fastcgi cache configured
- No expires/Cache-Control rules for static assets
- **[ OK ]** sendfile on

### nginx memory (RSS)


```text
total RSS: 19.3 MB across 3 processes
```


### Top 5 processes by memory


```text
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
ubuntu     80322 36.4  9.5 1463382388 383384 ?   S<l  20:46   0:11 /apps/antigravity/antigravityIde/antigravity-ide --type=zygote
ubuntu     80494 13.6  7.9 1461621164 317556 ?   Sl   20:46   0:04 /proc/self/exe --type=utility --utility-sub-type=node.mojom.NodeService -
ubuntu     81130 26.5  7.2 1459871592 292272 ?   Sl   20:46   0:04 /apps/antigravity/antigravityIde/antigravity-ide --type=zygote
ubuntu     81099  5.6  7.1 2252024 285156 ?      Sl   20:46   0:01 /home/ubuntu/.gemini/bin/agy --hub --hub-port=42805 --app_data_dir=antigr
ubuntu     80245 16.0  6.7 1461795436 272312 ?   S<Lsl 20:46   0:05 /apps/antigravity/antigravityIde/antigravity-ide
```


### Files/sockets open by nginx

- 13 open descriptors (lsof)

<a id="16-backends-related-services"></a>

## 16. BACKENDS & RELATED SERVICES


### Upstream/proxy targets reachability

- **[FAIL] (`FAIL-2`)** Upstream backend 127.0.0.1:3000 is NOT reachable (configured at github.jaganathan.co.uk.conf)
  - **Where**: [github.jaganathan.co.uk.conf:57](file:///etc/nginx/conf.d/github.jaganathan.co.uk.conf#L57) (`/etc/nginx/conf.d/github.jaganathan.co.uk.conf:57`)
  - **Reference**: <https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_pass>
  - **How to Fix**: Verify the backend application listening on 127.0.0.1:3000 is running and check its logs

### Common companion services


```text
docker             active (sysvinit)
```


### Cron jobs mentioning nginx / certbot

- No cron files mentioning nginx or certbot

<a id="17-config-backup-change-tracking"></a>

## 17. CONFIG BACKUP & CHANGE TRACKING

- 10 most recently modified files in /etc/nginx:
- 2026-11-14 20:34 — [nginx.conf](file:///etc/nginx/nginx.conf) (`/etc/nginx/nginx.conf`)
- 2026-11-14 20:34 — [github.jaganathan.co.uk.conf](file:///etc/nginx/conf.d/github.jaganathan.co.uk.conf) (`/etc/nginx/conf.d/github.jaganathan.co.uk.conf`)
- 2026-11-14 20:34 — [00-production-hardening.conf](file:///etc/nginx/conf.d/00-production-hardening.conf) (`/etc/nginx/conf.d/00-production-hardening.conf`)
- 2026-11-14 17:57 — [nginx.localhost.com.conf](file:///etc/nginx/conf.d/nginx.localhost.com.conf) (`/etc/nginx/conf.d/nginx.localhost.com.conf`)
- 2026-07-18 21:48 — [win-utf](file:///etc/nginx/win-utf) (`/etc/nginx/win-utf`)
- 2026-07-18 21:48 — [uwsgi_params](file:///etc/nginx/uwsgi_params) (`/etc/nginx/uwsgi_params`)
- 2026-07-18 21:48 — [snakeoil.conf](file:///etc/nginx/snippets/snakeoil.conf) (`/etc/nginx/snippets/snakeoil.conf`)
- 2026-07-18 21:48 — [fastcgi-php.conf](file:///etc/nginx/snippets/fastcgi-php.conf) (`/etc/nginx/snippets/fastcgi-php.conf`)
- 2026-07-18 21:48 — [default](file:///etc/nginx/sites-available/default) (`/etc/nginx/sites-available/default`)
- 2026-07-18 21:48 — [scgi_params](file:///etc/nginx/scgi_params) (`/etc/nginx/scgi_params`)
- Config not under version control (consider git or etckeeper in /etc/nginx)
