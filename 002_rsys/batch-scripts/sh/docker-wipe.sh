#!/bin/bash

# docker-wipe.sh
# Wipes everything Docker-related EXCEPT volumes
# Also disables BuildKit permanently for stability
# Now compatible with non-systemd systems

set -e

echo "⚠ This will remove:"
echo "  - All containers (running + stopped)"
echo "  - All images"
echo "  - All custom networks"
echo "  - All build cache"
echo "  - All container logs"
echo "  - All dangling Docker data"
echo "  - Disable BuildKit permanently"
echo ""
read -p "Type 'yes' to continue: " confirm

if [ "$confirm" != "yes" ]; then
  echo "Aborted."
  exit 1
fi

# Function to handle Docker service management across different init systems
manage_docker_service() {
  local action=$1

  # Try systemd first
  if command -v systemctl &>/dev/null && systemctl is-active docker &>/dev/null 2>&1; then
    sudo systemctl "$action" docker
  # Try service command
  elif command -v service &>/dev/null; then
    sudo service docker "$action"
  # Try init.d script
  elif [ -f /etc/init.d/docker ]; then
    sudo /etc/init.d/docker "$action"
  # Try rc.d (BSD style)
  elif command -v rc-service &>/dev/null; then
    sudo rc-service docker "$action"
  else
    # If we can't manage the service, just try to stop/start Docker daemon directly
    case "$action" in
      stop)
        sudo pkill docker || true
        sudo pkill dockerd || true
        sleep 2
        ;;
      start|restart)
        sudo dockerd >/dev/null 2>&1 &
        ;;
    esac
  fi
}

# Function to check if Docker is running
is_docker_running() {
  docker info &>/dev/null
  return $?
}

echo "Checking Docker service..."
if ! is_docker_running; then
  echo "Docker is not running. Attempting to start..."
  manage_docker_service start
  sleep 3
fi

echo "Stopping Docker (if running)..."
manage_docker_service stop 2>/dev/null || true
sleep 2

echo "Removing BuildKit cache..."
sudo rm -rf /var/lib/docker/buildkit 2>/dev/null || true

echo "Starting Docker..."
manage_docker_service start 2>/dev/null || {
  echo "Failed to start Docker with service manager, trying direct start..."
  sudo dockerd >/dev/null 2>&1 &
  sleep 3
}

# Wait for Docker to be ready
echo "Waiting for Docker to be ready..."
for i in {1..10}; do
  if is_docker_running; then
    break
  fi
  echo -n "."
  sleep 2
done
echo ""

if ! is_docker_running; then
  echo "Error: Docker failed to start. Please check Docker installation."
  exit 1
fi

echo "Removing all containers..."
docker rm -f $(docker ps -aq) 2>/dev/null || true

echo "Removing all images..."
docker rmi -f $(docker images -aq) 2>/dev/null || true

echo "Removing all custom networks..."
docker network rm $(docker network ls -q | grep -v "bridge\|host\|none") 2>/dev/null || true

echo "Pruning builder cache..."
docker builder prune -a -f || true

echo "Pruning system (excluding volumes)..."
docker system prune -a -f || true

echo "Clearing container logs..."
if [ -d "/var/lib/docker/containers" ]; then
  sudo find /var/lib/docker/containers/ -type f -name "*.log" -exec truncate -s 0 {} \; 2>/dev/null || true
else
  echo "Docker data directory not found at /var/lib/docker, skipping log cleanup"
fi

echo "Disabling BuildKit permanently..."
sudo mkdir -p /etc/docker

# Check if daemon.json exists and merge with existing config
if [ -f /etc/docker/daemon.json ]; then
  # Backup existing config
  sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup
  # Use jq to merge if available, otherwise create new
  if command -v jq &>/dev/null; then
    sudo jq '.features.buildkit = false' /etc/docker/daemon.json > /tmp/daemon.json
    sudo mv /tmp/daemon.json /etc/docker/daemon.json
  else
    echo "Warning: jq not found, overwriting daemon.json (backup created)"
    sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "features": {
    "buildkit": false
  }
}
EOF
  fi
else
  sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "features": {
    "buildkit": false
  }
}
EOF
fi

echo "Restarting Docker to apply changes..."
manage_docker_service restart 2>/dev/null || {
  manage_docker_service stop
  sleep 2
  manage_docker_service start
}

# Final check
if is_docker_running; then
  echo "Docker wipe completed successfully."
  echo "Volumes preserved."
  echo "BuildKit disabled."
else
  echo "Warning: Docker may not be running. Please check manually."
fi