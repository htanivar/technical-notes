#!/bin/bash

# Function to encrypt a file
encrypt_file() {
    local input_file="$1"
    local output_file="$2"
    local password="$3"

    openssl enc -aes-256-cbc -salt -in "$input_file" -out "$output_file" -k "$password"
    if [[ $? -eq 0 ]]; then
        echo "File '$input_file' has been encrypted to '$output_file'."
    else
        echo "Encryption failed."
    fi
}

# Function to decrypt a file
decrypt_file() {
    local input_file="$1"
    local output_file="$2"
    local password="$3"

    openssl enc -d -aes-256-cbc -in "$input_file" -out "$output_file" -k "$password"
    if [[ $? -eq 0 ]]; then
        echo "File '$input_file' has been decrypted to '$output_file'."
    else
        echo "Decryption failed."
    fi
}

# Main script
read -p "Enter the action (encrypt/decrypt): " action
read -p "Enter the input file location: " input_file
read -p "Enter the output file location: " output_file
read -sp "Enter the password: " password
echo

case "$action" in
    encrypt)
        encrypt_file "$input_file" "$output_file" "$password"
        ;;
    decrypt)
        decrypt_file "$input_file" "$output_file" "$password"
        ;;
    *)
        echo "Invalid action. Use 'encrypt' or 'decrypt'."
        exit 1
        ;;
esac
