#!/bin/bash

# Ensure ~/.bin is in the PATH
export PATH="$HOME/.bin:$PATH"

# Check and manage Go symbolic link
if [ -L "$HOME/.bin/go" ]; then
  rm "$HOME/.bin/go"
  echo "Existing Go symbolic link deleted."
elif [ -e "$HOME/.bin/go" ]; then
  echo "Error: A regular file exists at ~/.bin/go. Please remove it manually."
  exit 1
fi

# Create a new symbolic link for Go
ln -s /opt/go/bin/go "$HOME/.bin/go"
echo "Go symbolic link created from /opt/go/bin/go."
