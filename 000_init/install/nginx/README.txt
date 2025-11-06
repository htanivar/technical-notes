--- NGINX Installation and Configuration Summary ---

This guide details the steps to set up a new website (Virtual Host) on your NGINX server.

## I. Installed Test Site Details
1. **Test URL**: https://nginx.localhost.com/
2. **Configuration File**: /etc/nginx/conf.d/nginx.localhost.com.conf
3. **Document Root**: /var/www/html/nginx.localhost.com
4. **Self-Signed Certificate**: /etc/ssl/certs/nginx/nginx.crt
5. **Self-Signed Key**: /etc/ssl/certs/nginx/nginx.key

## II. How to Add a New Website (Virtual Host)

### 1. Create the Document Root
Create the directory that will hold your website files (HTML, CSS, etc.).

$ sudo mkdir -p /var/www/html/mynewsite.com

### 2. Create the Configuration File
Create a new file in the conf.d directory. Use a descriptive name ending in .conf.

$ sudo nano /etc/nginx/conf.d/mynewsite.com.conf

### 3. Basic HTTP Configuration
Paste the following structure into the file, replacing 'mynewsite.com' with your actual domain:

server {
    listen 80;
    server_name mynewsite.com www.mynewsite.com;

    root /var/www/html/mynewsite.com;
    index index.html index.htm;

    # Standard location block
    location / {
        try_files $uri $uri/ =404;
    }
}

### 4. Optional: HTTPS (SSL) Configuration
For HTTPS, you will need a valid SSL certificate (e.g., from Let's Encrypt or a vendor).
A simple HTTPS block would look like this:

server {
    listen 443 ssl;
    server_name mynewsite.com;

    # IMPORTANT: Update these paths to your actual certificate files
    ssl_certificate /etc/ssl/certs/mynewsite.crt;
    ssl_certificate_key /etc/ssl/private/mynewsite.key;

    root /var/www/html/mynewsite.com;
    index index.html;

    # ... rest of location blocks ...
}

### 5. Final Steps: Test and Restart
After saving your new .conf file, you must check the syntax and reload NGINX.

* **Test Config Syntax**:
    $ sudo nginx -t

* **Reload NGINX**:
    $ sudo systemctl reload nginx

## III. Testing Commands
Use these commands to verify the installation:

* **Check the current test site**:
    $ curl -s -k -H "Host: nginx.localhost.com" https://127.0.0.1/

* **View the full installation log**:
    $ cat /var/log/nginx_install_20251106_090212.log
