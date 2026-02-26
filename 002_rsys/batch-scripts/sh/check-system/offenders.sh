#!/usr/bin/env bash

TARGET="${1:-/}"

echo "Top 10 disk space consumers under: $TARGET"
echo "----------------------------------------"

du -xh --one-file-system "$TARGET" 2>/dev/null \
| sort -rh \
| head -10 \
| awk '{ printf "%-10s %s\n", $1, $2 }'

