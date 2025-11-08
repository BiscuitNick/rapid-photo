#!/bin/bash
# Restart LocalStack with Lambda support

echo "Stopping current LocalStack container..."
docker stop localstack-rapid
docker rm localstack-rapid

echo "Starting LocalStack with Lambda support..."
docker run -d \
  --name localstack-rapid \
  -p 4566:4566 \
  -p 4571:4571 \
  -e SERVICES=s3,sqs,lambda,iam,logs \
  -e DEFAULT_REGION=us-east-1 \
  -e DEBUG=1 \
  -e LAMBDA_EXECUTOR=docker \
  -e DOCKER_HOST=unix:///var/run/docker.sock \
  -v /var/run/docker.sock:/var/run/docker.sock \
  localstack/localstack:latest

echo "Waiting for LocalStack to be ready..."
sleep 10

echo "Checking LocalStack health..."
curl -s http://localhost:4566/_localstack/health | python3 -m json.tool

echo ""
echo "✅ LocalStack restarted with Lambda support!"
echo ""
echo "Next steps:"
echo "1. Re-run the LocalStack setup script:"
echo "   ./scripts/setup-localstack.sh"
echo ""
echo "2. Deploy the Lambda:"
echo "   cd lambda"
echo "   ./deploy-to-localstack.sh"
