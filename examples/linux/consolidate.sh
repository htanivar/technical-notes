#!/bin/bash

# Input file containing the list of Vault roles
input_file="vault_roles.txt"

# Output file to capture the results
output_file="result.txt"

# Clear the output file if it already exists
> "$output_file"

# Read each line from the input file and execute the command
while IFS= read -r line
do
  # Execute the command and capture the output
  result=$(eval "$line")

  # Append the command and its result to the output file
  echo "Command: $line" >> "$output_file"
  echo "Result:" >> "$output_file"
  echo "$result" >> "$output_file"
  echo "" >> "$output_file"

done < "$input_file"

echo "All commands have been executed and results are stored in $output_file."
