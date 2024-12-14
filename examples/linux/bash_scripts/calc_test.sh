#!/bin/bash

# Source the math functions
source /home/ravi/code/technical-notes/examples/linux/bash_scripts/functions/calc.sh

# Function to prompt for input and add the numbers
prompt_and_add() {
  read -p "Enter the first number: " num1
  read -p "Enter the second number: " num2

  result=$(add_numbers "$num1" "$num2")
  if [ $? -eq 0 ]; then
    echo "The sum of $num1 and $num2 is: $result"
  else
    echo "Failed to add the numbers."
  fi
}

# Call the function to prompt for input and add the numbers
prompt_and_add
