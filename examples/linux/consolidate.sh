#!/bin/bash

# Input file containing the list of Vault roles
input_file="vault_roles.txt"

# Output file to capture the results
output_file="result.txt"

# Check if the input file exists
if [[ ! -f "$input_file" ]]; then
  echo "Input file $input_file not found!"
  exit 1
fi

# Clear the output file if it already exists
> "$output_file"

# Read each line from the input file and execute the command
while IFS= read -r line
do
  # Trim any leading/trailing whitespace
  line=$(echo "$line" | xargs)

  # Check if the line is not empty
  if [[ -n "$line" ]]; then
    echo "Executing: $line"
    # Execute the command and capture the output
    result=$(eval "$line" 2>&1)

    # Log the command output to the console for debugging
    echo "Command output: $result"

    # Append the command and its result to the output file
    echo "Command: $line" >> "$output_file"
    echo "Result:" >> "$output_file"
    echo "$result" >> "$output_file"
    echo "" >> "$output_file"
  else
    echo "Skipping empty line"
  fi
done < "$input_file"

echo "All commands have been executed and results are stored in $output_file."
