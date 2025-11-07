#!/bin/bash
# 03_setup_medusa_project.sh

# --- Core Global Variables (Must match 01) ---
LOG_FILE=$(cat /tmp/medusa_log_path.txt 2>/dev/null)
MEDUSA_ROOT="/opt/medusa/my-store"
TEMP_ROLLBACK_FILE="/tmp/medusa_new_packages.txt"
# DB credentials are only needed for the seed command, defined for completeness
DB_USER="medusa_user"
DB_PASS="medusa_password"
DB_NAME="medusa_db"
RUN_USER=$(logname 2>/dev/null || whoami)

# --- Logging Functions ---
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"; }
error_exit() { log "!!! FATAL ERROR: $1"; exit 1; }

# --- Core Logic ---
log "--- [03/06] Starting Medusa Project Setup Script ---"

# 1. CLI installation is now handled in script 01.
log "1. Skipping CLI installation (done in step 01)."

# 2. Prepare Directory
log "2. Creating/cleaning project directory $MEDUSA_ROOT."
sudo mkdir -p "$MEDUSA_ROOT" || error_exit "Failed to create directory $MEDUSA_ROOT."
# Crucial: Ensure the project directory is owned by the execution user
sudo chown -R "$RUN_USER":"$RUN_USER" "$MEDUSA_ROOT"
log "   Ensuring project directory is clean for project setup..."
# Run cleanup as the user who owns the files
sudo -u "$RUN_USER" rm -rf "$MEDUSA_ROOT"/* 2>>"$LOG_FILE"
sudo -u "$RUN_USER" find "$MEDUSA_ROOT" -maxdepth 1 -name ".*" -not -name "." -not -name ".." -exec rm -rf {} \; 2>>"$LOG_FILE"

cd "$MEDUSA_ROOT" || error_exit "Failed to change directory to $MEDUSA_ROOT."

# 3. Robust Medusa Project Setup: Manual Clone
log "3. Manually cloning Medusa starter repository (medusajs/medusa-starter-default)..."

if ! command -v git &> /dev/null; then
    error_exit "Git is required but not installed."
fi

# Clone the repository as the non-root user
sudo -u "$RUN_USER" git clone https://github.com/medusajs/medusa-starter-default.git . --depth 1 2>>"$LOG_FILE" || error_exit "Git clone of Medusa starter failed."

log "   ✅ Repository cloned successfully."

# NPM install and Build steps must be run as the project owner ($RUN_USER)
# Since the script is running with sudo, we use sudo -u
log "4. Installing NPM dependencies (npm install --legacy-peer-deps)..."
sudo -u "$RUN_USER" /usr/bin/npm install --legacy-peer-deps 2>>"$LOG_FILE" || error_exit "NPM dependency installation failed."

log "5. Building Medusa modules (npm run build)..."
sudo -u "$RUN_USER" /usr/bin/npm run build 2>>"$LOG_FILE" || error_exit "Medusa build command failed."

# -----------------------------------------------------
# START: CORRECTED STEP 6 (Merged from successful patch)
# -----------------------------------------------------
log "6. Preparing database: Cleaning, Running Migrations, and Seeding Data (medusa db:migrate; npm run seed)..."

# CRITICAL FIX: Ensure PostgreSQL service is running & CLEAN THE DATABASE
log "   6a. Checking PostgreSQL service and performing database cleanup..."
# Ensure the service is running
sudo systemctl restart postgresql 2>>"$LOG_FILE" || log "   ⚠️ Could not explicitly restart postgresql. Proceeding."
sudo systemctl enable postgresql 2>>"$LOG_FILE"
sleep 5

# Drop and recreate the database to ensure a clean slate
log "      Dropping and recreating database: $DB_NAME"
# Drop the database (must be executed as the postgres user)
sudo -u postgres psql -c "DROP DATABASE IF EXISTS $DB_NAME;" 2>>"$LOG_FILE"
# Recreate the database, ensuring it is owned by the medusa user
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" 2>>"$LOG_FILE" || error_exit "Failed to drop/recreate database. Check if user $DB_USER exists."
log "   ✅ Database cleaned and recreated."

# Set environment variable string for both migration and seed commands
DB_ENV_VARS="DATABASE_URL=postgres://$DB_USER:$DB_PASS@localhost/$DB_NAME"

# 6b. Run Migrations explicitly AS THE PROJECT USER
log "   6b. Running database migrations (npx medusa db:migrate)..."
# FIX: Use the correct, explicit Medusa migration command and export env variables correctly.
sudo -u "$RUN_USER" bash -c "export $DB_ENV_VARS && npx medusa db:migrate" 2>>"$LOG_FILE" || error_exit "Database migration failed. The correct command ('medusa db:migrate') failed."

# 6c. Run Seed AS THE PROJECT USER
log "   6c. Seeding database with sample data (npm run seed)..."
sudo -u "$RUN_USER" bash -c "export $DB_ENV_VARS && /usr/bin/npm run seed" 2>>"$LOG_FILE" || error_exit "Medusa seed command failed."

# -----------------------------------------------------
# END: CORRECTED STEP 6
# -----------------------------------------------------

log "   ✅ Medusa project created, installed, built, migrated, and seeded."
log "--- [03/06] Medusa Project Setup SUCCESSFUL. ---"
exit 0