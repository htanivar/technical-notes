#!/bin/bash

# Input and output file paths
input_file="input_file.txt"
output_file="output_file.txt"

# Replace literal '\n' with actual newlines and save to a new file
sed 's/\\n/\n/g' "$input_file" > "$output_file"

echo "Replaced \n with newlines. Output saved to $output_file."
