# 🔐 Certbot Cheatsheet

> **Certbot** is the official EFF client for Let's Encrypt — automates obtaining, renewing, and managing free TLS/SSL certificates.

---

## 📦 Installation

### Ubuntu / Debian
```bash
sudo apt update
sudo apt install certbot
# With Apache plugin
sudo apt install python3-certbot-apache
# With Nginx plugin
sudo apt install python3-certbot-nginx
```

### CentOS / RHEL / Fedora
```bash
sudo dnf install certbot
sudo dnf install python3-certbot-apache   # Apache plugin
sudo dnf install python3-certbot-nginx    # Nginx plugin
```

### Snap (Universal / recommended by EFF)
```bash
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

### pip
```bash
pip install certbot
pip install certbot-apache
pip install certbot-nginx
```

---

## 🚀 Obtaining Certificates

### Apache (auto-configures Apache)
```bash
sudo certbot --apache -d example.com -d www.example.com
```

### Nginx (auto-configures Nginx)
```bash
sudo certbot --nginx -d example.com -d www.example.com
```

### Standalone (starts its own temp web server on port 80)
```bash
# Stop your web server first!
sudo certbot certonly --standalone -d example.com -d www.example.com
```

### Webroot (uses existing web server's document root)
```bash
sudo certbot certonly --webroot \
  -w /var/www/html \
  -d example.com \
  -d www.example.com
```

### DNS Challenge (for wildcard certificates)
```bash
sudo certbot certonly --manual \
  --preferred-challenges dns \
  -d "*.example.com" \
  -d example.com
```

### Manual / Interactive mode
```bash
sudo certbot certonly --manual -d example.com
```

### Non-interactive / Automated
```bash
sudo certbot certonly --standalone \
  --non-interactive \
  --agree-tos \
  --email admin@example.com \
  -d example.com
```

---

## 🔄 Renewal

### Test renewal (dry run — no actual changes)
```bash
sudo certbot renew --dry-run
```

### Renew all certificates
```bash
sudo certbot renew
```

### Renew a specific certificate
```bash
sudo certbot renew --cert-name example.com
```

### Renew and force even if not near expiry
```bash
sudo certbot renew --force-renewal
```

### Renew with pre/post hooks (e.g., restart services)
```bash
sudo certbot renew \
  --pre-hook "systemctl stop nginx" \
  --post-hook "systemctl start nginx"
```

### Renew with a deploy hook (runs only on successful renewal)
```bash
sudo certbot renew \
  --deploy-hook "systemctl reload nginx"
```

### Hook scripts (persistent hooks via directories)
```bash
# Place scripts in these directories:
/etc/letsencrypt/renewal-hooks/pre/      # Runs before renewal
/etc/letsencrypt/renewal-hooks/post/     # Runs after renewal attempt
/etc/letsencrypt/renewal-hooks/deploy/   # Runs after successful renewal
```

### Automated renewal via systemd timer (check status)
```bash
sudo systemctl status certbot.timer
sudo systemctl list-timers | grep certbot
```

### Automated renewal via cron (manual setup)
```bash
# Add to crontab:
0 3 * * * /usr/bin/certbot renew --quiet --deploy-hook "systemctl reload nginx"
```

---

## 📋 Certificate Management

### List all certificates
```bash
sudo certbot certificates
```

### Delete a certificate
```bash
sudo certbot delete --cert-name example.com
```

### Revoke a certificate
```bash
sudo certbot revoke --cert-path /etc/letsencrypt/live/example.com/cert.pem
```

### Revoke and delete
```bash
sudo certbot revoke \
  --cert-path /etc/letsencrypt/live/example.com/cert.pem \
  --delete-after-revoke
```

### Update certificate (add/remove domains)
```bash
sudo certbot certonly --cert-name example.com \
  -d example.com \
  -d www.example.com \
  -d blog.example.com   # new domain added
```

### Expand an existing certificate
```bash
sudo certbot --expand -d example.com -d www.example.com -d new.example.com
```

---

## 📁 File Locations

| Path | Description |
|------|-------------|
| `/etc/letsencrypt/live/<domain>/` | Symlinks to latest certs |
| `/etc/letsencrypt/live/<domain>/cert.pem` | Domain certificate |
| `/etc/letsencrypt/live/<domain>/chain.pem` | Intermediate chain |
| `/etc/letsencrypt/live/<domain>/fullchain.pem` | cert + chain (use this for Nginx/Apache) |
| `/etc/letsencrypt/live/<domain>/privkey.pem` | Private key |
| `/etc/letsencrypt/archive/<domain>/` | All historical certs |
| `/etc/letsencrypt/renewal/<domain>.conf` | Per-cert renewal config |
| `/etc/letsencrypt/renewal-hooks/` | Hook script directories |
| `/var/log/letsencrypt/letsencrypt.log` | Log file |

---

## ⚙️ Configuration Options

### Key flags

| Flag | Description |
|------|-------------|
| `-d <domain>` | Specify domain (repeat for multiple) |
| `--email <email>` | Contact email for notices |
| `--agree-tos` | Auto-agree to Let's Encrypt TOS |
| `--non-interactive` | Disable prompts (for scripts) |
| `--quiet` | Suppress output (except errors) |
| `--dry-run` | Simulate without making changes |
| `--force-renewal` | Force renewal even if cert is not expiring |
| `--cert-name <name>` | Target a specific certificate by name |
| `--preferred-challenges` | Set challenge type: `http`, `dns`, `tls-sni` |
| `--rsa-key-size <n>` | RSA key size (default: 2048) |
| `--key-type <type>` | `rsa` or `ecdsa` |
| `--elliptic-curve <curve>` | e.g., `secp256r1`, `secp384r1` |
| `--staging` | Use Let's Encrypt staging server (for testing) |
| `--server <url>` | Custom ACME server URL |
| `--webroot-path` | Path to webroot for webroot plugin |

### Use ECDSA key instead of RSA
```bash
sudo certbot certonly --key-type ecdsa \
  --elliptic-curve secp384r1 \
  -d example.com
```

### Use Let's Encrypt staging (avoid rate limits during testing)
```bash
sudo certbot certonly --staging -d example.com
```

---

## 🌐 Web Server Configuration Examples

### Nginx
```nginx
server {
    listen 443 ssl;
    server_name example.com www.example.com;

    ssl_certificate     /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    # Recommended TLS settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
}

server {
    listen 80;
    server_name example.com www.example.com;
    return 301 https://$host$request_uri;
}
```

### Apache
```apache
<VirtualHost *:443>
    ServerName example.com
    SSLEngine on
    SSLCertificateFile      /etc/letsencrypt/live/example.com/fullchain.pem
    SSLCertificateKeyFile   /etc/letsencrypt/live/example.com/privkey.pem
</VirtualHost>

<VirtualHost *:80>
    ServerName example.com
    Redirect permanent / https://example.com/
</VirtualHost>
```

---

## 🔍 Checking Certificate Info

### Inspect a live certificate
```bash
openssl x509 -in /etc/letsencrypt/live/example.com/cert.pem -text -noout
```

### Check expiry date
```bash
openssl x509 -in /etc/letsencrypt/live/example.com/cert.pem -noout -enddate
```

### Check a remote server's certificate
```bash
echo | openssl s_client -connect example.com:443 -servername example.com 2>/dev/null \
  | openssl x509 -noout -dates
```

### Verify certificate chain
```bash
openssl verify -CAfile /etc/letsencrypt/live/example.com/chain.pem \
  /etc/letsencrypt/live/example.com/cert.pem
```

---

## 🔁 DNS Plugin Examples (for Wildcard Certs)

### Cloudflare
```bash
pip install certbot-dns-cloudflare
# Create ~/.secrets/cloudflare.ini:
#   dns_cloudflare_api_token = your_api_token

sudo certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials ~/.secrets/cloudflare.ini \
  -d "*.example.com" -d example.com
```

### Route53 (AWS)
```bash
pip install certbot-dns-route53
sudo certbot certonly \
  --dns-route53 \
  -d "*.example.com" -d example.com
```

### DigitalOcean
```bash
pip install certbot-dns-digitalocean
sudo certbot certonly \
  --dns-digitalocean \
  --dns-digitalocean-credentials ~/.secrets/digitalocean.ini \
  -d "*.example.com" -d example.com
```

---

## 🚨 Troubleshooting

### View logs
```bash
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

### Rate limit check
Let's Encrypt limits: **5 duplicate certs/week**, **50 certs/registered domain/week**.
Use `--staging` to test without hitting limits.

### Port 80 not reachable (standalone)
```bash
# Ensure nothing is using port 80
sudo ss -tlnp | grep ':80'
# Temporarily stop web server
sudo systemctl stop nginx
sudo certbot certonly --standalone -d example.com
sudo systemctl start nginx
```

### Permission denied on privkey.pem
```bash
# Private key is readable only by root by default
sudo ls -la /etc/letsencrypt/live/example.com/
# If your app needs access, add to the ssl-cert group or use ACLs
sudo setfacl -m u:www-data:r /etc/letsencrypt/live/example.com/privkey.pem
sudo setfacl -m u:www-data:r /etc/letsencrypt/archive/example.com/privkey*.pem
```

### Force re-authentication
```bash
sudo certbot certonly --force-renewal -d example.com
```

### Reset/re-register account
```bash
sudo certbot register --update-registration --email new@example.com
```

---

## 📅 Rate Limits (Let's Encrypt)

| Limit | Value |
|-------|-------|
| Certificates per Registered Domain | 50 / week |
| Duplicate Certificates | 5 / week |
| Failed Validations | 5 / hour, per account, hostname |
| New Orders | 300 / 3 hours |
| SANs per Certificate | 100 domains |
| Accounts per IP | 10 / 3 hours |

> Use `--staging` to bypass rate limits during development/testing.
> Staging CA URL: `https://acme-staging-v02.api.letsencrypt.org/directory`

---

## ✅ Quick Reference

```bash
# Install (snap)
sudo snap install --classic certbot

# Get cert (Nginx)
sudo certbot --nginx -d example.com

# Get cert (Apache)
sudo certbot --apache -d example.com

# Get wildcard cert (DNS)
sudo certbot certonly --manual --preferred-challenges dns -d "*.example.com"

# List certs
sudo certbot certificates

# Dry-run renewal
sudo certbot renew --dry-run

# Force renew
sudo certbot renew --force-renewal

# Delete cert
sudo certbot delete --cert-name example.com

# Check expiry
openssl x509 -in /etc/letsencrypt/live/example.com/cert.pem -noout -enddate
```

---

*Certbot documentation: https://eff-certbot.readthedocs.io*
*Let's Encrypt: https://letsencrypt.org*
