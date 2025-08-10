#!/bin/bash

# access_check.sh - Verify Cloudflare account access and environment variables
# This script checks if required Cloudflare credentials are available

set -e

echo "=== Cloudflare Account Access Check ==="
echo "Date: $(date)"
echo ""

# Required environment variables
REQUIRED_VARS=("CLOUDFLARE_API_TOKEN" "CLOUDFLARE_ACCOUNT_ID")
OPTIONAL_VARS=("CLOUDFLARE_ZONE_ID" "CLOUDFLARE_EMAIL")

# Function to check if variable is set and not empty
check_var() {
    local var_name="$1"
    local var_value="${!var_name}"
    
    if [ -z "$var_value" ]; then
        return 1
    else
        return 0
    fi
}

# Function to mask sensitive values for display
mask_value() {
    local value="$1"
    local length=${#value}
    
    if [ $length -le 8 ]; then
        echo "****"
    else
        echo "${value:0:4}****${value: -4}"
    fi
}

echo "Checking required environment variables..."
echo ""

missing_vars=()
for var in "${REQUIRED_VARS[@]}"; do
    if check_var "$var"; then
        masked_value=$(mask_value "${!var}")
        echo "✓ $var: $masked_value"
    else
        echo "✗ $var: NOT SET"
        missing_vars+=("$var")
    fi
done

echo ""
echo "Checking optional environment variables..."
echo ""

for var in "${OPTIONAL_VARS[@]}"; do
    if check_var "$var"; then
        masked_value=$(mask_value "${!var}")
        echo "✓ $var: $masked_value"
    else
        echo "- $var: NOT SET (optional)"
    fi
done

echo ""

# If required variables are missing, provide guidance
if [ ${#missing_vars[@]} -gt 0 ]; then
    echo "❌ MISSING REQUIRED VARIABLES"
    echo ""
    echo "The following required environment variables are not set:"
    for var in "${missing_vars[@]}"; do
        echo "  - $var"
    done
    echo ""
    echo "To set these variables, you can:"
    echo ""
    echo "1. Export them in your current session:"
    for var in "${missing_vars[@]}"; do
        echo "   export $var='your_${var,,}_here'"
    done
    echo ""
    echo "2. Add them to your ~/.bashrc or ~/.profile:"
    for var in "${missing_vars[@]}"; do
        echo "   echo 'export $var=\"your_${var,,}_here\"' >> ~/.bashrc"
    done
    echo "   source ~/.bashrc"
    echo ""
    echo "3. Create a .env file and source it:"
    echo "   cat > cloudflare.env << EOF"
    for var in "${missing_vars[@]}"; do
        echo "   export $var='your_${var,,}_here'"
    done
    echo "   EOF"
    echo "   source cloudflare.env"
    echo ""
    echo "How to get these values:"
    echo "• CLOUDFLARE_API_TOKEN: Go to https://dash.cloudflare.com/profile/api-tokens"
    echo "  Create a token with 'Cloudflare Tunnel:Edit' permissions"
    echo "• CLOUDFLARE_ACCOUNT_ID: Found in the right sidebar of any domain in your Cloudflare dashboard"
    echo ""
    exit 1
fi

# Test API connectivity if curl is available
if command -v curl &> /dev/null; then
    echo "Testing Cloudflare API connectivity..."
    echo ""
    
    # Test API token validity
    response=$(curl -s -w "%{http_code}" -o /tmp/cf_test_response \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" \
        "https://api.cloudflare.com/client/v4/user/tokens/verify")
    
    if [ "$response" = "200" ]; then
        echo "✓ API Token is valid"
        
        # Extract token info
        if command -v jq &> /dev/null; then
            token_status=$(jq -r '.result.status' /tmp/cf_test_response 2>/dev/null || echo "unknown")
            echo "  Token status: $token_status"
        fi
    else
        echo "✗ API Token validation failed (HTTP $response)"
        if [ -f /tmp/cf_test_response ]; then
            echo "Response:"
            cat /tmp/cf_test_response
        fi
        rm -f /tmp/cf_test_response
        exit 1
    fi
    
    # Test account access
    response=$(curl -s -w "%{http_code}" -o /tmp/cf_account_response \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" \
        "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID")
    
    if [ "$response" = "200" ]; then
        echo "✓ Account access verified"
        
        # Extract account info
        if command -v jq &> /dev/null; then
            account_name=$(jq -r '.result.name' /tmp/cf_account_response 2>/dev/null || echo "unknown")
            echo "  Account: $account_name"
        fi
    else
        echo "✗ Account access failed (HTTP $response)"
        if [ -f /tmp/cf_account_response ]; then
            echo "Response:"
            cat /tmp/cf_account_response
        fi
        rm -f /tmp/cf_account_response
        exit 1
    fi
    
    # Clean up temp files
    rm -f /tmp/cf_test_response /tmp/cf_account_response
    
else
    echo "⚠ curl not available - skipping API connectivity test"
    echo "  Install curl to enable API testing: sudo apt-get install curl"
fi

echo ""
echo "✅ All checks passed! Your Cloudflare credentials are properly configured."
echo ""
echo "Next step: Run install_cloudflare.sh to install Cloudflare Tunnel"
