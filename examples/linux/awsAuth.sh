#!/bin/bash

# AWS Credentials
AWS_ACCESS_KEY="your-access-key"
AWS_SECRET_KEY="your-secret-key"
AWS_REGION="us-east-1"
AWS_SERVICE="s3"
AWS_BUCKET_NAME="your-bucket-name"

# HTTP Request Information
HTTP_METHOD="GET"
HTTP_PATH="/"
HTTP_DATE=$(date -u +'%Y%m%dT%H%M%SZ')
HTTP_HOST="${AWS_BUCKET_NAME}.s3.amazonaws.com"
HTTP_SIGNED_HEADERS="host;x-amz-content-sha256"

# Generate Canonical Request
HTTP_CANONICAL_REQUEST="${HTTP_METHOD}\n${HTTP_PATH}\n\nhost:${HTTP_HOST}\nx-amz-content-sha256:UNSIGNED-PAYLOAD\n\n${HTTP_SIGNED_HEADERS}\n$(echo -n '' | sha256sum | cut -d ' ' -f 1)"

# Generate String to Sign
HTTP_STRING_TO_SIGN="AWS4-HMAC-SHA256\n${HTTP_DATE}\n$(echo -n "${HTTP_DATE}" | cut -c 1-8)/${AWS_REGION}/${AWS_SERVICE}/aws4_request\n$(echo -n "${HTTP_CANONICAL_REQUEST}" | sha256sum | cut -d ' ' -f 1)"

# Generate Signing Key
HTTP_SIGNING_KEY=$(echo -n "AWS4${AWS_SECRET_KEY}" | openssl sha256 -hex | sed 's/^.* //')
HTTP_SIGNING_KEY=$(echo -n "${HTTP_DATE}" | openssl sha256 -hex -mac HMAC -macopt hexkey:${HTTP_SIGNING_KEY} | sed 's/^.* //')
HTTP_SIGNING_KEY=$(echo -n "${AWS_REGION}" | openssl sha256 -hex -mac HMAC -macopt hexkey:${HTTP_SIGNING_KEY} | sed 's/^.* //')
HTTP_SIGNING_KEY=$(echo -n "${AWS_SERVICE}" | openssl sha256 -hex -mac HMAC -macopt hexkey:${HTTP_SIGNING_KEY} | sed 's/^.* //')
HTTP_SIGNING_KEY=$(echo -n "aws4_request" | openssl sha256 -hex -mac HMAC -macopt hexkey:${HTTP_SIGNING_KEY} | sed 's/^.* //')

# Generate Signature
HTTP_SIGNATURE=$(echo -n "${HTTP_STRING_TO_SIGN}" | openssl sha256 -hex -mac HMAC -macopt hexkey:${HTTP_SIGNING_KEY} | sed 's/^.* //')

# Generate Authorization Header
HTTP_AUTHORIZATION_HEADER="AWS4-HMAC-SHA256 Credential=${AWS_ACCESS_KEY}/${HTTP_DATE}/${AWS_REGION}/${AWS_SERVICE}/aws4_request, SignedHeaders=${HTTP_SIGNED_HEADERS}, Signature=${HTTP_SIGNATURE}"

# Send HTTP Request
curl -X ${HTTP_METHOD} "https://${HTTP_HOST}${HTTP_PATH}" \
  -H "Host: ${HTTP_HOST}" \
  -H "Authorization: ${HTTP_AUTHORIZATION_HEADER}" \
  -H "x-amz-content-sha256: UNSIGNED-PAYLOAD" \
  -H "x-amz-date: ${HTTP_DATE}" \
  -s # Suppress curl progress output for clarity
