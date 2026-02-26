#!/bin/bash

# docker-wipe.sh
# Removes EVERYTHING related to Docker except volumes

set -e

echo "⚠ This will remove:"
echo "  - All containers (running + stopped)"
echo "  - All images"
echo "  - All networks (except default)"
echo "  - All build cache"
echo "  - All container logs"
echo "  - All dangling data"
echo ""
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Aborted."
  exit 1
fi

echo "Stopping Docker..."
sudo systemctl stop docker

echo "Starting Docker..."
sudo systemctl start docker

echo "Removing all containers..."
docker rm -f $(docker ps -aq) 2>/dev/null || true

echo "Removing all images..."
docker rmi -f $(docker images -aq) 2>/dev/null || true

echo "Removing all custom networks..."
docker network rm $(docker network ls -q | grep -v "bridge\|host\|none") 2>/dev/null || true

echo "Pruning build cache..."
docker builder prune -a -f

echo "Pruning system (without volumes)..."
docker system prune -a -f

echo "Clearing container logs..."
sudo find /var/lib/docker/containers/ -type f -name "*.log" -exec truncate -s 0 {} \; 2>/dev/null || true

echo "Removing leftover build cache directory..."
sudo rm -rf /var/lib/docker/buildkit 2>/dev/null || true

echo "Docker wipe completed (volumes preserved)."