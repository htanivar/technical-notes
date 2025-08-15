#!/bin/bash

# Check if a project name is provided as the first parameter
if [ -z "$1" ]; then
  echo "Error: Please provide a project name as the first parameter."
  exit 1
fi

# Install Angular CLI globally (if not already installed)
if ! command -v ng &> /dev/null; then
  echo "Installing Angular CLI..."
  npm install -g @angular/cli
fi

# Create a new Angular project using Angular CLI
echo "Creating new Angular project '$1'..."
ng new "$1"

# Navigate to the project directory
cd "$1" || exit 1

echo "Angular project '$1' setup completed successfully."
