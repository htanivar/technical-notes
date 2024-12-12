#!/bin/bash

# Read user input
read -p "Enter your choice (start, stop, restart): " choice

# Switch case statement
case $choice in
  start)
    echo "Starting the service..."
    # Add commands to start the service
    ;;
  stop)
    echo "Stopping the service..."
    # Add commands to stop the service
    ;;
  restart)
    echo "Restarting the service..."
    # Add commands to restart the service
    ;;
  *)
    echo "Invalid choice. Please enter start, stop, or restart."
    ;;
esac
