#!/bin/bash

containers=$(docker ps -aq)

if [ -z "$containers" ]; then
    echo "No containers to delete."
    exit 0
fi

echo "Deleting all containers..."
docker rm -f $containers
echo "All containers deleted."
