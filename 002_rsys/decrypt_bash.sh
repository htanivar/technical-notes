#!/bin/bash

# List encrypted files in the current directory
files=($(find . -maxdepth 1 -type f -name "*.enc" -printf "%f\n"))

# Check number of files
if [ ${#files[@]} -gt 10 ]; then
    echo "More than 10 encrypted files detected. Please create a dedicated folder for decryption task."
    exit 1
fi

echo "Select a file to decrypt:"
select fname in "${files[@]}"; do
    if [[ -n "$fname" ]]; then
        outname="${fname%.enc}"
        read -s -p "Enter decryption password: " pass
        echo
        openssl enc -d -aes-256-cbc -pbkdf2 -md sha256 -in "$fname" -out "$outname" -pass pass:"$pass"
        echo "Decrypted: $fname -> $outname"
        break
    else
        echo "Invalid selection."
    fi
done
