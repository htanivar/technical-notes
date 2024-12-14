| Configuration Item    | Command                                                                                     |
|-----------------------|---------------------------------------------------------------------------------------------|
| AWS Access Key ID     | `aws2 configure set aws_access_key_id YOUR_ACCESS_KEY_ID --profile YourProfileName`         |
| AWS Secret Access Key | `aws2 configure set aws_secret_access_key YOUR_SECRET_ACCESS_KEY --profile YourProfileName` |
| Default region name   | `aws2 configure set region YOUR_DEFAULT_REGION --profile YourProfileName`                   |
| Default output format | `aws2 configure set output YOUR_OUTPUT_FORMAT --profile YourProfileName`                    |

# AWS CLI Notes

This document provides an extensive list of AWS CLI commands for common operations across multiple AWS services.

---

## **AWS CLI Basics**

| Command              | Description                                                        |
|----------------------|--------------------------------------------------------------------|
| `aws --version`      | Check AWS CLI version.                                             |
| `aws configure`      | Configure AWS CLI (Access Key, Secret Key, Region, Output format). |
| `aws help`           | Get help on AWS CLI commands.                                      |
| `aws <service> help` | Get help for a specific service.                                   |

---

## **S3 Commands**

| Command                                       | Description                         |
|-----------------------------------------------|-------------------------------------|
| `aws s3 ls`                                   | List all S3 buckets.                |
| `aws s3api list-buckets`                      | List all buckets using the API.     |
| `aws s3 mb s3://<bucket>`                     | Create a new bucket.                |
| `aws s3 rb s3://<bucket>`                     | Delete an empty bucket.             |
| `aws s3 rb s3://<bucket> --force`             | Delete a bucket and its contents.   |
| `aws s3 cp <local_file> s3://<bucket>/`       | Upload a file to a bucket.          |
| `aws s3 cp s3://<bucket>/<file> <local_file>` | Download a file from a bucket.      |
| `aws s3 mv <source> <destination>`            | Move/rename files in a bucket.      |
| `aws s3 rm s3://<bucket>/<file>`              | Remove a file from a bucket.        |
| `aws s3 sync <local_dir> s3://<bucket>/`      | Sync a local directory to a bucket. |
| `aws s3 sync s3://<bucket>/ <local_dir>`      | Sync a bucket to a local directory. |

---

## **EC2 Commands**

| Command                                                                                | Description                       |
|----------------------------------------------------------------------------------------|-----------------------------------|
| `aws ec2 describe-instances`                                                           | List all EC2 instances.           |
| `aws ec2 describe-instance-status`                                                     | Get instance status.              |
| `aws ec2 start-instances --instance-ids <instance_id>`                                 | Start an EC2 instance.            |
| `aws ec2 stop-instances --instance-ids <instance_id>`                                  | Stop an EC2 instance.             |
| `aws ec2 reboot-instances --instance-ids <instance_id>`                                | Reboot an EC2 instance.           |
| `aws ec2 terminate-instances --instance-ids <instance_id>`                             | Terminate an EC2 instance.        |
| `aws ec2 describe-images`                                                              | List available AMIs.              |
| `aws ec2 create-image --instance-id <instance_id> --name <name>`                       | Create an image (AMI).            |
| `aws ec2 allocate-address`                                                             | Allocate an Elastic IP address.   |
| `aws ec2 associate-address --instance-id <instance_id> --allocation-id <eip_alloc_id>` | Associate Elastic IP to instance. |
| `aws ec2 describe-security-groups`                                                     | List all security groups.         |
| `aws ec2 create-security-group --group-name <name> --description <desc>`               | Create a security group.          |

---

## **IAM Commands**

| Command                                                                          | Description                      |
|----------------------------------------------------------------------------------|----------------------------------|
| `aws iam list-users`                                                             | List all IAM users.              |
| `aws iam create-user --user-name <username>`                                     | Create a new IAM user.           |
| `aws iam delete-user --user-name <username>`                                     | Delete an IAM user.              |
| `aws iam list-groups`                                                            | List all IAM groups.             |
| `aws iam create-group --group-name <groupname>`                                  | Create an IAM group.             |
| `aws iam delete-group --group-name <groupname>`                                  | Delete an IAM group.             |
| `aws iam attach-group-policy --group-name <groupname> --policy-arn <policy_arn>` | Attach a policy to a group.      |
| `aws iam detach-group-policy --group-name <groupname> --policy-arn <policy_arn>` | Detach a policy from a group.    |
| `aws iam list-policies`                                                          | List all IAM policies.           |
| `aws iam get-user`                                                               | Get details of the current user. |

---

## **CloudFormation Commands**

| Command                                                                                            | Description                     |
|----------------------------------------------------------------------------------------------------|---------------------------------|
| `aws cloudformation list-stacks`                                                                   | List all CloudFormation stacks. |
| `aws cloudformation create-stack --stack-name <stack_name> --template-body file://<template.json>` | Create a stack.                 |
| `aws cloudformation update-stack --stack-name <stack_name> --template-body file://<template.json>` | Update a stack.                 |
| `aws cloudformation delete-stack --stack-name <stack_name>`                                        | Delete a stack.                 |
| `aws cloudformation describe-stacks --stack-name <stack_name>`                                     | Describe a specific stack.      |

---

## **Lambda Commands**

| Command                                                                                                                                 | Description                      |
|-----------------------------------------------------------------------------------------------------------------------------------------|----------------------------------|
| `aws lambda list-functions`                                                                                                             | List all Lambda functions.       |
| `aws lambda create-function --function-name <name> --runtime <runtime> --role <role_arn> --handler <handler> --zip-file fileb://<file>` | Create a Lambda function.        |
| `aws lambda update-function-code --function-name <name> --zip-file fileb://<file>`                                                      | Update a Lambda function's code. |
| `aws lambda invoke --function-name <name> <output_file>`                                                                                | Invoke a Lambda function.        |
| `aws lambda delete-function --function-name <name>`                                                                                     | Delete a Lambda function.        |

---

## **Helpful Tips**

| Tip                            | Description                                                                          |
|--------------------------------|--------------------------------------------------------------------------------------|
| Use `--query`                  | Format JSON responses for clarity (e.g., extract fields).                            |
| Use `--output`                 | Specify the output format: `json`, `table`, or `text`.                               |
| Use `--profile <profile_name>` | Use a specific AWS CLI profile for commands.                                         |
| Use environment variables      | Set `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_DEFAULT_REGION` directly. |
