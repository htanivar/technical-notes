| Command Description                                       | Command Syntax                                                                                                          |
|-----------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------|
| Generate a new key pair and self-signed certificate       | `keytool -genkeypair -alias mykey -keyalg RSA -keysize 2048 -validity 365 -keystore keystore.jks -storepass mypassword` |
| Import a trusted certificate into a trust store           | `keytool -import -trustcacerts -alias myca -file myca.crt -keystore truststore.jks -storepass trustpassword`            |
| List entries in a keystore or trust store                 | `keytool -list -keystore keystore.jks -storepass mypassword`                                                            |
| Export a certificate from a keystore                      | `keytool -export -alias mykey -file mycert.crt -keystore keystore.jks -storepass mypassword`                            |
| Generate a certificate signing request (CSR)              | `keytool -certreq -alias mykey -keyalg RSA -file mycsr.csr -keystore keystore.jks -storepass mypassword`                |
| Import a certificate reply (response) into a keystore     | `keytool -import -alias mykey -file mycert.crt -keystore keystore.jks -storepass mypassword -trustcacerts`              |
| Delete an entry from a keystore or trust store            | `keytool -delete -alias mykey -keystore keystore.jks -storepass mypassword`                                             |
| Change the password of a keystore or trust store          | `keytool -storepasswd -keystore keystore.jks -storepass oldpassword -new newpassword`                                   |
| Export the public key from a keystore or trust store      | `keytool -exportcert -alias mykey -file mykey.crt -keystore keystore.jks -storepass mypassword`                         |
| Import a certificate chain into a keystore or trust store | `keytool -importcert -trustcacerts -alias mykey -file mycertchain.crt -keystore keystore.jks -storepass mypassword`     |
