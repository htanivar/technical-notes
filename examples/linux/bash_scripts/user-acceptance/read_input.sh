#!/bin/bash

# Prompt for user name
read -p "Enter your name: " user_name

# Check if user_name is empty and set default value if necessary
if [ -z "$user_name" ]; then
  user_name="User"
fi

# Display the user name
echo "Hello, $user_name!"
