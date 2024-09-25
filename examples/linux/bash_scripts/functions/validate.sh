#!/bin/bash

# Function to check if a variable is empty
must_be_empty() {
  #  variable exists only within the function
  #  $1 first param after the function call
  local var="$1"
  if [ -z "$var" ]; then
    echo "The variable is empty."
    return 0
  else
    echo "The variable is not empty."
    return 1
  fi
}

# Function to check if a variable is null (unset)
must_be_null() {
  #  variable exists only within the function
  #  $1 first param after the function call
  local var_name="$1"
  if [ -z "${!var_name+x}" ]; then
    echo "The variable is null (unset)."
    return 0
  else
    echo "The variable is set."
    return 1
  fi
}

# Function to check if a variable is empty
is_empty() {
#  variable exists only within the function
#  $1 first param after the function call
  local var="$1"
  if [ -z "$var" ]; then
    return 0  # True (empty)
  else
    return 1  # False (not empty)
  fi
}

# Function to check if a variable is null (unset)
is_null() {
  #  variable exists only within the function
  #  $1 first param after the function call
  local var_name="$1"
  if [ -z "${!var_name+x}" ]; then
    return 0  # True (null/unset)
  else
    return 1  # False (set)
  fi
}

must_be_number() {
  local input="$1"
  if [[ "$input" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
    return
    else
    echo "Input '$1' is NOT a number."
  fi
}

is_number() {
  local input="$1"
  if [[ "$input" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
    echo "yes input is number"
    return 0  # True (is a number)
  else
    echo "no input is NOT number"
    return 1  # False (not a number)
  fi
}