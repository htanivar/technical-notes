#!/bin/bash

# Function to log commands
log_command() {
    echo "$1" >> ca_creation_log.txt
}

# Prompt for user input
read -p "Enter the name for your CA: " CA_NAME
read -p "Enter your country (2 letter code): " COUNTRY
read -p "Enter your state or province: " STATE
read -p "Enter your locality: " LOCALITY
read -p "Enter your organization name: " ORGANIZATION
read -p "Enter your organizational unit: " ORGANIZATIONAL_UNIT
read -p "Enter your common name (e.g., CA name): " COMMON_NAME
read -p "Enter your email address: " EMAIL

# Create directory structure
mkdir -p ~/"${CA_NAME}"/{certs,crl,newcerts,private}
touch ~/"${CA_NAME}"/index.txt
echo 1000 > ~/"${CA_NAME}"/serial

# Generate Root CA Private Key
openssl genpkey -algorithm RSA -out ~/"${CA_NAME}"/private/ca_private_key.pem -aes256
log_command "openssl genpkey -algorithm RSA -out ~/${CA_NAME}/private/ca_private_key.pem -aes256"

# Generate Root CA Certificate Signing Request (CSR)
openssl req -new -key ~/"${CA_NAME}"/private/ca_private_key.pem -out ~/"${CA_NAME}"/root_ca.csr -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${ORGANIZATIONAL_UNIT}/CN=${COMMON_NAME}/emailAddress=${EMAIL}"
log_command "openssl req -new -key ~/${CA_NAME}/private/ca_private_key.pem -out ~/${CA_NAME}/root_ca.csr -subj \"/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${ORGANIZATIONAL_UNIT}/CN=${COMMON_NAME}/emailAddress=${EMAIL}\""

# Create Self-Signed Root CA Certificate
openssl x509 -req -days 3650 -in ~/"${CA_NAME}"/root_ca.csr -signkey ~/"${CA_NAME}"/private/ca_private_key.pem -out ~/"${CA_NAME}"/certs/ca_certificate.pem
log_command "openssl x509 -req -days 3650 -in ~/${CA_NAME}/root_ca.csr -signkey ~/${CA_NAME}/private/ca_private_key.pem -out ~/${CA_NAME}/certs/ca_certificate.pem"

# Test the CA
echo "Testing the CA..."
openssl x509 -in ~/"${CA_NAME}"/certs/ca_certificate.pem -text -noout
log_command "openssl x509 -in ~/${CA_NAME}/certs/ca_certificate.pem -text -noout"

echo "CA created successfully! Logs saved to ca_creation_log.txt."
