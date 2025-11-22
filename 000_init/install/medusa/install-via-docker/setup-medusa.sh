#!/bin/bash

# Check if the output of 'id -u' is not equal to 0
if [ "$(id -u)" -ne 0 ]; then
    echo "🚨 This script must be run with root privileges (e.g., using 'sudo')." >&2
    exit 1
fi

# The rest of your script
echo "Root privileges detected. Continuing script execution..."

# --- Default Configuration Variables ---
DEFAULT_DB_NAME="medusa-store"
DEFAULT_DB_USER="postgres"
DEFAULT_DB_PASS="postgres"
DEFAULT_JWT_SECRET="supersecret"
DEFAULT_COOKIE_SECRET="supersecret"
DEFAULT_REDIS_PORT=6379
DEFAULT_DB_PORT=5432
DEFAULT_MEDUSA_PORT=9000

# --- Function Definitions ---

# Function to display colored messages
log() {
    local type=$1
    local message=$2
    local color_code

    case "$type" in
        INFO) color_code='\033[0;32m' ;; # Green
        WARN) color_code='\033[0;33m' ;; # Yellow
        ERROR) color_code='\033[0;31m' ;; # Red
        STEP) color_code='\033[0;36m' ;; # Cyan
        *) color_code='\033[0m' ;;    # Reset
    esac

    echo -e "${color_code}[$(date +'%Y-%m-%d %H:%M:%S')] $type: $message\033[0m"
}

# Function to execute a command and check for errors
exec_cmd() {
    log STEP "Executing: $1"
    eval "$1"
    if [ $? -ne 0 ]; then
        log ERROR "Command failed: $1"
        exit 1
    fi
}

# Function to print usage guide
usage() {
    log INFO "Usage: $0 <ENVIRONMENT_NAME> <MEDUSA_PORT> <DB_PORT>"
    log INFO ""
    log INFO "  <ENVIRONMENT_NAME> : e.g., dev, tst, uat, prd. Used for directory name and container names."
    log INFO "  <MEDUSA_PORT>      : The host port for the Medusa server (e.g., 9001)."
    log INFO "  <DB_PORT>          : The host port for the PostgreSQL database (e.g., 5433)."
    log INFO ""
    log INFO "Example: $0 dev 9001 5433"
    exit 1
}

# --- Script Execution Start ---

# Check for required arguments
if [ "$#" -lt 3 ]; then
    log ERROR "Missing required arguments."
    usage
fi

# --- Parameter Assignment ---
ENV_NAME=$(echo "$1" | tr '[:upper:]' '[:lower:]') # Convert to lowercase for paths/names
MEDUSA_PORT=$2
DB_PORT=$3
PROJECT_DIR="${ENV_NAME}-medusa-store"

# Optional parameters (using defaults if not provided)
DB_USER=${4:-$DEFAULT_DB_USER}
DB_PASS=${5:-$DEFAULT_DB_PASS}
DB_NAME="${ENV_NAME}_${DEFAULT_DB_NAME}" # Parameterize DB name with environment
JWT_SECRET="${ENV_NAME}_${DEFAULT_JWT_SECRET}"
COOKIE_SECRET="${ENV_NAME}_${DEFAULT_COOKIE_SECRET}"

# --- Derived Variables ---
DOCKER_COMPOSE_FILE="docker-compose.yml"
START_SCRIPT="start.sh"
DOCKERFILE_NAME="Dockerfile"
DOCKERIGNORE_FILE=".dockerignore"
ENV_FILE=".env"
PACKAGE_JSON="package.json"
MEDUSA_CONFIG="medusa-config.js"

log INFO "=================================================="
log INFO "🚀 Starting Medusa Environment Setup Script"
log INFO "--------------------------------------------------"
log INFO "Environment Name (ENV_NAME):    $ENV_NAME"
log INFO "Project Directory (PROJECT_DIR): $PROJECT_DIR"
log INFO "Medusa Host Port:               $MEDUSA_PORT"
log INFO "DB Host Port:                   $DB_PORT"
log INFO "DB Name:                        $DB_NAME"
log INFO "=================================================="

## 1. Clone the Medusa starter repository
log STEP "1. Cloning Medusa starter repository into $PROJECT_DIR..."
exec_cmd "git clone https://github.com/medusajs/medusa-starter-default.git --depth=1 $PROJECT_DIR"

## 2. Change into the project directory
log STEP "2. Changing directory to $PROJECT_DIR..."
exec_cmd "cd $PROJECT_DIR"

## 3. Create docker-compose.yml with parameterized ports and names
log STEP "3. Creating $DOCKER_COMPOSE_FILE with parameterized settings..."
cat << EOF > $DOCKER_COMPOSE_FILE
services:
  # PostgreSQL Database
  postgres:
    image: postgres:15-alpine
    container_name: ${ENV_NAME}_medusa_postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: $DB_NAME
      POSTGRES_USER: $DB_USER
      POSTGRES_PASSWORD: $DB_PASS
    ports:
      - "$DB_PORT:$DEFAULT_DB_PORT" # Host Port:Container Port
    volumes:
      - ${ENV_NAME}_postgres_data:/var/lib/postgresql/data
    networks:
      - ${ENV_NAME}_network

  # Redis
  redis:
    image: redis:7-alpine
    container_name: ${ENV_NAME}_medusa_redis
    restart: unless-stopped
    ports:
      - "$DEFAULT_REDIS_PORT:$DEFAULT_REDIS_PORT" # Redis port is usually fixed
    networks:
      - ${ENV_NAME}_network

  # Medusa Server
  medusa:
    build: .
    container_name: ${ENV_NAME}_medusa_backend
    restart: unless-stopped
    depends_on:
      - postgres
      - redis
    ports:
      - "$MEDUSA_PORT:$DEFAULT_MEDUSA_PORT" # Host Port:Container Port
    environment:
      - NODE_ENV=development
      # Internal Docker Compose communication uses service names (postgres, redis)
      - DATABASE_URL=postgres://$DB_USER:$DB_PASS@postgres:$DEFAULT_DB_PORT/$DB_NAME
      - REDIS_URL=redis://redis:$DEFAULT_REDIS_PORT
    env_file:
      - .env
    volumes:
      - .:/server
      - /server/node_modules
    networks:
      - ${ENV_NAME}_network

volumes:
  ${ENV_NAME}_postgres_data:

networks:
  ${ENV_NAME}_network:
    driver: bridge
EOF
log INFO "$DOCKER_COMPOSE_FILE created successfully."

## 4. Create start.sh
log STEP "4. Creating $START_SCRIPT..."
cat << EOF > $START_SCRIPT
#!/bin/sh

# Wait for the database to be ready (a simple check, better checks in production)
echo "Waiting for PostgreSQL to start..."
sleep 5 # Simple wait

# Run migrations and start server
echo "Running database migrations..."
npx medusa db:migrate

echo "Seeding database..."
npm run seed || echo "Seeding failed, continuing..."

echo "Starting Medusa development server..."
npm run dev
EOF
log INFO "$START_SCRIPT created."

## 5. Make start.sh executable
log STEP "5. Making $START_SCRIPT executable..."
exec_cmd "chmod +x $START_SCRIPT"

## 6. Create Dockerfile (no change needed as it's environment-agnostic)
log STEP "6. Creating $DOCKERFILE_NAME..."
cat << EOF > $DOCKERFILE_NAME
# Development Dockerfile for Medusa
FROM node:20-alpine

# Set working directory
WORKDIR /server

# Copy package files and npm config
COPY package.json package-lock.json ./

# Install all dependencies using npm
RUN npm install --legacy-peer-deps

# Copy source code
COPY . .

# Expose the port Medusa runs on
EXPOSE $DEFAULT_MEDUSA_PORT

# Start with migrations and then the development server
CMD ["./start.sh"]
EOF
log INFO "$DOCKERFILE_NAME created."

## 7. Run npm install (Host dependencies)
log STEP "7. Installing host dependencies (required for package.json modification)..."
exec_cmd "npm install --legacy-peer-deps"

## 8. Update package.json to include Docker scripts
log STEP "8. Updating $PACKAGE_JSON with Docker scripts..."
# Temporary modification using sed
if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_INPLACE_OPT='-i ""'
else
    SED_INPLACE_OPT='-i'
fi

# Read package.json content
PKG_CONTENT=$(cat $PACKAGE_JSON)

# Define the new scripts to insert (using 'docker compose' which is the modern command)
NEW_SCRIPTS='"docker:up": "docker compose up --build -d",\n    "docker:down": "docker compose down"'

# Insert the new scripts right after the "scripts": { line
MODIFIED_PKG_CONTENT=$(echo "$PKG_CONTENT" | sed -E '/"scripts": {/a\
    '"$NEW_SCRIPTS"'
')

# Overwrite the package.json file with the modified content
echo "$MODIFIED_PKG_CONTENT" > $PACKAGE_JSON
log INFO "$PACKAGE_JSON updated."

## 9. Update medusa-config.js for Docker
log STEP "9. Updating $MEDUSA_CONFIG for Docker connectivity..."
# Insert the databaseDriverOptions block
sed $SED_INPLACE_OPT '/projectConfig: {/a\
    databaseDriverOptions: {\
      ssl: false,\
      sslmode: "disable",\
    },' $MEDUSA_CONFIG
log INFO "$MEDUSA_CONFIG updated."

## 10. Create .dockerignore
log STEP "10. Creating $DOCKERIGNORE_FILE..."
cat << EOF > $DOCKERIGNORE_FILE
node_modules
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.git
.gitignore
README.md
.env.test
.nyc_output
coverage
.DS_Store
*.log
dist
build
EOF
log INFO "$DOCKERIGNORE_FILE created."

## 11. Create .env file with required variables
log STEP "11. Creating $ENV_FILE with parameterized variables..."
cat << EOF > $ENV_FILE
# General Environment
NODE_ENV=development

# Medusa Application Settings (used for cookie/JWT signing)
JWT_SECRET=$JWT_SECRET
COOKIE_SECRET=$COOKIE_SECRET

# Store URLs
MEDUSA_ADMIN_CORS=http://localhost:7000,http://localhost:7001,http://localhost:7002,http://localhost:7003
MEDUSA_STORE_CORS=http://localhost:8000,http://localhost:8001,http://localhost:8002,http://localhost:8003
MEDUSA_STORE_URL=http://localhost:$MEDUSA_PORT

# Database connection settings (used by the 'medusa' service *inside* docker)
DATABASE_URL=postgres://$DB_USER:$DB_PASS@postgres:$DEFAULT_DB_PORT/$DB_NAME
REDIS_URL=redis://redis:$DEFAULT_REDIS_PORT

# Optional: File Storage (e.g., Minio or S3)
# S3_URL=
# S3_BUCKET=
# S3_REGION=
# S3_ACCESS_KEY_ID=
# S3_SECRET_ACCESS_KEY=

# Optional: Payment Provider (e.g., Stripe)
# STRIPE_API_KEY=
# STRIPE_WEBHOOK_SECRET=
EOF
log INFO "$ENV_FILE created."

log INFO "--------------------------------------------------"
log INFO "✅ Setup complete! The **$ENV_NAME** environment is ready."
log INFO "Project is located at: **./$PROJECT_DIR**"
log INFO "Medusa Backend will run on host port: **$MEDUSA_PORT**"
log INFO "PostgreSQL will run on host port: **$DB_PORT**"
log INFO "--------------------------------------------------"

# --- End of Script ---
