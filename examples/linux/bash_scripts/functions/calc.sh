#!/bin/bash

# Function to add two numerical inputs
add_numbers() {
  if [ $# -lt 2 ]; then
    echo "Error: At least two inputs are required."
    return 1  # False (indicates error)
  fi

  local num1="$1"
  local num2="$2"

  # Check if inputs are numerical
  if ! [[ "$num1" =~ ^-?[0-9]+([.][0-9]+)?$ ]] || ! [[ "$num2" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
    echo "Error: Both inputs must be numerical."
    return 1  # False (indicates error)
  fi

  local sum=$(echo "$num1 + $num2" | bc)
  echo "$sum"
  return 0  # True (indicates success)
}
