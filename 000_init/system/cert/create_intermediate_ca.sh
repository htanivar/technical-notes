#!/bin/bash

# Function to log commands
log_command() {
    echo "$1" >> intermediate_ca_creation_log.txt
}

# Prompt for user input
read -p "Enter the name for your Intermediate CA: " INTERMEDIATE_CA_NAME
read -p "Enter your country (2 letter code): " COUNTRY
read -p "Enter your state or province: " STATE
read -p "Enter your locality: " LOCALITY
read -p "Enter your organization name: " ORGANIZATION
read -p "Enter your organizational unit: " ORGANIZATIONAL_UNIT
read -p "Enter your common name (e.g., Intermediate CA name): " COMMON_NAME
read -p "Enter your email address: " EMAIL
read -p "Enter the path to your Root CA certificate: " ROOT_CA_CERT
read -p "Enter the path to your Root CA private key: " ROOT_CA_KEY

# Create directory structure for Intermediate CA
mkdir -p ~/"${INTERMEDIATE_CA_NAME}"/{certs,crl,newcerts,private}
touch ~/"${INTERMEDIATE_CA_NAME}"/index.txt
echo 1000 > ~/"${INTERMEDIATE_CA_NAME}"/serial

# Generate Intermediate CA Private Key
openssl genpkey -algorithm RSA -out ~/"${INTERMEDIATE_CA_NAME}"/private/intermediate_ca_private_key.pem -aes256
log_command "openssl genpkey -algorithm RSA -out ~/${INTERMEDIATE_CA_NAME}/private/intermediate_ca_private_key.pem -aes256"

# Generate Intermediate CA Certificate Signing Request (CSR)
openssl req -new -key ~/"${INTERMEDIATE_CA_NAME}"/private/intermediate_ca_private_key.pem -out ~/"${INTERMEDIATE_CA_NAME}"/intermediate_ca.csr -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${ORGANIZATIONAL_UNIT}/CN=${COMMON_NAME}/emailAddress=${EMAIL}"
log_command "openssl req -new -key ~/${INTERMEDIATE_CA_NAME}/private/intermediate_ca_private_key.pem -out ~/${INTERMEDIATE_CA_NAME}/intermediate_ca.csr -subj \"/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${ORGANIZATIONAL_UNIT}/CN=${COMMON_NAME}/emailAddress=${EMAIL}\""

# Create Intermediate CA Certificate Signed by Root CA
openssl x509 -req -days 1825 -in ~/"${INTERMEDIATE_CA_NAME}"/intermediate_ca.csr -CA "$ROOT_CA_CERT" -CAkey "$ROOT_CA_KEY" -CAcreateserial -out ~/"${INTERMEDIATE_CA_NAME}"/certs/intermediate_ca_certificate.pem
log_command "openssl x509 -req -days 1825 -in ~/${INTERMEDIATE_CA_NAME}/intermediate_ca.csr -CA $ROOT_CA_CERT -CAkey $ROOT_CA_KEY -CAcreateserial -out ~/${INTERMEDIATE_CA_NAME}/certs/intermediate_ca_certificate.pem"

# Test the Intermediate CA
echo "Testing the Intermediate CA..."
openssl x509 -in ~/"${INTERMEDIATE_CA_NAME}"/certs/intermediate_ca_certificate.pem -text -noout
log_command "openssl x509 -in ~/${INTERMEDIATE_CA_NAME}/certs/intermediate_ca_certificate.pem -text -noout"

echo "Intermediate CA created successfully! Logs saved to intermediate_ca_creation_log.txt."
