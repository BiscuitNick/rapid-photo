#!/bin/bash
# Deploy Lambda to LocalStack with SQS trigger

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║      Deploy Lambda to LocalStack with SQS Trigger         ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Configuration
FUNCTION_NAME="photo-processor"
QUEUE_NAME="photo-upload-events-local"
ENDPOINT="http://localhost:4566"

echo "1️⃣  Checking if Lambda package exists..."
if [ ! -f "lambda-package.zip" ]; then
    echo "   Package not found. Creating it..."
    rm -rf dist
    mkdir -p dist

    echo "   Installing dependencies..."
    source venv/bin/activate
    pip install -r requirements.txt -t dist/ --upgrade -q

    echo "   Copying source code..."
    cp -r src/* dist/

    echo "   Creating zip package..."
    cd dist && zip -r ../lambda-package.zip . -q && cd ..

    echo "   ✅ Package created ($(ls -lh lambda-package.zip | awk '{print $5}'))"
else
    echo "   ✅ Package found ($(ls -lh lambda-package.zip | awk '{print $5}'))"
fi

echo ""
echo "2️⃣  Creating IAM role..."
AWS_ENDPOINT_URL=$ENDPOINT aws iam create-role \
  --role-name lambda-photo-processor-role \
  --assume-role-policy-document '{
    "Version":"2012-10-17",
    "Statement":[{
      "Effect":"Allow",
      "Principal":{"Service":"lambda.amazonaws.com"},
      "Action":"sts:AssumeRole"
    }]
  }' 2>/dev/null && echo "   ✅ IAM role created" || echo "   ✅ IAM role already exists"

echo ""
echo "3️⃣  Deleting existing Lambda (if any)..."
AWS_ENDPOINT_URL=$ENDPOINT aws lambda delete-function \
  --function-name $FUNCTION_NAME \
  2>/dev/null && echo "   ✅ Old function deleted" || echo "   ℹ️  No existing function"

echo ""
echo "4️⃣  Creating Lambda function..."
AWS_ENDPOINT_URL=$ENDPOINT aws lambda create-function \
  --function-name $FUNCTION_NAME \
  --runtime python3.13 \
  --handler handler.lambda_handler \
  --zip-file fileb://lambda-package.zip \
  --role arn:aws:iam::000000000000:role/lambda-photo-processor-role \
  --timeout 300 \
  --memory-size 512 \
  --environment "Variables={
    DB_HOST=host.docker.internal,
    DB_PORT=5432,
    DB_NAME=rapidphoto,
    DB_USER=rapidphoto,
    DB_PASSWORD=rapidphoto_dev,
    S3_BUCKET=amplify-rapidphotoweb-nic-rapidphotouploadsbucketc-cvzqed1qst7p,
    AWS_REGION=us-east-1,
    LOG_LEVEL=INFO
  }" \
  --region us-east-1 > /dev/null

echo "   ✅ Lambda function created"

echo ""
echo "5️⃣  Getting SQS queue ARN..."
QUEUE_ARN=$(AWS_ENDPOINT_URL=$ENDPOINT aws sqs get-queue-attributes \
  --queue-url http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/$QUEUE_NAME \
  --attribute-names QueueArn \
  --query 'Attributes.QueueArn' \
  --output text)

echo "   ✅ Queue ARN: $QUEUE_ARN"

echo ""
echo "6️⃣  Creating SQS event source mapping (trigger)..."
AWS_ENDPOINT_URL=$ENDPOINT aws lambda create-event-source-mapping \
  --function-name $FUNCTION_NAME \
  --event-source-arn $QUEUE_ARN \
  --batch-size 10 \
  --enabled \
  --region us-east-1 > /dev/null

echo "   ✅ SQS trigger created"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                    Deployment Complete!                    ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Summary:"
echo "   Function: $FUNCTION_NAME"
echo "   Queue: $QUEUE_NAME"
echo "   Trigger: Enabled (batch size: 10)"
echo ""
echo "🧪 To test:"
echo "   1. Upload a photo via your backend API"
echo "   2. S3 will send event to SQS"
echo "   3. Lambda will automatically process it"
echo ""
echo "📊 To monitor:"
echo "   - Check SQS: AWS_ENDPOINT_URL=$ENDPOINT aws sqs get-queue-attributes --queue-url http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/$QUEUE_NAME --attribute-names All"
echo "   - Check Lambda logs: AWS_ENDPOINT_URL=$ENDPOINT aws logs tail /aws/lambda/$FUNCTION_NAME --follow"
echo ""
