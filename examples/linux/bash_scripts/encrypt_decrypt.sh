#!/bin/bash

# Function to encrypt a file
encrypt_file() {
    local input_file="$1"
    local output_file="$2"
    local password="$3"

    # Read the input content
    local content=$(<"$input_file")

    # Encrypt the content with OpenSSL and convert to Base64
    local encrypted_content=$(echo -n "$content" | openssl enc -aes-256-cbc -salt -pass pass:"$password" | base64)

    # Write the encrypted content to the output file
    echo "$encrypted_content" > "$output_file"

    echo "File '$input_file' has been encrypted to '$output_file'."
}

# Function to decrypt a file
decrypt_file() {
    local input_file="$1"
    local output_file="$2"
    local password="$3"

    # Read the encrypted content
    local encrypted_content=$(<"$input_file")

    # Decode from Base64 and decrypt the content with OpenSSL
    local decrypted_content=$(echo -n "$encrypted_content" | base64 -d | openssl enc -d -aes-256-cbc -salt -pass pass:"$password")

    # Write the decrypted content to the output file
    echo "$decrypted_content" > "$output_file"

    echo "File '$input_file' has been decrypted to '$output_file'."
}

# Main script
read -p "Enter the action (en/de): " action
read -p "Enter the file location: " input_file
output_file="${input_file}.enc"

if [[ "$action" == "de" ]]; then
    output_file="${input_file%.enc}"
fi

read -sp "Enter the password: " password
echo

case "$action" in
    en)
        encrypt_file "$input_file" "$output_file" "$password"
        ;;
    de)
        decrypt_file "$input_file" "$output_file" "$password"
        ;;
    *)
        echo "Invalid action. Use 'en' for encrypt or 'de' for decrypt."
        exit 1
        ;;
esac
