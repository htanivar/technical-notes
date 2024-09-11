#!/bin/bash

# Path to your certificate file (with newlines)
input_cert_file="your_cert_file.pem"

# Output file to store the clean, one-line certificate
output_cert_file="clean_cert.txt"

# Read the certificate file and remove newlines, preserving the BEGIN and END lines
clean_cert=$(awk 'NF {sub(/\r/, ""); printf "%s\\n", $0}' "$input_cert_file")

# Output the clean certificate to a file
echo "$clean_cert" > "$output_cert_file"

echo "The certificate has been cleaned and saved to $output_cert_file."
