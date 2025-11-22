#!/bin/bash
set -euo pipefail

# 03_setup_medusa_project.sh - Sets up Medusa project, DB, migrations, and initial admin user.

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

log() {
  local ts msg
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  msg="$1"
  printf '[%s] %s\n' "$ts" "$msg" | tee -a "$LOG_FILE" >&2
}
log_cmd() {
  echo "$1" | tee -a "$COMMANDS_FILE" >&2
}
error_exit() {
  log "ERROR: $1"
  exit 1
}

log "Starting Medusa project setup..."
log "MEDUSA_ROOT=$MEDUSA_ROOT, RUN_USER=$RUN_USER, DB=${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

# Ensure MEDUSA_ROOT exists and has correct perms
sudo mkdir -p "$MEDUSA_ROOT"
sudo chown -R "$RUN_USER":"$RUN_USER" "$MEDUSA_ROOT"

cd "$MEDUSA_ROOT"

# Ensure node/npm available
if ! command -v node >/dev/null 2>&1; then
  error_exit "node not found. Install Node.js before running this script."
fi
if ! command -v npm >/dev/null 2>&1; then
  error_exit "npm not found. Install npm before running this script."
fi

# Install medusa CLI locally if not present
if ! command -v medusa >/dev/null 2>&1; then
  log "medusa CLI not found globally — will use npx to run Medusa commands"
  MEDUSA_CMD="npx @medusajs/medusa@latest"
else
  MEDUSA_CMD="medusa"
fi

# Check Postgres connection
log "Checking PostgreSQL connectivity to ${DB_HOST}:${DB_PORT} as ${DB_USER}..."
log_cmd "CMD Issued: PGPASSWORD=\"$DB_PASS\" psql -h \"$DB_HOST\" -U \"$DB_USER\" -p \"$DB_PORT\" -d postgres -c '\\l'"
if ! PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -U "$DB_USER" -p "$DB_PORT" -d postgres -c '\l' >/dev/null 2>&1; then
  log "Unable to connect as ${DB_USER}. Attempting to create database user and database (requires sudo/postgres privileges)..."
  if sudo -n true 2>/dev/null; then
    log_cmd "CMD Issued: sudo -u postgres psql -v ON_ERROR_STOP=1 -c \"DO \$\$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$DB_USER') THEN CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS'; END IF; END \$\$;\""
    sudo -u postgres psql -v ON_ERROR_STOP=1 -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$DB_USER') THEN CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS'; END IF; END \$\$;" || log "Warning: creating DB user failed. Ensure postgres is configured for password auth."
    log_cmd "CMD Issued: sudo -u postgres psql -v ON_ERROR_STOP=1 -c \"CREATE DATABASE $DB_NAME OWNER $DB_USER;\""
    sudo -u postgres psql -v ON_ERROR_STOP=1 -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" || log "Warning: creating DB may have failed or already exists."
  else
    log "No sudo privileges to create DB user. Please ensure Postgres user '$DB_USER' exists and is password-auth enabled."
  fi
else
  log "Postgres connectivity OK."
fi

# Ensure .env exists and has correct DATABASE_URL and REDIS_URL
ENV_FILE="$MEDUSA_ROOT/.env"
DATABASE_URL="postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

if [ ! -f "$ENV_FILE" ]; then
  log "No .env file found. Creating one with DATABASE_URL and REDIS_URL."
  log_cmd "CMD Issued: echo \"DATABASE_URL=$DATABASE_URL\" > \"$ENV_FILE\""
  echo "DATABASE_URL=$DATABASE_URL" > "$ENV_FILE"
  log_cmd "CMD Issued: echo \"REDIS_URL=$REDIS_URL\" >> \"$ENV_FILE\""
  echo "REDIS_URL=$REDIS_URL" >> "$ENV_FILE"
else
  log ".env file found. Ensuring DATABASE_URL and REDIS_URL are set."
  if ! grep -q '^DATABASE_URL=' "$ENV_FILE"; then
    log_cmd "CMD Issued: echo \"DATABASE_URL=$DATABASE_URL\" >> \"$ENV_FILE\""
    echo "DATABASE_URL=$DATABASE_URL" >> "$ENV_FILE"
  fi
  if ! grep -q '^REDIS_URL=' "$ENV_FILE"; then
    log_cmd "CMD Issued: echo \"REDIS_URL=$REDIS_URL\" >> \"$ENV_FILE\""
    echo "REDIS_URL=$REDIS_URL" >> "$ENV_FILE"
  fi
fi

# Initialize medusa project if package.json missing
if [ ! -f package.json ]; then
  log "No package.json found — creating Medusa project skeleton..."
  log_cmd "CMD Issued: sudo -u \"$RUN_USER\" bash -c \"$MEDUSA_CMD new . --seed\""
  sudo -u "$RUN_USER" bash -c "$MEDUSA_CMD new . --seed" >>"$LOG_FILE" 2>&1 || {
    log "medusa new with --seed failed, retrying without --seed"
    log_cmd "CMD Issued: sudo -u \"$RUN_USER\" bash -c \"$MEDUSA_CMD new .\""
    sudo -u "$RUN_USER" bash -c "$MEDUSA_CMD new ." >>"$LOG_FILE" 2>&1 || error_exit "Medusa project creation failed. Check $LOG_FILE"
  }
else
  log "Detected existing project; skipping 'medusa new'."
fi

# Install dependencies
log_cmd "CMD Issued: sudo -u \"$RUN_USER\" bash -lc \"npm install --legacy-peer-deps\""
log "Installing npm dependencies..."
sudo -u "$RUN_USER" bash -lc "npm install --legacy-peer-deps" >>"$LOG_FILE" 2>&1 || error_exit "npm install failed. Check $LOG_FILE"

# Run database migrations / setup
log "Running Medusa DB setup/migrations..."
if $MEDUSA_CMD --help 2>/dev/null | grep -q 'db:setup'; then
  log_cmd "CMD Issued: sudo -u \"$RUN_USER\" bash -lc \"$MEDUSA_CMD db:setup\""
  sudo -u "$RUN_USER" bash -lc "$MEDUSA_CMD db:setup" >>"$LOG_FILE" 2>&1 || log "medusa db:setup failed; attempting fallback migrations"
fi

# Fallback: run prisma migrate deploy if prisma exists
if [ -d prisma ] || grep -q "\"prisma\"" package.json >/dev/null 2>&1; then
  log_cmd "CMD Issued: sudo -u \"$RUN_USER\" bash -lc \"npx prisma migrate deploy\""
  log "Attempting prisma migrate deploy..."
  sudo -u "$RUN_USER" bash -lc "npx prisma migrate deploy" >>"$LOG_FILE" 2>&1 || log "prisma migrate deploy failed or not configured"
fi

# Create initial admin (if Medusa provides a create-admin script)
if grep -q "\"create-admin\"" package.json >/dev/null 2>&1; then
  log_cmd "CMD Issued: sudo -u \"$RUN_USER\" bash -lc \"npm run create-admin\""
  log "Creating initial admin user via npm script 'create-admin'..."
  sudo -u "$RUN_USER" bash -lc "npm run create-admin" >>"$LOG_FILE" 2>&1 || log "create-admin script failed"
else
  log "No create-admin script detected. You may create an admin via Medusa CLI or API later."
fi

log "Medusa setup completed. Check log: $LOG_FILE"