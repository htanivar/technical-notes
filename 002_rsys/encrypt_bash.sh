#!/bin/bash

# List files in the current directory (excluding hidden files and already encrypted files)
files=($(find . -maxdepth 1 -type f ! -name ".*" ! -name "*.enc" -printf "%f\n"))

# Check number of files
if [ ${#files[@]} -gt 10 ]; then
    echo "More than 10 files detected. Please create a dedicated folder for encryption task."
    exit 1
fi

echo "Select a file to encrypt:"
select fname in "${files[@]}"; do
    if [[ -n "$fname" ]]; then
        read -s -p "Enter encryption password: " pass
        echo
        openssl enc -aes-256-cbc -pbkdf2 -md sha256 -salt -in "$fname" -out "$fname.enc" -pass pass:"$pass"
        echo "Encrypted: $fname -> $fname.enc"
        break
    else
        echo "Invalid selection."
    fi
done
