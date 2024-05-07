| User Commands                       | Admin Commands |
|-------------------------------------|----------------|
| [CONFIG Commands](#config-commands) | -              |

## config-commands

**CONFIG Commands**

| Step                                 | Command                                                                                                            | Description                                                                                    |
|--------------------------------------|--------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|
| Install AWS CLI                      | `curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg" && sudo installer -pkg AWSCLIV2.pkg -target /` | Install AWS CLI on macOS (replace with appropriate command for your OS)                        |
| Configure AWS CLI                    | `aws configure`                                                                                                    | Configure AWS CLI with AWS Access Key ID, Secret Access Key, default region, and output format |
| Verify Configuration                 | `aws sts get-caller-identity`                                                                                      | Verify AWS CLI configuration and display caller identity                                       |
| Use Profiles (Optional)              | `aws configure --profile myprofile`                                                                                | Create a named profile or edit existing profile in AWS CLI                                     |
| Set Environment Variables (Optional) | `export AWS_ACCESS_KEY_ID=your_access_key`                                                                         | Set AWS CLI environment variables for credentials                                              |
| Update Configuration                 | `aws configure`                                                                                                    | Update AWS CLI configuration with new credentials or settings                                  |
| Switch Profiles (Optional)           | `aws s3 ls --profile myprofile`                                                                                    | Use a specific profile when running AWS CLI commands                                           |
| Additional Options                   | `aws help`                                                                                                         | Explore advanced options, plugins, and help documentation                                      |

| Command                                          | Description                                                            |
|--------------------------------------------------|------------------------------------------------------------------------|
| `aws configure`                                  | Configure AWS CLI with interactive prompts                             |
| `aws configure set region <region>`              | Set the default region for AWS CLI                                     |
| `aws configure set output <output>`              | Set the default output format (json, text, table)                      |
| `aws configure set aws_access_key_id <key>`      | Set AWS Access Key ID for the configured profile                       |
| `aws configure set aws_secret_access_key <key>`  | Set AWS Secret Access Key for the configured profile                   |
| `aws configure set profile <profile>`            | Set the named profile for AWS CLI operations                           |
| `aws configure list`                             | List the current AWS CLI configuration settings                        |
| `aws configure get <option>`                     | Get the value of a specific AWS CLI configuration option               |
| `aws configure --profile <profile>`              | Configure AWS CLI settings for a specific profile                      |
| `aws configure --profile <profile> list`         | List the configuration settings for a specific profile                 |
| `aws configure --profile <profile> get <option>` | Get the value of a specific AWS CLI configuration option for a profile |
