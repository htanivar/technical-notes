# NGINX Production Site Summary — github.jaganathan.co.uk

Generated on: 2026-11-14 20:34:04 IST

## I. Site Overview & Connection Details

| Property | Value |
| :--- | :--- |
| **Server Name (Domain)** | `github.jaganathan.co.uk`  |
| **Site Mode** | `proxy` (Reverse Proxy -> http://127.0.0.1:3000 (WebSocket enabled)) |
| **Primary App URL** | https://github.jaganathan.co.uk/ |
| **HTTP Entry URL** | http://github.jaganathan.co.uk/ (301 Redirects to HTTPS) |
| **Healthcheck URL** | https://github.jaganathan.co.uk/healthz |
| **Host / LAN IP** | `192.168.1.2` |
| **HTTP Listen Port** | `80` |
| **HTTPS Listen Port** | `443` |
| **Backend App Port** | `127.0.0.1:3000` |

---

## II. File Locations (Config, Logs, Web Root & SSL Certificates)

| Resource | Path / Location |
| :--- | :--- |
| **Virtual Host Config** | `/etc/nginx/conf.d/github.jaganathan.co.uk.conf` |
| **Global Hardening Config** | `/etc/nginx/conf.d/00-production-hardening.conf` |
| **Main NGINX Config** | `/etc/nginx/nginx.conf` |
| **Document Root / Upstream** | `http://127.0.0.1:3000` |
| **Access Log** | `/var/log/nginx/github.jaganathan.co.uk.access.log` |
| **Error Log** | `/var/log/nginx/github.jaganathan.co.uk.error.log` |
| **Configuration Run Log** | `/var/log/nginx_configure_20261114_203032.log` |
| **SSL Mode** | `self-signed` |
| **SSL Certificate** | `/etc/ssl/certs/nginx/github.jaganathan.co.uk.crt` |
| **SSL Private Key** | `/etc/ssl/certs/nginx/github.jaganathan.co.uk.key` (Permissions: `600`) |
| **SSL Issuer & Expiry** | C = US, ST = State, L = City, O = ProductionNginx, CN = github.jaganathan.co.uk — Expires: `Nov 14 15:04:03 2027 GMT` |

---

## III. Verification & Testing Commands

1. **Test the site locally via Host header**:
   ```bash
   curl -s -k -H "Host: github.jaganathan.co.uk" https://127.0.0.1:443/
   ```

2. **Test the site & inspect security headers via DNS override**:
   ```bash
   curl -k -i --resolve github.jaganathan.co.uk:443:127.0.0.1 https://github.jaganathan.co.uk/
   ```

3. **Check the healthcheck endpoint**:
   ```bash
   curl -s -k -H "Host: github.jaganathan.co.uk" https://127.0.0.1:443/healthz
   ```

4. **Test NGINX configuration syntax**:
   ```bash
   sudo nginx -t
   ```

---

## IV. Log Monitoring & Day-to-Day Operations

- **Tail site access & error logs in real time**:
  ```bash
  sudo tail -f /var/log/nginx/github.jaganathan.co.uk.access.log /var/log/nginx/github.jaganathan.co.uk.error.log
  # Or using nginx-ops.sh:
  /home/ubuntu/code/github/raviautopilot/technical-notes/000_init/install/nginx/nginx-ops.sh logs --domain github.jaganathan.co.uk --follow
  ```

- **Check service status, reload, or restart NGINX**:
  ```bash
  /home/ubuntu/code/github/raviautopilot/technical-notes/000_init/install/nginx/nginx-ops.sh status
  sudo /home/ubuntu/code/github/raviautopilot/technical-notes/000_init/install/nginx/nginx-ops.sh reload
  sudo /home/ubuntu/code/github/raviautopilot/technical-notes/000_init/install/nginx/nginx-ops.sh restart
  ```

- **Run full security & configuration audit**:
  ```bash
  sudo /home/ubuntu/code/github/raviautopilot/technical-notes/000_init/install/nginx/status_nginx.sh
  ```

---

## V. Production Hardening Applied

- **TLS 1.2 & TLS 1.3 Only**: Legacy `SSLv3`, `TLSv1`, and `TLSv1.1` disabled.
- **AEAD Cipher Suites**: Configured Mozilla Intermediate ECDHE/GCM/CHACHA20 ciphers (`ssl_prefer_server_ciphers off`).
- **OWASP Security Headers**: `Strict-Transport-Security`, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`, and `Content-Security-Policy`.
- **DoS & Rate Limiting**: Per-IP rate limit (`20r/s`, burst `40`) and `client_max_body_size 25m`.
- **Sensitive File Protection**: Blocks hidden dotfiles (`/.git`, `/.env`, `/.htpasswd`) and backup/SQL artifacts (`.bak`, `.sql`, `.old`, `.swp`).
