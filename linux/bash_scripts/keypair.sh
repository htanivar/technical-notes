#!/bin/bash

# Set the key type (RSA is common)
KEY_TYPE="rsa"

# Set the key size (2048 is a common and secure choice)
KEY_SIZE=2048

# Define the filename for the key pair (without extension)
KEY_FILE_NAME=$(pwd)/id

# Generate the key pair with quiet mode (-q) and empty passphrase (-N '')
ssh-keygen -t $KEY_TYPE -b $KEY_SIZE -f $KEY_FILE_NAME -q -N ''

# Check if the key generation was successful
if [ $? -eq 0 ]; then
  echo "Key pair generated successfully!"
else
  echo "Error generating key pair."
fi
