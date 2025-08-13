#!/bin/bash

read -p "Enter container ID or name: " container

# Check if container exists
if ! docker ps -a --format "{{.ID}} {{.Names}}" | grep -qw "$container"; then
    echo "Container '$container' not found."
    exit 1
fi

# Delete container
docker rm -f "$container"
echo "Container '$container' deleted."
