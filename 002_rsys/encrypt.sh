#!/bin/bash

log_file="encrypt_bash.log"

# Check OpenSSL version
if ! openssl version | grep -qE "1\.[1-9]\.|3\."; then
    echo "⚠️ OpenSSL version too old. Use at least OpenSSL 1.1.1+ for PBKDF2 support." | tee -a "$log_file"
    exit 1
fi

# List files in current dir (non-hidden, non-encrypted)
files=($(find . -maxdepth 1 -type f ! -name ".*" ! -name "*.enc" -printf "%f\n"))

if [ {#files[@]} -gt 10 ]; then
    echo "More than 10 files detected. Please create a dedicated folder for this task." | tee -a "$log_file"
    exit 1
fi

echo "Select a file to encrypt:"
select fname in "${files[@]}"; do
    if [[ -n "$fname" ]]; then
        if [[ -f "$fname.enc" ]]; then
            echo "File $fname.enc already exists. Aborting to avoid overwrite." | tee -a "$log_file"
            exit 1
        fi
        echo "Encrypting..."
        openssl enc -aes-256-cbc -pbkdf2 -md sha256 -salt -in "$fname" -out "$fname.enc"
        sha256sum "$fname.enc" > "$fname.enc.hash"
        echo "[2025-08-15 07:47:31] Encrypted: $fname -> $fname.enc" | tee -a "$log_file"
        break
    else
        echo "Invalid selection."
    fi
done
