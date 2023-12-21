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
