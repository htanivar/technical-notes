| Task                     | Command                            | Description                                         |
|--------------------------|------------------------------------|-----------------------------------------------------|
| Generate SSH Key Pair    | `ssh-keygen -t rsa -b 2048`        | Generates a new SSH key pair (RSA, 2048-bit).       |
| Add Public Key to Server | `ssh-copy-id username@remote_host` | Copies the public key to the specified remote host. |
| List Available Keys      | `ssh-add -l`                       | Lists the currently added SSH keys.                 |
| Debug SSH Connection     | `ssh -v username@remote_host`      | Verbose mode to debug SSH connection issues.        |

| Task                                      | Command                                  | Description                                              |
|-------------------------------------------|------------------------------------------|----------------------------------------------------------|
| Generate RSA Key Pair (default)           | `ssh-keygen`                             | Generates a new RSA key pair (2048-bit)                  |
| Generate ECDSA Key Pair                   | `ssh-keygen -t ecdsa -b 256`             | Generates a new ECDSA key pair (256-bit)                 |
| Generate Ed25519 Key Pair                 | `ssh-keygen -t ed25519`                  | Generates a new Ed25519 key pair                         |
| Specify Output File                       | `ssh-keygen -f /path/to/custom_key`      | Generates a key pair and saves it to a custom file       |
| Specify Key Comment                       | `ssh-keygen -C "your_comment"`           | Adds a comment to the key                                |
| Set Key Length (RSA)                      | `ssh-keygen -b 4096`                     | Sets the key length for RSA keys (e.g., 4096 bits)       |
| Specify Key Type and Length Together      | `ssh-keygen -t rsa -b 4096`              | Specifies both key type and length for RSA keys          |
| Generate Key Without a Password           | `ssh-keygen -t rsa -N ""`                | Generates a key without a passphrase                     |
| Change Passphrase for an Existing Key     | `ssh-keygen -p -f /path/to/key`          | Changes the passphrase for an existing private key       |
| Import Key to SSH Agent                   | `ssh-add /path/to/private_key`           | Adds a private key to the SSH agent                      |
| Convert RSA Key to PEM Format             | `ssh-keygen -p -m PEM -f /path/to/key`   | Converts an existing key to PEM format                   |
| Convert RSA Key to PKCS#8 Format          | `ssh-keygen -p -m PKCS8 -f /path/to/key` | Converts an existing key to PKCS#8 format                |
| Extract Public Key from Private Key (RSA) | `ssh-keygen -y -f /path/to/private_key`  | Extracts the public key from an existing private key     |
| Generate Random Art Visual Representation | `ssh-keygen -lv -E md5 -f /path/to/key`  | Displays a visual representation (random art) of the key |

| Task                                  | Command                                     | Description                                                           |
|---------------------------------------|---------------------------------------------|-----------------------------------------------------------------------|
| Add Default SSH Key                   | `ssh-add`                                   | Adds the default SSH key to the SSH agent                             |
| Add Specific Key File                 | `ssh-add /path/to/private_key`              | Adds a specific private key file to the SSH agent                     |
| Add Key with Custom Lifetime          | `ssh-add -t 3600 /path/to/private_key`      | Adds a key with a custom lifetime (e.g., 3600 seconds)                |
| List Added Keys                       | `ssh-add -l`                                | Lists the fingerprints of all keys added to the agent                 |
| Delete All Added Keys                 | `ssh-add -D`                                | Deletes all keys from the agent                                       |
| Delete Specific Key                   | `ssh-add -d /path/to/private_key`           | Deletes a specific key from the agent                                 |
| Run Command with Added Key            | `ssh-add -s /usr/bin/ssh-agent`             | Runs a command with the SSH agent and added keys                      |
| Disable Confirmation Prompts          | `ssh-add -q`                                | Suppresses confirmation prompts when adding or removing keys          |
| Use Specific Authentication Socket    | `ssh-add -s /path/to/authentication_socket` | Specifies a custom authentication socket for the agent                |
| Remove All Identities                 | `ssh-add -e`                                | Removes all identities from the agent                                 |
| Remove All Identities Except One      | `ssh-add -E /path/to/keep/key`              | Removes all identities except the one specified                       |
| Confirm Adding New Keys Automatically | `ssh-add -c`                                | Requests confirmation before adding new keys                          |
| Specify Lifetime for All Future Adds  | `ssh-add -L -t 1800`                        | Specifies a default lifetime for all future adds (e.g., 1800 seconds) |

| Task                                        | Command                                                                       | Description                                                     |
|---------------------------------------------|-------------------------------------------------------------------------------|-----------------------------------------------------------------|
| Connect to Remote Host in Verbose Mode      | `ssh -v username@remote_host`                                                 | Initiates an SSH connection in verbose mode for debugging       |
| Debug SSH Connection with More Verbosity    | `ssh -vv username@remote_host`                                                | Increases verbosity for more detailed debugging                 |
| Debug SSH Connection with Maximum Verbosity | `ssh -vvv username@remote_host`                                               | Maximizes verbosity for extensive debugging                     |
| Check SSH Version on Remote Host            | `ssh -V`                                                                      | Displays the version of the SSH client                          |
| Check SSH Version on Local Machine          | `ssh -V` or `ssh -V 2>&1 \| head -n 1`                                        | Displays the version of the local SSH client                    |
| Check Server Host Key Fingerprint           | `ssh-keygen -F remote_host`                                                   | Checks the server host key fingerprint on the local machine     |
| List Available Key Algorithms               | `ssh -Q key`                                                                  | Lists the available key algorithms supported by the SSH client  |
| Show Details of a Public Key File           | `ssh-keygen -l -f /path/to/public_key`                                        | Displays detailed information about a public key file           |
| Check for SSH Agent Running                 | `ssh-add -L` or `ssh-add -l`                                                  | Lists the fingerprints of all keys added to the SSH agent       |
| Generate Random Art Visual Representation   | `ssh-keygen -lv -E md5 -f /path/to/key`                                       | Displays a visual representation (random art) of the key        |
| Enable Connection Sharing                   | `ssh -o ControlMaster=yes -o ControlPath=~/.ssh/ctl-%r@%h:%p -Nf remote_host` | Enables connection sharing for subsequent connections           |
| Show Connection Information (ControlMaster) | `ssh -O check -S ~/.ssh/ctl-%r@%h:%p remote_host`                             | Shows information about the existing connection (ControlMaster) |
| Terminate Shared Connection (ControlMaster) | `ssh -O exit -S ~/.ssh/ctl-%r@%h:%p remote_host`                              | Terminates the shared connection (ControlMaster)                |

| Task                              | Command                                                                    | Description                                                          |
|-----------------------------------|----------------------------------------------------------------------------|----------------------------------------------------------------------|
| Copy Default Public Key           | `ssh-copy-id username@remote_host`                                         | Copies the default public key to the specified remote host           |
| Copy Specific Public Key          | `ssh-copy-id -i /path/to/public_key username@remote_host`                  | Copies a specific public key to the remote host                      |
| Specify Non-Standard SSH Port     | `ssh-copy-id -p port username@remote_host`                                 | Copies the public key to a remote host using a non-standard SSH port |
| Use Specific SSH Identity File    | `ssh-copy-id -i /path/to/private_key.pub username@remote_host`             | Copies the public key associated with a specific private key         |
| Display Detailed Debugging Output | `ssh-copy-id -v username@remote_host`                                      | Displays detailed debugging information during the copy process      |
| Disable Strict Host Key Checking  | `ssh-copy-id -o StrictHostKeyChecking=no username@remote_host`             | Disables strict host key checking during the copy process            |
| Specify SSH Configuration File    | `ssh-copy-id -F /path/to/ssh_config username@remote_host`                  | Uses a specific SSH configuration file during the copy process       |
| Copy Multiple Keys at Once        | `ssh-copy-id -i /path/to/pubkey1 -i /path/to/pubkey2 username@remote_host` | Copies multiple public keys to the remote host at once               |

| Configuration File Location                    | Default Location       | Brief Description                                                  |
|------------------------------------------------|------------------------|--------------------------------------------------------------------|
| System-wide SSH Config File                    | `/etc/ssh/ssh_config`  | System-wide SSH client configuration file                          |
| Per-User SSH Config File (Global)              | `~/.ssh/config`        | Per-user SSH client configuration file (global)                    |
| Per-User SSH Config File (Local)               | `~/.ssh/ssh_config`    | Per-user SSH client configuration file (local)                     |
| Host-Specific Config within `known_hosts` File | `~/.ssh/known_hosts`   | Configurations for specific hosts stored in the `known_hosts` file |
| System-wide SSHD Config File                   | `/etc/ssh/sshd_config` | System-wide SSH server configuration file                          |
| Per-User SSHD Config File                      | `~/.ssh/sshd_config`   | Per-user SSH server configuration file                             |

