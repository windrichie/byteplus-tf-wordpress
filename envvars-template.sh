#!/bin/bash
#
# Environment Variables Template for BytePlus Terraform
# 
# Instructions:
# 1. Copy this file: cp envvars-template.sh envvars.sh
# 2. Edit envvars.sh with your actual BytePlus credentials
# 3. Source the file: source envvars.sh
# 4. Run terraform commands
#
# IMPORTANT: Never commit envvars.sh to version control!
#

# BytePlus Access Credentials
# Get these from BytePlus Console > Access Key Management
export BYTEPLUS_ACCESS_KEY="your-access-key-here"
export BYTEPLUS_SECRET_KEY="your-secret-key-here"
export BYTEPLUS_REGION="ap-southeast-3"

# AWS S3 Compatible Credentials for TOS Backend
# Use the same BytePlus credentials for TOS (Torch Object Storage)
export AWS_ACCESS_KEY_ID="$BYTEPLUS_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$BYTEPLUS_SECRET_KEY"

# Optional: Set session name for better tracking
export BYTEPLUS_SESSION_NAME="terraform-wordpress-deployment"

echo "✅ BytePlus environment variables loaded"
echo "📍 Region: $BYTEPLUS_REGION"
echo "🔑 Access Key: ${BYTEPLUS_ACCESS_KEY:0:8}..."
echo ""
echo "🚀 You can now run terraform commands:"
echo "   terraform init"
echo "   terraform plan"
echo "   terraform apply"