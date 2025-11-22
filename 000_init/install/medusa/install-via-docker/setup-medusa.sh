#!/bin/bash

# Check if the output of 'id -u' is not equal to 0
if [ "$(id -u)" -ne 0 ]; then
    echo "🚨 This script must be run with root privileges (e.g., using 'sudo')." >&2
    exit 1
fi

# The rest of your script
echo "Root privileges detected. Continuing script execution..."

# --- Default Configuration Variables ---
DEFAULT_JWT_SECRET="$1-supersecret"
DEFAULT_COOKIE_SECRET="$1-supersecret"
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

# Function to load environment variables from file
load_env_file() {
    local env_file="infra/$1/.env"
    
    # Define required variables by application
    declare -A required_vars=(
        ["medusa"]="MEDUSA_PORT MEDUSA_ADMIN MEDUSA_ADMIN_PASSWORD"
        ["database"]="DB_NAME DB_USER DB_PASS DB_PORT"
        ["redis"]="REDIS_PORT"
        # Add more applications here as needed
        # ["new_app"]="VAR1 VAR2 VAR3"
    )
    
    # Source the environment file
    set -a
    source "$env_file"
    set +a
    
    # Validate required variables for each application
    for app in "${!required_vars[@]}"; do
        log STEP "Checking required variables for $app..."
        IFS=' ' read -ra vars <<< "${required_vars[$app]}"
        for var in "${vars[@]}"; do
            if [ -z "${!var}" ]; then
                log ERROR "Required variable '$var' for $app is not set in $env_file"
                exit 1
            else
                log INFO "✅ $app: $var is set"
            fi
        done
    done
}

# Function to print usage guide
usage() {
    log INFO "Usage: $0 <ENVIRONMENT_NAME>"
    log INFO ""
    log INFO "  <ENVIRONMENT_NAME> : e.g., dev, tst, uat, prd. Used for directory name and container names."
    log INFO "                      The script will look for 'infra/<environment>.env' file."
    log INFO ""
    log INFO "Example: $0 dev"
    exit 1
}

# --- Script Execution Start ---

# Check for required arguments
if [ "$#" -lt 1 ]; then
    log ERROR "Missing required arguments."
    usage
fi

# --- Parameter Assignment ---
ENV_NAME=$(echo "$1" | tr '[:upper:]' '[:lower:]') # Convert to lowercase for paths/names
PROJECT_DIR="${ENV_NAME}-medusa-store"

# Create infra directory if it doesn't exist
if [ ! -d "infra" ]; then
    log STEP "Creating infra directory for environment files..."
    exec_cmd "mkdir -p infra"
fi

# Check if environment file exists, if not create a template
ENV_FILE_PATH="infra/${ENV_NAME}/.env"
if [ ! -f "$ENV_FILE_PATH" ]; then
    log WARN "Environment file '$ENV_FILE_PATH' not found. Creating a template..."
    cat << EOF > "$ENV_FILE_PATH"
# Medusa Environment Configuration for ${ENV_NAME}
# Required Variables
MEDUSA_PORT=9000
MEDUSA_ADMIN=admin@example.com
MEDUSA_ADMIN_PASSWORD=supersecret
DB_PORT=5432
REDIS_PORT=6379

# Optional: Override defaults
# DB_USER=postgres
# DB_PASS=postgres
# DB_NAME=${ENV_NAME}_medusa-store
# JWT_SECRET=${ENV_NAME}_supersecret
# COOKIE_SECRET=${ENV_NAME}_supersecret
EOF
    log INFO "Created template environment file at '$ENV_FILE_PATH'"
    log INFO "Please edit this file to set appropriate values before running the script again."
    exit 1
fi

# Load environment variables from file
log STEP "Loading environment configuration from $ENV_FILE_PATH..."
load_env_file "$ENV_NAME"

# Set variables with defaults if not provided in the environment file
JWT_SECRET=${JWT_SECRET:-"${ENV_NAME}_${DEFAULT_JWT_SECRET}"}
COOKIE_SECRET=${COOKIE_SECRET:-"${ENV_NAME}_${DEFAULT_COOKIE_SECRET}"}
MEDUSA_PORT=${MEDUSA_PORT}
DB_PORT=${DB_PORT}

# Check for environment-specific configuration files
ENV_PACKAGE_JSON="infra/${ENV_NAME}/package.json"
ENV_MEDUSA_CONFIG="infra/${ENV_NAME}/medusa-config.ts"

if [ ! -f "$ENV_PACKAGE_JSON" ]; then
    log ERROR "Environment-specific package.json not found at: $ENV_PACKAGE_JSON"
    log INFO "Please create this file with the appropriate configuration for the $ENV_NAME environment"
    exit 1
fi

if [ ! -f "$ENV_MEDUSA_CONFIG" ]; then
    log ERROR "Environment-specific medusa-config.ts not found at: $ENV_MEDUSA_CONFIG"
    log INFO "Please create this file with the appropriate configuration for the $ENV_NAME environment"
    exit 1
fi

log INFO "✅ Found all required environment-specific configuration files"

# --- Derived Variables ---
DOCKER_COMPOSE_FILE="docker-compose.yml"
START_SCRIPT="start.sh"
DOCKERFILE_NAME="Dockerfile"
DOCKERIGNORE_FILE=".dockerignore"
ENV_FILE=".env"
PACKAGE_JSON="package.json"
MEDUSA_CONFIG="medusa-config.ts"

log INFO "=================================================="
log INFO "🚀 Starting Medusa Environment Setup Script"
log INFO "--------------------------------------------------"
log INFO "Environment Name (ENV_NAME):    $ENV_NAME"
log INFO "Project Directory (PROJECT_DIR): $PROJECT_DIR"
log INFO "Medusa Host Port:               $MEDUSA_PORT"
log INFO "DB Host Port:                   $DB_PORT"
log INFO "DB Name:                        $DB_NAME"
log INFO "DB User:                        $DB_USER"
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

## 8. Copy environment-specific package.json
log STEP "8. Copying environment-specific package.json..."
exec_cmd "cp ../$ENV_PACKAGE_JSON $PACKAGE_JSON"
log INFO "$PACKAGE_JSON copied from ../$ENV_PACKAGE_JSON"

## 9. Copy environment-specific medusa-config.ts
log STEP "9. Copying environment-specific medusa-config.ts..."
exec_cmd "cp ../$ENV_MEDUSA_CONFIG $MEDUSA_CONFIG"
log INFO "$MEDUSA_CONFIG updated from ../$ENV_MEDUSA_CONFIG"

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
