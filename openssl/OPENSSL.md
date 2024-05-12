| Feature                                                                                 | Description                                                                                                                |
|-----------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------|
| [Symmetric Encryption](#symmetric-encryption)                                           | OpenSSL supports symmetric encryption algorithms like AES, DES, and RC4.                                                   |
| [Asymmetric Encryption](#asymmetric-encryption)                                         | It supports asymmetric encryption using RSA, DSA, and ECDSA.                                                               |
| [Digital Signatures](#digital-signatures)                                               | OpenSSL can generate and verify digital signatures using various algorithms like RSA, DSA, and ECDSA.                      |
| [Hashing Functions](#hashing-functions)                                                 | It provides hash functions like MD5, SHA-1, SHA-256, SHA-384, and SHA-512.                                                 |
| [Certificate Management](#certificate-management)                                       | OpenSSL can generate, sign, and manage X.509 certificates, including certificate signing requests (CSRs).                  |                                                                                                       
| [TLS/SSL Protocols](#tls-ssl-protocols)                                                 | It supports SSL/TLS protocols for secure communication over networks.                                                      |
| [Random Number Generation](#random-number-generation)                                   | OpenSSL includes a random number generator for cryptographic purposes.                                                     |
| [Public Key Infrastructure (PKI) Operations](#public-key-infrastructure-pki-operations) | It supports operations related to PKI, including key generation, certificate revocation, and certificate chain validation. |                                                                                                       |
| [Cipher Suites](#cipher-suites)                                                         | OpenSSL supports a variety of cipher suites for SSL/TLS connections.                                                       |
| [Diffie-Hellman Key Exchange](#diffie-hellman-key-exchange)                             | It provides support for Diffie-Hellman key exchange for secure key agreement.                                              |
| [Message Digests](#message-digests)                                                     | OpenSSL can compute message digests using hash functions.                                                                  |
| [Certificate Revocation Lists (CRLs)](#certificate-revocation-lists)                    | It can handle certificate revocation lists for managing revoked certificates in                                            |
| [Elliptic Curve Cryptography (ECC)](#elliptic-curve-cryptography)                       | OpenSSL supports ECC algorithms for both encryption and digital signatures.                                                |
| [Secure Socket Layer (SSL) Testing](#secure-socket-layer-testing)                       | OpenSSL includes tools for testing SSL/TLS connections and certificates.                                                   |

## symmetric-encryption

**Symmetric Encryption**

    1. aes-256-cbc = Advanced Encryption Standard (aes) 256-bit key size Cipher Block Chaining (cbc)

| Command Purpose                                   | Command                                                                                    |
|---------------------------------------------------|--------------------------------------------------------------------------------------------|
| Encrypt a file using AES-256-CBC                  | `openssl enc -aes-256-cbc -salt -in plaintext.txt -out encrypted.enc`                      |
| Decrypt an AES-256-CBC encrypted file             | `openssl enc -d -aes-256-cbc -in encrypted.enc -out decrypted.txt`                         |
| Encrypt a file using CAST5 algorithm              | `gpg -c --cipher-algo CAST5 file.txt`                                                      |
| Decrypt a CAST5 encrypted file                    | `gpg -d file.txt.gpg > decrypted.txt`                                                      |
| Encrypt a file using DES algorithm                | `mcrypt --keygen --list \| grep des`<br>`mcrypt -k des -a des file.txt`                    |
| Decrypt a DES encrypted file                      | `mcrypt -d -k des -a des file.txt.nc`                                                      |
| Encrypt a file using AES-256 algorithm            | `7z a -p -mhe=on -t7z archive.7z file.txt`                                                 |
| Decrypt an AES-256 encrypted archive              | `7z x archive.7z`                                                                          |
| Encrypt text using AES-256-CBC algorithm          | `echo -n "Secret Message" \| openssl enc -aes-256-cbc -a -salt -pass pass:yourpassword`    |
| Decrypt text encrypted with AES-256-CBC algorithm | `echo -n "Encrypted Text" \| openssl enc -d -aes-256-cbc -a -salt -pass pass:yourpassword` |

## asymmetric-encryption

**Asymmetric Encryption**

| Command Purpose                               | Command                                                                                           |
|-----------------------------------------------|---------------------------------------------------------------------------------------------------|
| Generate an RSA key pair                      | `openssl genpkey -algorithm RSA -out private_key.pem`                                             |
| Encrypt a file using RSA public key           | `openssl rsautl -encrypt -in plaintext.txt -inkey public_key.pem -pubin -out encrypted.txt`       |
| Decrypt a file using RSA private key          | `openssl rsautl -decrypt -in encrypted.txt -inkey private_key.pem -out decrypted.txt`             |
| Generate an RSA key pair with 4096 bits       | `openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:4096`               |
| Encrypt a file using RSA-OAEP algorithm       | `openssl rsautl -encrypt -oaep -in plaintext.txt -inkey public_key.pem -pubin -out encrypted.txt` |
| Generate an ECDSA key pair (Prime256v1 Curve) | `openssl ecparam -genkey -name prime256v1 -out private_key.pem`                                   |
| Sign a file using ECDSA private key           | `openssl dgst -sha256 -sign private_key.pem -out signature.txt file_to_sign.txt`                  |
| Verify ECDSA signature with public key        | `openssl dgst -sha256 -verify public_key.pem -signature signature.txt file_to_sign.txt`           |
| Generate an ED25519 key pair                  | `openssl genpkey -algorithm ED25519 -out private_key.pem`                                         |
| Encrypt a file using ED25519 public key       | `openssl pkeyutl -encrypt -in plaintext.txt -inkey public_key.pem -pubin -out encrypted.txt`      |
| Decrypt a file using ED25519 private key      | `openssl pkeyutl -decrypt -in encrypted.txt -inkey private_key.pem -out decrypted.txt`            |

## digital-signatures

**Digital Signatures**

| Command Purpose                            | Command                                                                                   |
|--------------------------------------------|-------------------------------------------------------------------------------------------|
| Generate SHA-256 Hash of File              | `openssl dgst -sha256 -out hash.txt file_to_sign.txt`                                     |
| Sign SHA-256 Hash with RSA Private Key     | `openssl rsautl -sign -inkey private_key.pem -in hash.txt -out signature.bin`             |
| Sign SHA-256 Hash with ECDSA Private Key   | `openssl dgst -sha256 -sign private_key.pem -out signature.bin hash.txt`                  |
| Sign SHA-256 Hash with ED25519 Private Key | `openssl dgst -sha256 -sign private_key.pem -out signature.bin hash.txt`                  |
| Verify RSA Signature with Public Key       | `openssl rsautl -verify -pubin -inkey public_key.pem -in signature.bin -out verified.txt` |
| Verify ECDSA Signature with Public Key     | `openssl dgst -sha256 -verify public_key.pem -signature signature.bin hash.txt`           |
| Verify ED25519 Signature with Public Key   | `openssl dgst -sha256 -verify public_key.pem -signature signature.bin hash.txt`           |

## hashing-functions

**Hashing Functions**

| Command Purpose                                  | Command                                                                                  |
|--------------------------------------------------|------------------------------------------------------------------------------------------|
| Generate MD5 Hash of a File                      | `openssl md5 -out hash.md5 file_to_hash.txt`                                             |
| Generate SHA-1 Hash of a File                    | `openssl sha1 -out hash.sha1 file_to_hash.txt`                                           |
| Generate SHA-256 Hash of a File                  | `openssl sha256 -out hash.sha256 file_to_hash.txt`                                       |
| Generate SHA-512 Hash of a File                  | `openssl sha512 -out hash.sha512 file_to_hash.txt`                                       |
| Generate MD5 Hash of a String                    | `echo -n "String to hash" \| openssl md5`                                                |
| Generate SHA-1 Hash of a String                  | `echo -n "String to hash" \| openssl sha1`                                               |
| Generate SHA-256 Hash of a String                | `echo -n "String to hash" \| openssl sha256`                                             |
| Generate SHA-512 Hash of a String                | `echo -n "String to hash" \| openssl sha512`                                             |
| Generate HMAC-MD5 Hash of a String with a Key    | `echo -n "String to hash" \| openssl dgst -md5 -hmac "Key" -binary \| openssl base64`    |
| Generate HMAC-SHA1 Hash of a String with a Key   | `echo -n "String to hash" \| openssl dgst -sha1 -hmac "Key" -binary \| openssl base64`   |
| Generate HMAC-SHA256 Hash of a String with a Key | `echo -n "String to hash" \| openssl dgst -sha256 -hmac "Key" -binary \| openssl base64` |
| Generate HMAC-SHA512 Hash of a String with a Key | `echo -n "String to hash" \| openssl dgst -sha512 -hmac "Key" -binary \| openssl base64` |

## certificate-management

**Certificate Management**

| Command Purpose                                                              | Command                                                                                                         |
|------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------|
| Generate a new private key and a certificate signing request (CSR)           | `openssl req -newkey rsa:2048 -keyout private_key.pem -out csr.pem -subj "/CN=YourDomain"`                      |
| Generate a new self-signed certificate                                       | `openssl req -new -x509 -key private_key.pem -out self_signed_cert.pem -days 365 -subj "/CN=YourDomain"`        |
| View the contents of a certificate file                                      | `openssl x509 -in cert.pem -text -noout`                                                                        |
| Verify a certificate against a CA certificate chain                          | `openssl verify -CAfile ca_chain.pem cert_to_verify.pem`                                                        |
| Convert a certificate from PEM format to DER format                          | `openssl x509 -outform der -in cert.pem -out cert.der`                                                          |
| Convert a certificate from DER format to PEM format                          | `openssl x509 -inform der -in cert.der -out cert.pem`                                                           |
| Generate a new private key and a self-signed certificate in a single command | `openssl req -newkey rsa:2048 -nodes -keyout key.pem -x509 -days 365 -out cert.pem -subj "/CN=YourDomain"`      |
| Export a private key from a PKCS#12 (PFX/P12) file                           | `openssl pkcs12 -in certificate.pfx -nocerts -out private_key.pem`                                              |
| Export a certificate and private key from a PKCS#12 (PFX/P12) file           | `openssl pkcs12 -in certificate.pfx -out certificate.pem -nodes`                                                |
| Create a PKCS#12 (PFX/P12) file containing a certificate and private key     | `openssl pkcs12 -export -out certificate.pfx -inkey private_key.pem -in certificate.pem -certfile ca_chain.pem` |

## tls-ssl-protocols

**TLS-SSL Protocols**

| Command Purpose                                                            | Command                                                                                                         |
|----------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------|
| Test SSL/TLS connection to a server                                        | `openssl s_client -connect hostname:port`                                                                       |
| Show SSL/TLS certificate information                                       | `openssl s_client -connect hostname:port -showcerts`                                                            |
| Generate a self-signed SSL/TLS certificate                                 | `openssl req -newkey rsa:2048 -nodes -keyout key.pem -x509 -days 365 -out cert.pem`                             |
| Create a PKCS#12 (PFX/P12) file containing a certificate and private key   | `openssl pkcs12 -export -out certificate.pfx -inkey private_key.pem -in certificate.pem -certfile ca_chain.pem` |
| Convert a PEM-formatted SSL/TLS certificate to DER format                  | `openssl x509 -outform der -in cert.pem -out cert.der`                                                          |
| Convert a DER-formatted SSL/TLS certificate to PEM format                  | `openssl x509 -inform der -in cert.der -out cert.pem`                                                           |
| Verify a certificate against a CA certificate chain                        | `openssl verify -CAfile ca_chain.pem cert_to_verify.pem`                                                        |
| Check if a private key matches a SSL/TLS certificate                       | `openssl x509 -noout -modulus -in certificate.pem                                                               | openssl md5`                                                 |
| Show supported TLS/SSL protocols and ciphers                               | `openssl ciphers -v`                                                                                            |
| Test SSL/TLS connection using a specific protocol version and cipher suite | `openssl s_client -connect hostname:port -tls1_2 -cipher ECDHE-RSA-AES256-GCM-SHA384`                           |
| Convert a certificate and private key from PKCS#12 (PFX/P12) to PEM format | `openssl pkcs12 -in certificate.pfx -out certificate.pem -nodes`                                                |

## random-number-generation

**Random Number Generation**

| Command Purpose                                | Command                                                                                                                              |
|------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------|
| Generate a random number using OpenSSL         | `openssl rand -hex 32`                                                                                                               |
| Generate a random password of specified length | `openssl rand -base64 12`                                                                                                            |
| Generate a random number using /dev/urandom    | `cat /dev/urandom \| tr -dc 'a-zA-Z0-9' \| fold -w 32 \| head -n 1`                                                                  |
| Generate a random number using Python          | `python -c "import random; print(''.join(random.SystemRandom().choice('abcdefghijklmnopqrstuvwxyz0123456789') for _ in range(32)))"` |
| Generate a random number using Ruby            | `ruby -e "puts ('a'..'z').to_a.shuffle[0,32].join"`                                                                                  |
| Generate a random number using Perl            | `perl -le 'print map { ("a".."z", 0..9)[rand 36] } 0..31'`                                                                           |
| Generate a random number using PHP             | `php -r 'echo substr(str_shuffle("abcdefghijklmnopqrstuvwxyz0123456789"), 0, 32);'`                                                  |
| Generate a random number using Node.js         | `node -e "console.log(require('crypto').randomBytes(16).toString('hex'))"`                                                           |

## public-key-infrastructure-pki-operations

**Public Key Infrastructure (PKI) Operations**

| Command Purpose                                                          | Command                                                                                                         |
|--------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------|
| Generate a new private key and a certificate signing request (CSR)       | `openssl req -newkey rsa:2048 -keyout private_key.pem -out csr.pem -subj "/CN=YourDomain"`                      |
| Generate a new self-signed certificate                                   | `openssl req -new -x509 -key private_key.pem -out self_signed_cert.pem -days 365 -subj "/CN=YourDomain"`        |
| View the contents of a certificate file                                  | `openssl x509 -in cert.pem -text -noout`                                                                        |
| Verify a certificate against a CA certificate chain                      | `openssl verify -CAfile ca_chain.pem cert_to_verify.pem`                                                        |
| Convert a certificate from PEM format to DER format                      | `openssl x509 -outform der -in cert.pem -out cert.der`                                                          |
| Convert a certificate from DER format to PEM format                      | `openssl x509 -inform der -in cert.der -out cert.pem`                                                           |
| Export a private key from a PKCS#12 (PFX/P12) file                       | `openssl pkcs12 -in certificate.pfx -nocerts -out private_key.pem`                                              |
| Export a certificate and private key from a PKCS#12 (PFX/P12) file       | `openssl pkcs12 -in certificate.pfx -out certificate.pem -nodes`                                                |
| Create a PKCS#12 (PFX/P12) file containing a certificate and private key | `openssl pkcs12 -export -out certificate.pfx -inkey private_key.pem -in certificate.pem -certfile ca_chain.pem` |
| Check if a private key matches a certificate                             | `openssl x509 -noout -modulus -in certificate.pem                                                               | openssl md5`                                            |

## cipher-suites

**Cipher Suites**

| Command Purpose                                                            | Command                                                                               |
|----------------------------------------------------------------------------|---------------------------------------------------------------------------------------|
| Show supported TLS/SSL protocols and ciphers                               | `openssl ciphers -v`                                                                  |
| Test SSL/TLS connection using a specific cipher suite                      | `openssl s_client -connect hostname:port -cipher ECDHE-RSA-AES256-GCM-SHA384`         |
| Show available SSL/TLS cipher suites on a server                           | `openssl s_client -connect hostname:port -cipher NULL,DEFAULT`                        |
| Test SSL/TLS connection using a specific protocol version and cipher suite | `openssl s_client -connect hostname:port -tls1_2 -cipher ECDHE-RSA-AES256-GCM-SHA384` |
| Show cipher suites supported by a specific OpenSSL version                 | `openssl ciphers -v 'ALL:eNULL'`                                                      |
| Show supported cipher suites by OpenSSL for a specific SSL/TLS version     | `openssl ciphers -v 'TLSv1.2'`                                                        |

## diffie-hellman-key-exchange

**Diffie-Hellman Key Exchange**

| Command Purpose                                                                        | Command                                                                                                                     |
|----------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| Generate a new Diffie-Hellman parameters file                                          | `openssl dhparam -out dhparam.pem 2048`                                                                                     |
| Generate a new private key and a certificate signing request (CSR) using DH parameters | `openssl req -new -keyout private_key.pem -out csr.pem -subj "/CN=YourDomain" -config dhparam.cnf`                          |
| Generate a new self-signed certificate using DH parameters                             | `openssl req -new -x509 -key private_key.pem -out self_signed_cert.pem -days 365 -config dhparam.cnf`                       |
| Show the parameters of a Diffie-Hellman parameters file                                | `openssl dhparam -in dhparam.pem -text -noout`                                                                              |
| Generate a new private key and a DH parameters file in a single command                | `openssl req -new -keyout private_key.pem -out csr.pem -subj "/CN=YourDomain" -config <(openssl dhparam -outform PEM 2048)` |

## message-digests

**Message Digests**

| Command Purpose                                  | Command                                                                                  |
|--------------------------------------------------|------------------------------------------------------------------------------------------|
| Generate MD5 Hash of a File                      | `openssl md5 -out hash.md5 file_to_hash.txt`                                             |
| Generate SHA-1 Hash of a File                    | `openssl sha1 -out hash.sha1 file_to_hash.txt`                                           |
| Generate SHA-256 Hash of a File                  | `openssl sha256 -out hash.sha256 file_to_hash.txt`                                       |
| Generate SHA-512 Hash of a File                  | `openssl sha512 -out hash.sha512 file_to_hash.txt`                                       |
| Generate MD5 Hash of a String                    | `echo -n "String to hash" \| openssl md5`                                                |
| Generate SHA-1 Hash of a String                  | `echo -n "String to hash" \| openssl sha1`                                               |
| Generate SHA-256 Hash of a String                | `echo -n "String to hash" \| openssl sha256`                                             |
| Generate SHA-512 Hash of a String                | `echo -n "String to hash" \| openssl sha512`                                             |
| Generate HMAC-MD5 Hash of a String with a Key    | `echo -n "String to hash" \| openssl dgst -md5 -hmac "Key" -binary \| openssl base64`    |
| Generate HMAC-SHA1 Hash of a String with a Key   | `echo -n "String to hash" \| openssl dgst -sha1 -hmac "Key" -binary \| openssl base64`   |
| Generate HMAC-SHA256 Hash of a String with a Key | `echo -n "String to hash" \| openssl dgst -sha256 -hmac "Key" -binary \| openssl base64` |
| Generate HMAC-SHA512 Hash of a String with a Key | `echo -n "String to hash" \| openssl dgst -sha512 -hmac "Key" -binary \| openssl base64` |

##certificate-revocation-lists

**Certificate Revocation Lists (CRLs)**

| Command Purpose                                  | Command                                                                                             |
|--------------------------------------------------|-----------------------------------------------------------------------------------------------------|
| Generate a new Certificate Revocation List (CRL) | `openssl ca -gencrl -keyfile ca_key.pem -cert ca_cert.pem -out crl.pem -config ca_config.cnf`       |
| Display the contents of a CRL                    | `openssl crl -in crl.pem -text -noout`                                                              |
| Verify a certificate against a CRL               | `openssl verify -crl_check -CAfile ca_cert.pem -crl_file crl.pem cert_to_verify.pem`                |
| Revoke a certificate in a CRL                    | `openssl ca -revoke cert_to_revoke.pem -keyfile ca_key.pem -cert ca_cert.pem -config ca_config.cnf` |
| Update a CRL file with revoked certificates      | `openssl ca -gencrl -keyfile ca_key.pem -cert ca_cert.pem -out crl.pem -config ca_config.cnf`       |

## elliptic-curve-cryptography

**Elliptic Curve Cryptography (ECC)**

| Command Purpose                                  | Command                                                                                             |
|--------------------------------------------------|-----------------------------------------------------------------------------------------------------|
| Generate a new Certificate Revocation List (CRL) | `openssl ca -gencrl -keyfile ca_key.pem -cert ca_cert.pem -out crl.pem -config ca_config.cnf`       |
| Display the contents of a CRL                    | `openssl crl -in crl.pem -text -noout`                                                              |
| Verify a certificate against a CRL               | `openssl verify -crl_check -CAfile ca_cert.pem -crl_file crl.pem cert_to_verify.pem`                |
| Revoke a certificate in a CRL                    | `openssl ca -revoke cert_to_revoke.pem -keyfile ca_key.pem -cert ca_cert.pem -config ca_config.cnf` |
| Update a CRL file with revoked certificates      | `openssl ca -gencrl -keyfile ca_key.pem -cert ca_cert.pem -out crl.pem -config ca_config.cnf`       |

## secure-socket-layer-testing

**Secure Socket Layer (SSL) Testing**

| Command Purpose                                                            | Command                                                                               |
|----------------------------------------------------------------------------|---------------------------------------------------------------------------------------|
| Test SSL/TLS connection to a server                                        | `openssl s_client -connect hostname:port`                                             |
| Show SSL/TLS certificate information                                       | `openssl s_client -connect hostname:port -showcerts`                                  |
| Test SSL/TLS connection using a specific protocol version and cipher suite | `openssl s_client -connect hostname:port -tls1_2 -cipher ECDHE-RSA-AES256-GCM-SHA384` |
| Show available SSL/TLS cipher suites on a server                           | `openssl s_client -connect hostname:port -cipher NULL,DEFAULT`                        |
| Check if a private key matches a SSL/TLS certificate                       | `openssl x509 -noout -modulus -in certificate.pem \| openssl md5`                     |
| View the parameters of a Diffie-Hellman parameters file                    | `openssl dhparam -in dhparam.pem -text -noout`                                        |
| Show supported TLS/SSL protocols and ciphers                               | `openssl ciphers -v`                                                                  |
| Show available SSL/TLS cipher suites on a server                           | `openssl s_client -connect hostname:port -cipher NULL,DEFAULT`                        |

