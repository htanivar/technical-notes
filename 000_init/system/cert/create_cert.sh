#!/bin/bash

# Function to log commands
log_command() {
    echo "$1" >> certificate_issue_log.txt
}

# Prompt for user input
read -p "Enter the name for the new certificate: " CERT_NAME
read -p "Enter your country (2 letter code): " COUNTRY
read -p "Enter your state or province: " STATE
read -p "Enter your locality: " LOCALITY
read -p "Enter your organization name: " ORGANIZATION
read -p "Enter your organizational unit: " ORGANIZATIONAL_UNIT
read -p "Enter your common name (e.g., domain name): " COMMON_NAME
read -p "Enter your email address: " EMAIL

# Create a directory for the new certificate
mkdir -p ~/"${CERT_NAME}"

# Generate Entity Private Key
openssl genpkey -algorithm RSA -out ~/"${CERT_NAME}"/private_key.pem -aes256
log_command "openssl genpkey -algorithm RSA -out ~/${CERT_NAME}/private_key.pem -aes256"

# Generate Certificate Signing Request (CSR)
openssl req -new -key ~/"${CERT_NAME}"/private_key.pem -out ~/"${CERT_NAME}"/certificate.csr -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${ORGANIZATIONAL_UNIT}/CN=${COMMON_NAME}/emailAddress=${EMAIL}"
log_command "openssl req -new -key ~/${CERT_NAME}/private_key.pem -out ~/${CERT_NAME}/certificate.csr -subj \"/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${ORGANIZATIONAL_UNIT}/CN=${COMMON_NAME}/emailAddress=${EMAIL}\""

# Sign the CSR with the Intermediate CA
read -p "Enter the path to your Intermediate CA certificate: " INTERMEDIATE_CA_CERT
read -p "Enter the path to your Intermediate CA private key: " INTERMEDIATE_CA_KEY

openssl x509 -req -days 365 -in ~/"${CERT_NAME}"/certificate.csr -CA "$INTERMEDIATE_CA_CERT" -CAkey "$INTERMEDIATE_CA_KEY" -CAcreateserial -out ~/"${CERT_NAME}"/issued_certificate.pem
log_command "openssl x509 -req -days 365 -in ~/${CERT_NAME}/certificate.csr -CA $INTERMEDIATE_CA_CERT -CAkey $INTERMEDIATE_CA_KEY -CAcreateserial -out ~/${CERT_NAME}/issued_certificate.pem"

# Test the issued certificate
echo "Testing the issued certificate..."
openssl x509 -in ~/"${CERT_NAME}"/issued_certificate.pem -text -noout
log_command "openssl x509 -in ~/${CERT_NAME}/issued_certificate.pem -text -noout"

echo "Certificate issued successfully! Logs saved to certificate_issue_log.txt."
