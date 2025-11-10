# Lightsail Deployment Guide

**Cost-Optimized Platform:** ~$25-30/month (vs $200-300/month for ECS)

This guide covers deploying the RapidPhotoUpload backend to AWS Lightsail Container Service instead of ECS Fargate.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Infrastructure Deployment](#infrastructure-deployment)
- [Application Deployment](#application-deployment)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Rollback](#rollback)

## Prerequisites

### Required Tools
- AWS CLI v2
- Terraform >= 1.9.0
- Docker
- jq (for JSON parsing)

### Infrastructure Setup

Ensure your infrastructure is deployed with `backend_platform = "lightsail"`:

```bash
cd infrastructure

# Verify or set platform in tfvars
cat environments/dev.tfvars | grep backend_platform
# Should show: backend_platform = "lightsail"

# Deploy infrastructure
terraform apply -var-file=environments/dev.tfvars

# Verify Lightsail resources are created
terraform output backend_platform  # Should show "lightsail"
```

## Infrastructure Deployment

### Lightsail Resources Created

- **Container Service:** Micro power, 1 instance (~$10/month)
- **PostgreSQL Database:** Micro_2_0 bundle (~$15/month)
- **Static IP:** Free with Lightsail
- **IAM User:** For S3/SQS access (least-privilege)

### Get Infrastructure Outputs

```bash
cd infrastructure

# Get all outputs
terraform output

# Key outputs:
terraform output backend_api_endpoint     # Lightsail container URL
terraform output lightsail_static_ip      # Static IP address
terraform output db_secret_arn            # Database credentials
terraform output lightsail_credentials_secret_arn  # IAM credentials
terraform output s3_bucket_name           # S3 bucket
terraform output sqs_queue_url            # SQS queue URL
```

## Application Deployment

### Step 1: Get Secrets from Secrets Manager

```bash
# Set variables from Terraform outputs
DB_SECRET_ARN=$(terraform output -raw db_secret_arn)
CREDS_SECRET_ARN=$(terraform output -raw lightsail_credentials_secret_arn)

# Retrieve and view database credentials
echo "Database Credentials:"
aws secretsmanager get-secret-value \
  --secret-id $DB_SECRET_ARN \
  --query SecretString \
  --output text | jq .

# Retrieve and view IAM credentials (for S3/SQS)
echo "IAM Credentials:"
aws secretsmanager get-secret-value \
  --secret-id $CREDS_SECRET_ARN \
  --query SecretString \
  --output text | jq .
```

### Step 2: Build Spring Backend

```bash
cd backend

# Build JAR (production profile)
./gradlew clean bootJar

# Build Docker image
docker build -t rapid-photo-backend:latest .

# Verify image
docker images | grep rapid-photo-backend
```

### Step 3: Push to Lightsail

```bash
# Get Lightsail service name from Terraform
cd ../infrastructure
SERVICE_NAME=$(terraform output -raw backend_api_endpoint | cut -d'.' -f1 | cut -d'/' -f3)
echo "Service name: $SERVICE_NAME"

# Push image to Lightsail
cd ../backend
aws lightsail push-container-image \
  --service-name $SERVICE_NAME \
  --label backend \
  --image rapid-photo-backend:latest \
  --region us-east-1

# **IMPORTANT:** Save the image name from the output
# It will look like: :backend.1, :backend.2, etc.
# Example output:
#   Image "rapid-photo-dev-backend:backend.1" registered.
```

### Step 4: Create Deployment

Extract secrets and create deployment JSON:

```bash
cd ../infrastructure

# Extract all secrets and configs
DB_SECRET=$(aws secretsmanager get-secret-value --secret-id $DB_SECRET_ARN --query SecretString --output text)
CREDS_SECRET=$(aws secretsmanager get-secret-value --secret-id $CREDS_SECRET_ARN --query SecretString --output text)

# Parse database credentials
export DB_HOST=$(echo $DB_SECRET | jq -r .host)
export DB_PORT=$(echo $DB_SECRET | jq -r .port)
export DB_NAME=$(echo $DB_SECRET | jq -r .dbname)
export DB_USERNAME=$(echo $DB_SECRET | jq -r .username)
export DB_PASSWORD=$(echo $DB_SECRET | jq -r .password)

# Parse IAM credentials
export AWS_ACCESS_KEY_ID_LIGHTSAIL=$(echo $CREDS_SECRET | jq -r .aws_access_key_id)
export AWS_SECRET_ACCESS_KEY_LIGHTSAIL=$(echo $CREDS_SECRET | jq -r .aws_secret_access_key)

# Get other configs from Terraform
export S3_BUCKET=$(terraform output -raw s3_bucket_name)
export SQS_QUEUE_URL=$(terraform output -raw sqs_queue_url)

# **REPLACE THIS with the image tag from Step 3**
export IMAGE_TAG=":backend.1"  # Example: :backend.1, :backend.2, etc.

# Create deployment JSON
cat > lightsail-deployment.json <<EOF
{
  "containers": {
    "backend": {
      "image": "$SERVICE_NAME$IMAGE_TAG",
      "environment": {
        "SPRING_PROFILES_ACTIVE": "lightsail",
        "AWS_REGION": "us-east-1",
        "DB_HOST": "$DB_HOST",
        "DB_PORT": "$DB_PORT",
        "DB_NAME": "$DB_NAME",
        "DB_USERNAME": "$DB_USERNAME",
        "DB_PASSWORD": "$DB_PASSWORD",
        "AWS_ACCESS_KEY_ID": "$AWS_ACCESS_KEY_ID_LIGHTSAIL",
        "AWS_SECRET_ACCESS_KEY": "$AWS_SECRET_ACCESS_KEY_LIGHTSAIL",
        "S3_BUCKET_NAME": "$S3_BUCKET",
        "SQS_QUEUE_URL": "$SQS_QUEUE_URL",
        "SQS_PHOTO_UPLOAD_QUEUE": "$SQS_QUEUE_URL",
        "LAMBDA_SECRET": "rapid-photo-lambda-secret-change-in-production",
        "COGNITO_ISSUER_URI": "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_XXXXXXX",
        "COGNITO_JWK_SET_URI": "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_XXXXXXX/.well-known/jwks.json"
      },
      "ports": {
        "8080": "HTTP"
      }
    }
  },
  "publicEndpoint": {
    "containerName": "backend",
    "containerPort": 8080,
    "healthCheck": {
      "healthyThreshold": 2,
      "unhealthyThreshold": 3,
      "timeoutSeconds": 5,
      "intervalSeconds": 30,
      "path": "/actuator/health",
      "successCodes": "200"
    }
  }
}
EOF

# Review deployment JSON
cat lightsail-deployment.json | jq .
```

### Step 5: Deploy to Lightsail

```bash
# Deploy
aws lightsail create-container-service-deployment \
  --service-name $SERVICE_NAME \
  --cli-input-json file://lightsail-deployment.json \
  --region us-east-1

# Monitor deployment status (should eventually show "ACTIVE")
watch -n 5 'aws lightsail get-container-services \
  --service-name '$SERVICE_NAME' \
  --region us-east-1 | jq -r ".containerServices[0].state"'

# Or check once
aws lightsail get-container-services \
  --service-name $SERVICE_NAME \
  --region us-east-1 | jq .containerServices[0].state
```

### Step 6: Verify Deployment

```bash
# Get backend URL
BACKEND_URL=$(terraform output -raw backend_api_endpoint)

# Test health endpoint
curl $BACKEND_URL/actuator/health | jq .

# Expected response:
# {
#   "status": "UP",
#   ...
# }

# Test info endpoint
curl $BACKEND_URL/actuator/info | jq .

# Check container logs
aws lightsail get-container-log \
  --service-name $SERVICE_NAME \
  --container-name backend \
  --region us-east-1 | less
```

## Monitoring

### CloudWatch Dashboards

Access via AWS Console:
```
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=rapid-photo-dev-dashboard
```

The dashboard includes:
- **Lightsail Container:** CPU & Memory utilization, Network I/O
- **Lightsail Database:** CPU, Connections, Storage, Network throughput
- **Lambda:** Invocations, Errors, Duration
- **SQS:** Queue depth, Message age
- **S3:** Bucket operations

### CloudWatch Alarms

Alarms are automatically created for:
- Container CPU > 80%
- Container Memory > 85%
- Database CPU > 80%
- Database Connections > threshold
- Database Free Storage < threshold

### View Metrics via CLI

```bash
# Container CPU utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lightsail \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=$SERVICE_NAME \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum

# Container Memory utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lightsail \
  --metric-name MemoryUtilization \
  --dimensions Name=ServiceName,Value=$SERVICE_NAME \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum
```

### View Container Logs

```bash
# View recent logs
aws lightsail get-container-log \
  --service-name $SERVICE_NAME \
  --container-name backend \
  --region us-east-1

# Follow logs (refresh every 5 seconds)
watch -n 5 'aws lightsail get-container-log \
  --service-name '$SERVICE_NAME' \
  --container-name backend \
  --region us-east-1 | tail -50'
```

## Troubleshooting

### Deployment Stuck or Failed

```bash
# Check deployment state
aws lightsail get-container-services \
  --service-name $SERVICE_NAME \
  --region us-east-1 | jq .containerServices[0]

# Check for errors in logs
aws lightsail get-container-log \
  --service-name $SERVICE_NAME \
  --container-name backend \
  --region us-east-1 | grep -i error

# Common issues:
# 1. Image tag mismatch - verify image name in deployment JSON
# 2. Environment variable errors - check secret values
# 3. Database connection failure - verify DB credentials and network access
```

### Health Check Failing

```bash
# Check health endpoint directly
curl $BACKEND_URL/actuator/health -v

# Verify database connectivity from container
# (check logs for database connection errors)
aws lightsail get-container-log \
  --service-name $SERVICE_NAME \
  --container-name backend \
  --region us-east-1 | grep -i "database\|connection\|flyway"
```

### High CPU/Memory Usage

```bash
# Check current resource usage
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lightsail \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=$SERVICE_NAME \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Average,Maximum

# Consider upgrading to larger instance
# Edit infrastructure/environments/dev.tfvars:
# lightsail_container_power = "small"  # or medium, large
# Then terraform apply
```

## Rollback

### Rollback to Previous Image

Lightsail doesn't have a direct "rollback" command. You need to redeploy a previous image:

```bash
# List previous container images
aws lightsail get-container-images \
  --service-name $SERVICE_NAME \
  --region us-east-1

# Use a previous image tag (e.g., :backend.1) and redeploy
# Follow Step 4 and 5 above with the previous IMAGE_TAG
```

### Switch Back to ECS Platform

If you need to switch back to the ECS platform:

```bash
cd infrastructure

# Edit environments/dev.tfvars
# Change: backend_platform = "ecs"

# Apply changes
terraform apply -var-file=environments/dev.tfvars

# This will:
# - Create ECS cluster, service, RDS
# - Keep Lightsail resources (they won't be destroyed unless manually removed)
# - Update Lambda to point to RDS instead of Lightsail DB
```

## Performance Tuning

### Connection Pool Sizing

The `lightsail` Spring profile sets conservative pool sizes:
- Initial: 5 connections
- Max: 10 connections

For higher load, edit `backend/src/main/resources/application.yml` (lightsail profile):

```yaml
spring:
  r2dbc:
    pool:
      initial-size: 10
      max-size: 20
```

### Container Scaling

Lightsail micro instance supports 1-3 containers. To scale:

```bash
# Edit infrastructure/environments/dev.tfvars
lightsail_container_scale = 2  # or 3

# Apply
cd infrastructure
terraform apply -var-file=environments/dev.tfvars
```

## Cost Optimization

Current monthly costs (~$25-30):
- Lightsail Container (micro): $10/month
- Lightsail PostgreSQL (micro): $15/month
- Static IP: Free
- IAM user: Free
- Lambda: ~$5-10/month (usage-based)
- S3/SQS: ~$1-2/month (usage-based)

Total: ~$25-30/month vs $200-300/month for ECS platform

## Related Documentation

- [Infrastructure README](../infrastructure/README.md) - Platform selection and architecture
- [Main Deployment Guide](./deployment.md) - ECS deployment procedures
- [Local Development Setup](./LOCAL_DEV_SETUP.md) - Running locally
