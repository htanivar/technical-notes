#!/bin/bash

# docker-wipe.sh
# Wipes everything Docker-related EXCEPT volumes
# Also disables BuildKit permanently for stability

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

echo "Stopping Docker..."
sudo systemctl stop docker

echo "Removing BuildKit cache..."
sudo rm -rf /var/lib/docker/buildkit 2>/dev/null || true

echo "Starting Docker..."
sudo systemctl start docker

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
sudo find /var/lib/docker/containers/ -type f -name "*.log" -exec truncate -s 0 {} \; 2>/dev/null || true

echo "Disabling BuildKit permanently..."
sudo mkdir -p /etc/docker

sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "features": {
    "buildkit": false
  }
}
EOF

echo "Restarting Docker..."
sudo systemctl restart docker

echo "Docker wipe completed."
echo "Volumes preserved."
echo "BuildKit disabled."