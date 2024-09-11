#!/bin/bash

# Input and output file paths
input_file="ugly_cert.pem"
output_file="clean_cert.pem"

# Function to reformat the certificate
reformat_certificate() {
  # Remove any existing blank lines and format the certificate into a proper PEM format
  awk '
    BEGIN {in_cert=0; cert=""; }
    /-----BEGIN CERTIFICATE-----/ {in_cert=1; cert=$0; next}
    /-----END CERTIFICATE-----/ {in_cert=0; cert = cert "\n" $0; print cert; cert=""; next}
    {
      if (in_cert) {
        # Remove newlines in the middle of the cert and concatenate base64 data
        gsub(/[ \t\n\r]/, "", $0);
        cert = cert $0
      }
    }
    END {
      if (cert != "") {
        print cert
      }
    }
  ' "$input_file" | fold -w 64 > "$output_file"

  echo "Certificate reformatted and saved to $output_file"
}

# Call the function to reformat the certificate
reformat_certificate
