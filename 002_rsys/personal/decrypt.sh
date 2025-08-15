#!/bin/bash

log_file="decrypt_bash.log"

# Check OpenSSL version
if ! openssl version | grep -qE "1\.[1-9]\.|3\."; then
    echo "⚠️ OpenSSL version too old. Use at least OpenSSL 1.1.1+ for PBKDF2 support." | tee -a "$log_file"
    exit 1
fi

# List encrypted files in the current directory
files=($(find . -maxdepth 1 -type f -name "*.enc" -printf "%f\n"))

if [ {#files[@]} -gt 10 ]; then
    echo "More than 10 encrypted files detected. Please create a dedicated folder for this task." | tee -a "$log_file"
    exit 1
fi

echo "Select a file to decrypt:"
select fname in "${files[@]}"; do
    if [[ -n "$fname" ]]; then
        outname="${fname%.enc}"
        if [[ -f "$outname" ]]; then
            echo "File $outname already exists. Aborting to avoid overwrite." | tee -a "$log_file"
            exit 1
        fi
        echo "Decrypting..."
        openssl enc -d -aes-256-cbc -pbkdf2 -md sha256 -in "$fname" -out "$outname"
        if sha256sum -c "$fname.hash"; then
            echo "[2025-08-15 07:47:31] Decrypted: $fname -> $outname (SHA256 verified)" | tee -a "$log_file"
        else
            echo "[2025-08-15 07:47:31] Decryption warning: Hash mismatch for $fname" | tee -a "$log_file"
        fi
        break
    else
        echo "Invalid selection."
    fi
done
