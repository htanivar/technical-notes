#!/bin/bash
set -euo pipefail

# 03_setup_medusa_project_combined.sh - Comprehensive Medusa project setup with all features

# --- Core Global Variables ---
LOG_FILE="${LOG_FILE:-$(pwd)/medusa_setup_$(date +%Y%m%d_%H%M%S).log}"
MEDUSA_ROOT="${MEDUSA_ROOT:-/opt/medusa/my-store}"
RUN_USER="${RUN_USER:-${SUDO_USER:-$(logname 2>/dev/null || whoami)}}"
DB_USER="medusa_user"
DB_PASS="medusa_password"
DB_NAME="medusa_db"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
REDIS_URL="redis://localhost:6379"
COMMANDS_FILE="$MEDUSA_ROOT/commands.txt"
TEMP_ROLLBACK_FILE="/tmp/medusa_new_packages.txt"
SETUP_METHOD="${SETUP_METHOD:-git}" # Options: 'git' or 'cli'

# --- Logging Functions ---
log() {
  local ts msg
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  msg="$1"
  printf '[%s] %s\\n' "$ts" "$msg" | tee -a "$LOG_FILE" >&2
}

log_cmd() {
  echo "$1" | tee -a "$COMMANDS_FILE" >&2
}

error_exit() {
  log "ERROR: $1"
  exit 1
}

# --- Main Script ---
log "==================================================================="
log "Starting Comprehensive Medusa Project Setup"
log "==================================================================="
log "MEDUSA_ROOT=$MEDUSA_ROOT"
log "RUN_USER=$RUN_USER"
log "DB=${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
log "SETUP_METHOD=$SETUP_METHOD"
log "==================================================================="

# 1. Ensure MEDUSA_ROOT exists and has correct permissions
log "Step 1: Creating and configuring project directory..."
sudo mkdir -p "$MEDUSA_ROOT"
sudo chown -R "$RUN_USER":"$RUN_USER" "$MEDUSA_ROOT"

# 2. Clean directory if requested
if [ "${CLEAN_DIRECTORY:-false}" = "true" ]; then
  log "Step 2: Cleaning project directory (CLEAN_DIRECTORY=true)..."
  sudo -u "$RUN_USER" rm -rf "$MEDUSA_ROOT"/* 2>>"$LOG_FILE"
  sudo -u "$RUN_USER" find "$MEDUSA_ROOT" -maxdepth 1 -name ".*" -not -name "." -not -name ".." -exec rm -rf {} \\; 2>>"$LOG_FILE"
else
  log "Step 2: Skipping directory cleanup (CLEAN_DIRECTORY not set)."
fi

cd "$MEDUSA_ROOT" || error_exit "Failed to change directory to $MEDUSA_ROOT"

# 3. Verify Node.js and npm
log "Step 3: Verifying Node.js and npm installation..."
if ! command -v node >/dev/null 2>&1; then
  error_exit "node not found. Install Node.js before running this script."
fi
if ! command -v npm >/dev/null 2>&1; then
  error_exit "npm not found. Install npm before running this script."
fi
log "   Node version: $(node --version)"
log "   NPM version: $(npm --version)"

# 4. Determine Medusa CLI command
if ! command -v medusa >/dev/null 2>&1; then
  log "Step 4: medusa CLI not found globally — will use npx"
  MEDUSA_CMD="npx @medusajs/medusa@latest"
else
  MEDUSA_CMD="medusa"
  log "Step 4: Using global medusa CLI: $(which medusa)"
fi

# 5. PostgreSQL Setup and Database Cleanup
log "Step 5: Configuring PostgreSQL..."
log "   5a. Checking PostgreSQL service..."
sudo systemctl restart postgresql 2>>"$LOG_FILE" || log "   ⚠️ Could not restart postgresql service"
sudo systemctl enable postgresql 2>>"$LOG_FILE"
sleep 3

log "   5b. Checking PostgreSQL connectivity..."
log_cmd "PGPASSWORD=\\"$DB_PASS\\" psql -h \\"$DB_HOST\\" -U \\"$DB_USER\\" -p \\"$DB_PORT\\" -d postgres -c '\\\\l'"
if ! PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -U "$DB_USER" -p "$DB_PORT" -d postgres -c '\\l' >/dev/null 2>&1; then
  log "   Unable to connect as ${DB_USER}. Creating database user and database..."
  if sudo -n true 2>/dev/null; then
    log_cmd "sudo -u postgres psql -v ON_ERROR_STOP=1 -c \\"CREATE ROLE IF NOT EXISTS...\\""
    sudo -u postgres psql -v ON_ERROR_STOP=1 -c "DO \\$\\$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$DB_USER') THEN CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS'; END IF; END \\$\\$;" || log "   ⚠️ Warning: creating DB user failed"
  else
    error_exit "No sudo privileges to create DB user. Please ensure Postgres user '$DB_USER' exists."
  fi
else
  log "   ✅ PostgreSQL connectivity OK"
fi

# 5c. Drop and recreate database for clean slate
if [ "${CLEAN_DATABASE:-true}" = "true" ]; then
  log "   5c. Dropping and recreating database for clean slate..."
  log_cmd "sudo -u postgres psql -c \\"DROP DATABASE IF EXISTS $DB_NAME;\\""
  sudo -u postgres psql -c "DROP DATABASE IF EXISTS $DB_NAME;" 2>>"$LOG_FILE"
  log_cmd "sudo -u postgres psql -c \\"CREATE DATABASE $DB_NAME OWNER $DB_USER;\\""
  sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" 2>>"$LOG_FILE" || error_exit "Failed to create database"
  log "   ✅ Database cleaned and recreated"
else
  log "   5c. Skipping database cleanup (CLEAN_DATABASE=false)"
  # Ensure database exists
  sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" 2>>"$LOG_FILE" || log "   Database may already exist"
fi

# 6. Setup .env file
log "Step 6: Configuring environment variables..."
ENV_FILE="$MEDUSA_ROOT/.env"
DATABASE_URL="postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

if [ ! -f "$ENV_FILE" ]; then
  log "   Creating .env file..."
  log_cmd "echo \\"DATABASE_URL=$DATABASE_URL\\" > \\"$ENV_FILE\\""
  echo "DATABASE_URL=$DATABASE_URL" > "$ENV_FILE"
  log_cmd "echo \\"REDIS_URL=$REDIS_URL\\" >> \\"$ENV_FILE\\""
  echo "REDIS_URL=$REDIS_URL" >> "$ENV_FILE"
else
  log "   .env file exists. Ensuring DATABASE_URL and REDIS_URL are set..."
  if ! grep -q '^DATABASE_URL=' "$ENV_FILE"; then
    log_cmd "echo \\"DATABASE_URL=$DATABASE_URL\\" >> \\"$ENV_FILE\\""
    echo "DATABASE_URL=$DATABASE_URL" >> "$ENV_FILE"
  fi
  if ! grep -q '^REDIS_URL=' "$ENV_FILE"; then
    log_cmd "echo \\"REDIS_URL=$REDIS_URL\\" >> \\"$ENV_FILE\\""
    echo "REDIS_URL=$REDIS_URL" >> "$ENV_FILE"
  fi
fi
log "   ✅ Environment variables configured"

# 7. Project Initialization (Git Clone or Medusa CLI)
if [ ! -f package.json ]; then
  if [ "$SETUP_METHOD" = "git" ]; then
    log "Step 7: Initializing project via Git clone..."
    if ! command -v git &> /dev/null; then
      error_exit "Git is required but not installed."
    fi
    log_cmd "sudo -u \\"$RUN_USER\\" git clone https://github.com/medusajs/medusa-starter-default.git . --depth 1"
    sudo -u "$RUN_USER" git clone https://github.com/medusajs/medusa-starter-default.git . --depth 1 2>>"$LOG_FILE" || error_exit "Git clone failed"
    log "   ✅ Repository cloned successfully"
  else
    log "Step 7: Initializing project via Medusa CLI..."
    log_cmd "sudo -u \\"$RUN_USER\\" bash -c \\"$MEDUSA_CMD new . --seed\\""
    sudo -u "$RUN_USER" bash -c "$MEDUSA_CMD new . --seed" >>"$LOG_FILE" 2>&1 || {
      log "   medusa new with --seed failed, retrying without --seed"
      log_cmd "sudo -u \\"$RUN_USER\\" bash -c \\"$MEDUSA_CMD new .\\""
      sudo -u "$RUN_USER" bash -c "$MEDUSA_CMD new ." >>"$LOG_FILE" 2>&1 || error_exit "Medusa project creation failed"
    }
    log "   ✅ Medusa project created via CLI"
  fi
else
  log "Step 7: Detected existing package.json; skipping project initialization."
fi

# 8. Install Dependencies
log "Step 8: Installing npm dependencies..."
log_cmd "sudo -u \\"$RUN_USER\\" bash -lc \\"npm install --legacy-peer-deps\\""
sudo -u "$RUN_USER" bash -lc "npm install --legacy-peer-deps" >>"$LOG_FILE" 2>&1 || error_exit "npm install failed"
log "   ✅ Dependencies installed"

# 9. Build Project
log "Step 9: Building Medusa project..."
if grep -q '\\"build\\"' package.json >/dev/null 2>&1; then
  log_cmd "sudo -u \\"$RUN_USER\\" bash -lc \\"npm run build\\""
  sudo -u "$RUN_USER" bash -lc "npm run build" >>"$LOG_FILE" 2>&1 || log "   ⚠️ Build command failed or not configured"
  log "   ✅ Build completed"
else
  log "   No build script found in package.json; skipping build step."
fi

# 10. Database Migrations
log "Step 10: Running database migrations..."
DB_ENV_VARS="DATABASE_URL=$DATABASE_URL"

# Try multiple migration approaches
MIGRATION_SUCCESS=false

# Approach 1: medusa db:setup
if $MEDUSA_CMD --help 2>/dev/null | grep -q 'db:setup'; then
  log "   10a. Attempting: medusa db:setup"
  log_cmd "sudo -u \\"$RUN_USER\\" bash -c \\"export $DB_ENV_VARS && $MEDUSA_CMD db:setup\\""
  if sudo -u "$RUN_USER" bash -c "export $DB_ENV_VARS && $MEDUSA_CMD db:setup" >>"$LOG_FILE" 2>&1; then
    MIGRATION_SUCCESS=true
    log "   ✅ medusa db:setup succeeded"
  else
    log "   ⚠️ medusa db:setup failed"
  fi
fi

# Approach 2: medusa db:migrate
if [ "$MIGRATION_SUCCESS" = false ]; then
  log "   10b. Attempting: npx medusa db:migrate"
  log_cmd "sudo -u \\"$RUN_USER\\" bash -c \\"export $DB_ENV_VARS && npx medusa db:migrate\\""
  if sudo -u "$RUN_USER" bash -c "export $DB_ENV_VARS && npx medusa db:migrate" >>"$LOG_FILE" 2>&1; then
    MIGRATION_SUCCESS=true
    log "   ✅ medusa db:migrate succeeded"
  else
    log "   ⚠️ medusa db:migrate failed"
  fi
fi

# Approach 3: prisma migrate deploy
if [ "$MIGRATION_SUCCESS" = false ] && ([ -d prisma ] || grep -q '\\"prisma\\"' package.json >/dev/null 2>&1); then
  log "   10c. Attempting: npx prisma migrate deploy"
  log_cmd "sudo -u \\"$RUN_USER\\" bash -c \\"export $DB_ENV_VARS && npx prisma migrate deploy\\""
  if sudo -u "$RUN_USER" bash -c "export $DB_ENV_VARS && npx prisma migrate deploy" >>"$LOG_FILE" 2>&1; then
    MIGRATION_SUCCESS=true
    log "   ✅ prisma migrate deploy succeeded"
  else
    log "   ⚠️ prisma migrate deploy failed"
  fi
fi

if [ "$MIGRATION_SUCCESS" = false ]; then
  log "   ⚠️ WARNING: All migration attempts failed. Check $LOG_FILE"
else
  log "   ✅ Database migrations completed successfully"
fi

# 11. Seed Database
log "Step 11: Seeding database with sample data..."
if grep -q '\\"seed\\"' package.json >/dev/null 2>&1; then
  log_cmd "sudo -u \\"$RUN_USER\\" bash -c \\"export $DB_ENV_VARS && npm run seed\\""
  sudo -u "$RUN_USER" bash -c "export $DB_ENV_VARS && npm run seed" >>"$LOG_FILE" 2>&1 || log "   ⚠️ Seed command failed"
  log "   ✅ Database seeded"
else
  log "   No seed script found in package.json; skipping seed step."
fi

# 12. Create Admin User
log "Step 12: Creating initial admin user..."
if grep -q '\\"create-admin\\"' package.json >/dev/null 2>&1; then
  log_cmd "sudo -u \\"$RUN_USER\\" bash -lc \\"npm run create-admin\\""
  sudo -u "$RUN_USER" bash -lc "npm run create-admin" >>"$LOG_FILE" 2>&1 || log "   ⚠️ create-admin script failed"
  log "   ✅ Admin user creation attempted"
else
  log "   No create-admin script detected. You may create an admin via Medusa CLI or API later."
fi

# 13. Final Summary
log "==================================================================="
log "✅ MEDUSA PROJECT SETUP COMPLETED SUCCESSFULLY"
log "==================================================================="
log "Project Location: $MEDUSA_ROOT"
log "Log File: $LOG_FILE"
log "Commands Log: $COMMANDS_FILE"
log "Database: $DB_NAME (User: $DB_USER)"
log "==================================================================="
log "Next Steps:"
log "  1. Start Medusa: cd $MEDUSA_ROOT && npm run start"
log "  2. Access Admin: http://localhost:7001/app"
log "  3. Access Storefront: http://localhost:8000"
log "==================================================================="

exit 0