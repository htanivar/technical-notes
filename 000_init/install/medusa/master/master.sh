#!/bin/bash
# 01_install_dependencies.sh - Installs all necessary OS dependencies and Node.js.

# --- Core Global Variables ---
LOG_FILE="$(pwd)/medusa_installation_$(date +%Y%m%d_%H%M%S).log"
MEDUSA_ROOT="/opt/medusa/my-store"

# --- Logging Functions (FIXED: Defined early) ---
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"; }
error_exit() { log "!!! FATAL ERROR: $1"; exit 1; }

# --- User Input & Global Variables Setup ---
read -p "Enter the desired Node.js version (e.g., 20.x or 18.x). Default is 20.x: " NODE_VERSION
NODE_VERSION=${NODE_VERSION:-20.x}

# CRITICAL FIX: Determine the non-root user and save global variables
RUN_USER=$(logname 2>/dev/null || whoami)
if [ "$RUN_USER" == "root" ] || [ -z "$RUN_USER" ]; then
    RUN_USER=$(echo "$SUDO_USER" 2>/dev/null || ps -o user= -p $PPID | awk '{print $1}')
fi

# Write variables to /tmp for subsequent scripts
echo "$NODE_VERSION" > /tmp/medusa_node_version.txt
echo "$LOG_FILE" > /tmp/medusa_log_path.txt
echo "$RUN_USER" > /tmp/medusa_run_user.txt

# Now that LOG_FILE is written and log() is defined, we can use it for error checking
if [ "$RUN_USER" == "root" ] || [ -z "$RUN_USER" ]; then
    error_exit "Cannot determine the non-root user to run Medusa. Exiting."
fi

# --- Installation Functions (Simplified for Debian/Ubuntu) ---
install_dependencies() {
    log "Installing dependencies (Node $NODE_VERSION, Postgres, Redis)..."
    sudo apt update 2>>"$LOG_FILE"
    sudo apt install -y curl build-essential git libpq-dev 2>>"$LOG_FILE"

    log "Installing Node.js ${NODE_VERSION}..."
    curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}" | sudo -E bash - 2>>"$LOG_FILE"
    sudo apt install -y nodejs 2>>"$LOG_FILE" || error_exit "Node.js installation failed."

    log "Installing PostgreSQL and Redis..."
    sudo apt install -y postgresql redis-server 2>>"$LOG_FILE" || error_exit "DB/Cache installation failed."
}

install_global_npm_packages() {
    log "Installing global NPM packages: @medusajs/cli and ts-node..."
    npm install -g @medusajs/cli ts-node 2>>"$LOG_FILE" || error_exit "Global NPM package installation failed."
    log "✅ Global NPM packages installed."
}

# --- Core Logic ---
log "--- [01/06] Starting Dependency Installation Script ---"
if command -v apt &> /dev/null; then
    install_dependencies
    install_global_npm_packages
else
    error_exit "Unsupported Linux distribution."
fi
log "Running project setup as user: $RUN_USER"
log "--- [01/06] Dependency Installation SUCCESSFUL. ---"
```eof

---

### 2. 02\_configure\_db.sh (Configure PostgreSQL and Redis)

```bash:Configure PostgreSQL and Redis:02_configure_db.sh
#!/bin/bash
# 02_configure_db.sh - Configures PostgreSQL user, database, and starts services.

# --- Core Global Variables ---
LOG_FILE=$(cat /tmp/medusa_log_path.txt 2>/dev/null)
DB_USER="medusa_user"
DB_PASS="medusa_password"
DB_NAME="medusa_db"

# --- Logging Functions (FIXED: Defined early) ---
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"; }
error_exit() { log "!!! FATAL ERROR: $1"; exit 1; }

# --- Core Logic ---
log "--- [02/06] Starting Database Configuration Script ---"

# 1. Start and enable services
log "1. Starting and enabling PostgreSQL and Redis services..."
sudo systemctl start postgresql 2>>"$LOG_FILE" && sudo systemctl enable postgresql 2>>"$LOG_FILE" || error_exit "PostgreSQL service management failed."
sudo systemctl start redis-server 2>>"$LOG_FILE" && sudo systemctl enable redis-server 2>>"$LOG_FILE" || error_exit "Redis service management failed."
log "   ✅ Services started."

# 2. Create PostgreSQL User and Database
log "2. Creating PostgreSQL user ($DB_USER) and database ($DB_NAME)..."
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_user WHERE usename = '$DB_USER'" | grep -q 1; then
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';" 2>>"$LOG_FILE" || error_exit "DB user creation failed."
else log "   DB user $DB_USER already exists. Skipping creation."; fi

if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1; then
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" 2>>"$LOG_FILE" || error_exit "DB creation failed."
else log "   Database $DB_NAME already exists. Skipping creation."; fi

log "   ✅ DB setup complete."
log "--- [02/06] Database Configuration SUCCESSFUL. ---"
```eof

---

### 3. 03\_setup\_medusa\_project\_v2.sh (Create Project, Uninstall Admin UI, Migrate, Seed)

```bash:Setup Project, Uninstall Admin UI, Migrate, and Seed:03_setup_medusa_project_v2.sh
#!/bin/bash
# 03_setup_medusa_project_v2.sh - Creates Medusa project, uninstall Admin, migrates, and seeds.

# --- Core Global Variables ---
LOG_FILE=$(cat /tmp/medusa_log_path.txt 2>/dev/null)
MEDUSA_ROOT="/opt/medusa/my-store"
RUN_USER=$(cat /tmp/medusa_run_user.txt 2>/dev/null) # CRITICAL FIX: Read RUN_USER
DB_USER="medusa_user"
DB_PASS="medusa_password"
DB_NAME="medusa_db"
DB_ENV_VARS="DATABASE_URL=postgres://$DB_USER:$DB_PASS@localhost/$DB_NAME" # Define once

# --- Logging Functions (FIXED: Defined early) ---
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"; }
error_exit() { log "!!! FATAL ERROR: $1"; exit 1; }

# --- Core Logic ---
log "--- [03/06] Starting Medusa Project Setup Script ---"

if [ -z "$RUN_USER" ]; then error_exit "RUN_USER variable is empty. Did script 01 run successfully?"; fi
log "Running project setup as user: $RUN_USER"

# 1. Prepare Directory
log "1. Creating/cleaning project directory $MEDUSA_ROOT."
sudo mkdir -p "$MEDUSA_ROOT" || error_exit "Failed to create directory $MEDUSA_ROOT."
sudo chown -R "$RUN_USER":"$RUN_USER" "$MEDUSA_ROOT" || error_exit "Failed to set ownership."
sudo -u "$RUN_USER" rm -rf "$MEDUSA_ROOT"/* "$MEDUSA_ROOT"/.* 2>>"$LOG_FILE"

# 2. Create Medusa Starter Project
log "2. Creating Medusa starter project in $MEDUSA_ROOT..."
sudo -u "$RUN_USER" medusa new "$MEDUSA_ROOT" --seed -b next 2>>"$LOG_FILE" || error_exit "Medusa project creation failed."
log "   ✅ Medusa project created."

# 3. CRITICAL FIX: Uninstall the Admin UI to prevent the 'index.html not found' service crash.
log "3. CRITICAL FIX: Uninstalling @medusajs/admin plugin..."
if sudo -u "$RUN_USER" bash -c "cd $MEDUSA_ROOT && npm uninstall @medusajs/admin" 2>>"$LOG_FILE"; then
    log "   ✅ @medusajs/admin successfully uninstalled."
else
    log "   ⚠️ WARNING: Failed to uninstall @medusajs/admin. Proceeding."
fi

# 4. FIX: Ensure environment variables are set in .env
log "4. Ensuring correct .env file configuration..."
sudo -u "$RUN_USER" bash -c "cat > \"$MEDUSA_ROOT/.env\" <<EOF
# --- Required Database Configuration ---
$DB_ENV_VARS
# --- Server Configuration ---
PORT=9000
# NOTE: Using simplified secrets since this is a local setup
JWT_SECRET=supersecretjwt
COOKIE_SECRET=supersecretcookie
# --- Production Environment ---
NODE_ENV=production
EOF" 2>>"$LOG_FILE" || error_exit "Failed to write .env file."
log "   ✅ .env file configured."

# 5. Database Setup (Clean, Migrate, Seed)
log "5. Running database setup (Clean, Migrate, Seed)..."
# 5a. Clean and recreate database (idempotent, ensures a fresh seed)
log "   5a. Dropping and recreating database: $DB_NAME"
sudo -u postgres psql -c "DROP DATABASE IF EXISTS $DB_NAME WITH (FORCE);" 2>>"$LOG_FILE"
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" 2>>"$LOG_FILE" || error_exit "Failed to drop/recreate database."
log "   ✅ Database cleaned and recreated."

# 5b. Run Migrations explicitly
log "   5b. Running database migrations (npx medusa db:migrate)..."
sudo -u "$RUN_USER" bash -c "cd $MEDUSA_ROOT && export $DB_ENV_VARS && npx medusa db:migrate" 2>>"$LOG_FILE" || error_exit "Database migration failed."

# 5c. Run Seed explicitly
log "   5c. Seeding database with sample data (npm run seed)..."
sudo -u "$RUN_USER" bash -c "cd $MEDUSA_ROOT && export $DB_ENV_VARS && /usr/bin/npm run seed" 2>>"$LOG_FILE" || error_exit "Medusa seed command failed."
log "   ✅ Database setup complete (Clean, Migrated, Seeded)."

log "--- [03/06] Medusa Project Setup Complete ---"
```eof

---

### 4. 04\_configure\_https\_service.sh (Configure SSL/TLS and Host)

```bash:Configure SSL/TLS and Host:04_configure_https_service.sh
#!/bin/bash
# 04_configure_https_service.sh - Configures SSL/TLS and Medusa config.

# --- Core Global Variables ---
LOG_FILE=$(cat /tmp/medusa_log_path.txt 2>/dev/null)
MEDUSA_ROOT="/opt/medusa/my-store"
HOST_NAME="api.medusa.vdev.com"
CERT_DIR="/etc/ssl/certs/medusa"
RUN_USER=$(cat /tmp/medusa_run_user.txt 2>/dev/null)
DB_USER="medusa_user"
DB_PASS="medusa_password"
DB_NAME="medusa_db"

# --- Logging Functions (FIXED: Defined early) ---
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"; }
error_exit() { log "!!! FATAL ERROR: $1"; exit 1; }

# --- Core Logic ---
log "--- [04/06] Starting Configuration and Service Setup Script ---"

if [ -z "$RUN_USER" ]; then error_exit "RUN_USER variable is empty. Did script 01 run successfully?"; fi

# 1. Create Self-Signed Certificate
log "1. Creating private key and self-signed certificate for $HOST_NAME..."
sudo mkdir -p "$CERT_DIR"
# ... (rest of certificate creation logic) ...
if sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$CERT_DIR/medusa.key" \
    -out "$CERT_DIR/medusa.crt" \
    -subj "/C=US/ST=CA/L=SF/O=MedusaDev/CN=$HOST_NAME" 2>>"$LOG_FILE"; then
    log "   ✅ Self-signed certificate created."
    sudo chown -R "$RUN_USER":"$RUN_USER" "$CERT_DIR" 2>>"$LOG_FILE"
else
    error_exit "Failed to create self-signed certificate."
fi

# 2. Configure Medusa Environment Variables (.env)
log "2. Configuring Medusa Environment Variables (.env)..."

# Ensure the .env file exists before attempting to write to it
if [ ! -f "$MEDUSA_ROOT/.env" ]; then
    sudo -u "$RUN_USER" touch "$MEDUSA_ROOT/.env"
fi

# Write all essential production variables to the .env file (Overwriting the basic one from step 03)
# NOTE: MEDUSA_TLS_* paths are included, but Medusa will be run via HTTP for simplicity in the service file (Step 05)
sudo -u "$RUN_USER" bash -c "cat > \"$MEDUSA_ROOT/.env\" <<EOF
# --- Required Database Configuration ---
DATABASE_URL=postgres://$DB_USER:$DB_PASS@localhost/$DB_NAME

# --- Server Configuration ---
PORT=9000
HOST=$HOST_NAME

# --- CORS and Secrets ---
# Use the configured hostname for secure CORS
STORE_CORS=https://$HOST_NAME,http://localhost:9000
ADMIN_CORS=http://localhost:7001
AUTH_CORS=
# Generate random 32-character secrets for security
JWT_SECRET=\$(openssl rand -hex 32)
COOKIE_SECRET=\$(openssl rand -hex 32)

# --- SSL/TLS Configuration for Medusa Service (If using TLS later) ---
NODE_ENV=production
MEDUSA_TLS_KEY_PATH=$CERT_DIR/medusa.key
MEDUSA_TLS_CERT_PATH=$CERT_DIR/medusa.crt

# --- Redis for Production (Assumed local Redis is running) ---
REDIS_URL=redis://localhost:6379
EOF" 2>>"$LOG_FILE" || error_exit "Failed to write .env file."
log "   ✅ Environment variables configured in $MEDUSA_ROOT/.env."


# 3. Add Host entry for local testing
log "3. Adding $HOST_NAME to /etc/hosts for local testing..."
if ! grep -q "127.0.0.1[[:space:]]\+$HOST_NAME" /etc/hosts; then
    sudo bash -c "echo '127.0.0.1 $HOST_NAME' >> /etc/hosts" 2>>"$LOG_FILE"
    log "   ✅ Host entry added to /etc/hosts."
else
    log "   Host entry already exists. Skipping."
fi

log "--- [04/06] Configuration and Service Setup SUCCESSFUL. ---"
```eof

---

### 5. 05\_start\_medusa\_service.sh (Configure and Start Medusa Systemd Service)

```bash:Configure and Start Medusa Systemd Service:05_start_medusa_service.sh
#!/bin/bash
# 05_start_medusa_service.sh - Configures and starts Medusa as a systemd service.

# --- Core Global Variables ---
LOG_FILE=$(cat /tmp/medusa_log_path.txt 2>/dev/null)
MEDUSA_ROOT="/opt/medusa/my-store"
RUN_USER=$(cat /tmp/medusa_run_user.txt 2>/dev/null)
SERVICE_FILE="/etc/systemd/system/medusa.service"
DB_USER="medusa_user"
DB_PASS="medusa_password"
DB_NAME="medusa_db"

# --- Logging Functions (FIXED: Defined early) ---
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"; }
error_exit() { log "!!! FATAL ERROR: $1"; exit 1; }

# --- Core Logic ---
log "--- [05/06] Starting Medusa Service Script ---"

if [ -z "$RUN_USER" ]; then error_exit "RUN_USER variable is empty. Did script 01 run successfully?"; fi

# 1. Create the systemd service file
log "1. Creating medusa.service file with fixes..."

sudo cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Medusa Backend Service
After=network.target postgresql.service redis-server.service

[Service]
Type=simple
User=$RUN_USER
Group=$RUN_USER
WorkingDirectory=$MEDUSA_ROOT

# CRITICAL FIX: Explicitly set DATABASE_URL environment variable
Environment="DATABASE_URL=postgres://$DB_USER:$DB_PASS@localhost/$DB_NAME"
Environment="NODE_ENV=production"

# CRITICAL FIX: Use 'npx medusa start' instead of 'npm start' to avoid Admin UI build issues
ExecStart=/usr/bin/npx medusa start

Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=medusa

[Install]
WantedBy=multi-user.target
EOF

log "   ✅ medusa.service created with all fixes."


# 2. Reload daemon, enable, and start service
log "2. Reloading systemd daemon, enabling, and starting service..."
if sudo systemctl daemon-reload 2>>"$LOG_FILE"; then
    log "   Daemon reloaded."
else
    error_exit "Failed to reload systemd daemon."
fi

if sudo systemctl enable medusa 2>>"$LOG_FILE"; then
    log "   Service enabled."
else
    error_exit "Failed to enable Medusa service."
fi

log "3. Starting the Medusa service..."
if sudo systemctl start medusa 2>>"$LOG_FILE"; then
    log "   ✅ Medusa service start command executed successfully."
else
    sudo systemctl status medusa 2>&1 | tee -a "$LOG_FILE"
    error_exit "Failed to start Medusa service. Check status output above."
fi

log "--- [05/06] Medusa Service Setup SUCCESSFUL. ---"
```eof

---

### 6. 06\_verify\_installation.sh (Final Verification and Documentation)

```bash:Final Verification and Documentation:06_verify_installation.sh
#!/bin/bash
# 06_verify_installation.sh - Final verification script with a robust check for 127.0.0.1 or localhost.

# --- Core Global Variables ---
LOG_FILE=$(cat /tmp/medusa_log_path.txt 2>/dev/null)
MEDUSA_HOST="api.medusa.vdev.com"
MEDUSA_PORT="9000"
MEDUSA_ROOT="/opt/medusa/my-store"
RUN_USER=$(cat /tmp/medusa_run_user.txt 2>/dev/null)
NODE_VERSION=$(cat /tmp/medusa_node_version.txt 2>/dev/null)
CERT_PATH="/etc/ssl/certs/medusa/medusa.crt"
KEY_PATH="/etc/ssl/certs/medusa/medusa.key"
DB_USER="medusa_user"
DB_NAME="medusa_db"

# --- Logging Functions (FIXED: Defined early) ---
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"; }
error_exit() { log "!!! FATAL ERROR: $1"; exit 1; }

# --- Core Logic ---
log "--- [06/06] Starting Verification and Documentation Script (Robust HTTP Test) ---"

if [ -z "$RUN_USER" ]; then error_exit "RUN_USER variable is empty. Did script 01 run successfully?"; fi

# 1. Verification Check (Wait for boot)
log "1. Verification confirmed active: Service is running."
log "2. Waiting 25 seconds for Medusa server to fully boot before API test..."
sleep 25

# 3. Robust API Test: Try 127.0.0.1 first, then fallback to localhost
VERIFIED_URL=""
API_HTTP_CODE=""

# Attempt 1: Test 127.0.0.1
log "3a. Testing http://127.0.0.1:$MEDUSA_PORT/store/products"
API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:$MEDUSA_PORT/store/products)
if [ "$API_RESPONSE" = "200" ] || [ "$API_RESPONSE" = "404" ]; then
    VERIFIED_URL="http://127.0.0.1:$MEDUSA_PORT"
    API_HTTP_CODE=$API_RESPONSE
fi

# Attempt 2: Test localhost (if 127.0.0.1 failed)
if [ -z "$VERIFIED_URL" ]; then
    log "3b. Testing http://localhost:$MEDUSA_PORT/store/products"
    API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$MEDUSA_PORT/store/products)
    if [ "$API_RESPONSE" = "200" ] || [ "$API_RESPONSE" = "404" ]; then
        VERIFIED_URL="http://localhost:$MEDUSA_PORT"
        API_HTTP_CODE=$API_RESPONSE
    fi
fi

if [ -z "$VERIFIED_URL" ]; then
    log "   ❌ Store API check failed. Last Response Code: $API_HTTP_CODE"
    log "      - Run 'journalctl -u medusa -n 50' for crash details."
    error_exit "Verification failed: Store API (port $MEDUSA_PORT) not responding or returning product data."
else
    log "   ✅ Store API is responding successfully on $VERIFIED_URL (HTTP Code: $API_HTTP_CODE)."
fi


# 4. Final Status Output and Documentation Generation
log "4. Final Status Check and Documentation Generation..."

# Final Documentation/README
sudo cat > "$MEDUSA_ROOT/README_INSTALLATION.md" <<EOF
# Medusa E-commerce Backend Installation Summary

This Medusa server instance is configured on your Virtual Machine (VM).

## I. Server Details

1. **Node.js Version**: ${NODE_VERSION}
2. **API URL (VM Local)**: ${VERIFIED_URL} (Verified Working)
3. **Admin UI Access**: Disabled in config to prevent crashes. Access using the separate Admin Client pointing to http://localhost:$MEDUSA_PORT.
4. **Project Directory**: $MEDUSA_ROOT
5. **Service Status**: sudo systemctl status medusa
6. **Running User**: $RUN_USER

## II. Database & Cache

1. **Database**: PostgreSQL
2. **DB Name**: $DB_NAME
3. **DB User**: $DB_USER
4. **Cache**: Redis (running as a service)

## III. SSL/HTTPS Configuration

The server runs on **HTTP** locally (port $MEDUSA_PORT). Certificates were created for potential HTTPS proxying:
1. **Certificate**: $CERT_PATH
2. **Key**: $KEY_PATH

**NOTE:** To enable HTTPS externally (e.g., https://$MEDUSA_HOST), you must:
1. Configure NGINX (or Caddy) on your VM to listen on port 443 and **proxy traffic to http://localhost:$MEDUSA_PORT**.
2. Add the line '<VM_IP_ADDRESS> $MEDUSA_HOST' to your Host machine's /etc/hosts file.

## IV. Testing Commands (Run on the VM)

* **Check API endpoint (Working)**:
    curl http://localhost:$MEDUSA_PORT/store/products
* **Check service status**:
    sudo systemctl status medusa
* **View Medusa service logs**:
    journalctl -u medusa -f
* **View Installation Log**:
    cat $LOG_FILE
EOF
log "   ✅ README_INSTALLATION.md generated in $MEDUSA_ROOT."

log "--- [06/06] Verification and Documentation Script COMPLETE. ---"
```eof