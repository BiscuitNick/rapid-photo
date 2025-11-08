#!/bin/bash
# LocalStack Setup Script for Rapid Photo Development

echo "Setting up LocalStack resources..."

# Set endpoint URL for aws CLI
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

# Create S3 buckets
echo "Creating S3 buckets..."
aws s3 mb s3://rapid-photo-uploads-local --endpoint-url=$AWS_ENDPOINT_URL
aws s3 mb s3://amplify-rapidphotoweb-nic-rapidphotouploadsbucketc-cvzqed1qst7p --endpoint-url=$AWS_ENDPOINT_URL

# Create SQS queues
echo "Creating SQS queues..."
aws sqs create-queue --queue-name photo-upload-events-local --endpoint-url=$AWS_ENDPOINT_URL
aws sqs create-queue --queue-name photo-upload-events-local-dlq --endpoint-url=$AWS_ENDPOINT_URL

# Set up DLQ redrive policy
DLQ_ARN=$(aws sqs get-queue-attributes --queue-url http://localhost:4566/000000000000/photo-upload-events-local-dlq --attribute-names QueueArn --query 'Attributes.QueueArn' --output text --endpoint-url=$AWS_ENDPOINT_URL)

aws sqs set-queue-attributes \
  --queue-url http://localhost:4566/000000000000/photo-upload-events-local \
  --attributes '{"RedrivePolicy": "{\"deadLetterTargetArn\":\"'$DLQ_ARN'\",\"maxReceiveCount\":3}"}' \
  --endpoint-url=$AWS_ENDPOINT_URL

# Configure S3 bucket for event notifications to SQS
echo "Configuring S3 event notifications..."
cat > /tmp/s3-notification.json <<EOF
{
  "QueueConfigurations": [
    {
      "QueueArn": "arn:aws:sqs:us-east-1:000000000000:photo-upload-events-local",
      "Events": ["s3:ObjectCreated:*"],
      "Filter": {
        "Key": {
          "FilterRules": [
            {
              "Name": "prefix",
              "Value": "originals/"
            }
          ]
        }
      }
    }
  ]
}
EOF

aws s3api put-bucket-notification-configuration \
  --bucket rapid-photo-uploads-local \
  --notification-configuration file:///tmp/s3-notification.json \
  --endpoint-url=$AWS_ENDPOINT_URL

echo "LocalStack setup complete!"

# Verify resources
echo -e "\n📦 Verifying created resources..."
echo "S3 Buckets:"
aws s3 ls --endpoint-url=$AWS_ENDPOINT_URL

echo -e "\nSQS Queues:"
aws sqs list-queues --endpoint-url=$AWS_ENDPOINT_URL
