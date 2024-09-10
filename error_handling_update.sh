#script to handle errors and provide a meaningful error message when the deployment fails.
#!/bin/bash

# Exit script on any error
set -e

# Function to print error messages
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Variables
BUCKET_NAME="shop-easy-app"
REGION="us-east-1"
APP_CODE_PATH="/app/code"
S3_BUCKET_PATH="s3://${BUCKET_NAME}/"
EC2_USER="ec2-user"
EC2_HOST="ec2-instance"
DOCKER_IMAGE="shop-easy-app"

# Create S3 bucket
echo "Creating S3 bucket..."
aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION" || error_exit "Failed to create S3 bucket."

# Upload application code to S3 bucket
echo "Uploading application code to S3 bucket..."
aws s3 cp "$APP_CODE_PATH" "$S3_BUCKET_PATH" --recursive || error_exit "Failed to upload application code to S3 bucket."

# Deploy application to EC2 instance
echo "Deploying application to EC2 instance..."
ssh "$EC2_USER@$EC2_HOST" "sudo docker run -p 80:80 $DOCKER_IMAGE" || error_exit "Failed to deploy application to EC2 instance."

echo "Deployment completed successfully."
