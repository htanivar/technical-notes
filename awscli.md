| Configuration Item    | Command                                                                                     |
|-----------------------|---------------------------------------------------------------------------------------------|
| AWS Access Key ID     | `aws2 configure set aws_access_key_id YOUR_ACCESS_KEY_ID --profile YourProfileName`         |
| AWS Secret Access Key | `aws2 configure set aws_secret_access_key YOUR_SECRET_ACCESS_KEY --profile YourProfileName` |
| Default region name   | `aws2 configure set region YOUR_DEFAULT_REGION --profile YourProfileName`                   |
| Default output format | `aws2 configure set output YOUR_OUTPUT_FORMAT --profile YourProfileName`                    |

| Description                         | AWS CLI Command                                                                               |
|-------------------------------------|-----------------------------------------------------------------------------------------------|
| List all S3 buckets                 | `aws s3 ls`                                                                                   |
| List objects in a bucket            | `aws s3 ls s3://your-bucket-name`                                                             |
| Create an S3 bucket                 | `aws s3 mb s3://your-new-bucket-name`                                                         |
| Upload a file to S3                 | `aws s3 cp your-local-file.txt s3://your-bucket-name/`                                        |
| Download a file from S3             | `aws s3 cp s3://your-bucket-name/your-s3-file.txt ./local-dir/`                               |
| Sync local directory with S3 bucket | `aws s3 sync ./local-directory/ s3://your-bucket-name/`                                       |
| Delete a file from S3               | `aws s3 rm s3://your-bucket-name/your-s3-file.txt`                                            |
| Delete a bucket                     | `aws s3 rb s3://your-bucket-name`                                                             |
| Copy objects between buckets        | `aws s3 cp s3://source-bucket/source-file.txt s3://destination-bucket/destination-file.txt`   |
| Set bucket ACL (make it public)     | `aws s3api put-bucket-acl --bucket your-bucket-name --acl public-read`                        |
| Set object ACL (make it public)     | `aws s3api put-object-acl --bucket your-bucket-name --key your-s3-file.txt --acl public-read` |


| Scenario                                   | Command                                                                      |
|--------------------------------------------|------------------------------------------------------------------------------|
| Copy a local file to S3 bucket              | `aws s3 cp local-file.txt s3://your-bucket/`                                  |
| Copy a local directory to S3 bucket         | `aws s3 cp local-directory/ s3://your-bucket/ --recursive`                   |
| Copy a file from S3 bucket to local         | `aws s3 cp s3://your-bucket/your-file.txt ./local-directory/`                |
| Copy all files in S3 bucket to local        | `aws s3 cp s3://your-bucket/ ./local-directory/ --recursive`                 |
| Copy files matching a pattern to S3 bucket   | `aws s3 cp ./local-directory/ s3://your-bucket/ --recursive --exclude "*" --include "*.txt"` |
| Copy files between two S3 buckets            | `aws s3 cp s3://source-bucket/ s3://destination-bucket/ --recursive`         |
| Copy with reduced redundancy storage class  | `aws s3 cp local-file.txt s3://your-bucket/ --storage-class REDUCED_REDUNDANCY` |
| Copy with server-side encryption (SSE-S3)    | `aws s3 cp local-file.txt s3://your-bucket/ --sse`                           |
| Copy and set ACL (Access Control List)       | `aws s3 cp local-file.txt s3://your-bucket/ --acl public-read`               |
