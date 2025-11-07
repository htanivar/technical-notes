#!/bin/bash
# 03_setup_medusa_project_v2.sh - Creates Medusa project, uninstall Admin, migrates, and seeds.

# --- Core Global Variables ---
LOG_FILE=$(cat /tmp/medusa_log_path.txt 2>/dev/null)
MEDUSA_ROOT="/opt/medusa/my-store"
RUN_USER=$(cat /tmp/medusa_run_user.txt 2>/dev/null) # CRITICAL FIX: Read RUN_USER
DB_USER="medusa_user"
DB_PASS="medusa_password"
DB_NAME="medusa_db"
# ... (logging functions) ...

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
DB_ENV_VARS="DATABASE_URL=postgres://$DB_USER:$DB_PASS@localhost/$DB_NAME"
sudo -u "$RUN_USER" bash -c "cat > \"$MEDUSA_ROOT/.env\" <<EOF
# --- Required Database Configuration ---
$DB_ENV_VARS
# --- Server Configuration ---
PORT=9000
# ... (other environment variables) ...
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