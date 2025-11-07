# RapidPhotoUpload - Deployment & Operations Runbook

## Table of Contents
- [Prerequisites](#prerequisites)
- [Infrastructure Deployment](#infrastructure-deployment)
- [Application Deployment](#application-deployment)
- [Monitoring & Observability](#monitoring--observability)
- [Rollback Procedures](#rollback-procedures)
- [Common Operations](#common-operations)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools
- AWS CLI v2
- Terraform >= 1.9.0
- Docker
- kubectl (for ECS Exec)
- k6 (for load testing)

### Required Access
- AWS IAM credentials with appropriate permissions
- GitHub repository access
- Access to AWS SSM/Secrets Manager

### Environment Variables
```bash
# AWS Credentials
export AWS_ACCESS_KEY_ID=<your-key-id>
export AWS_SECRET_ACCESS_KEY=<your-secret-key>
export AWS_REGION=us-east-1

# Application Secrets (stored in AWS Secrets Manager)
# These are managed by Terraform
```

## Infrastructure Deployment

### Initial Setup

#### 1. Configure Terraform Backend (Production Only)

Edit `infrastructure/main.tf` and uncomment the backend configuration:

```hcl
backend "s3" {
  bucket         = "rapid-photo-terraform-state-<account-id>"
  key            = "prod/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "rapid-photo-terraform-locks"
  encrypt        = true
}
```

Create the S3 bucket and DynamoDB table manually:

```bash
# Create state bucket
aws s3 mb s3://rapid-photo-terraform-state-<account-id> --region us-east-1
aws s3api put-bucket-versioning \
  --bucket rapid-photo-terraform-state-<account-id> \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name rapid-photo-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

#### 2. Deploy Infrastructure

```bash
cd infrastructure

# Initialize Terraform
terraform init

# Plan deployment (Dev)
terraform plan -var-file=environments/dev.tfvars -out=tfplan

# Apply (Dev)
terraform apply tfplan

# Plan deployment (Prod)
terraform plan -var-file=environments/prod.tfvars -out=tfplan-prod

# Apply (Prod) - requires approval
terraform apply tfplan-prod
```

#### 3. Verify Infrastructure

```bash
# Get outputs
terraform output

# Verify VPC
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=RapidPhotoUpload"

# Verify RDS
aws rds describe-db-instances --db-instance-identifier rapid-photo-prod-db

# Verify ECS Cluster
aws ecs describe-clusters --clusters rapid-photo-prod-cluster

# Verify Lambda
aws lambda get-function --function-name rapid-photo-prod-image-processor
```

## Application Deployment

### Backend (ECS Fargate)

#### Build and Push Docker Image

```bash
cd backend

# Build Docker image
docker build -t rapid-photo-backend:latest .

# Tag for ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Create ECR repository (first time only)
aws ecr create-repository --repository-name rapid-photo/backend --region us-east-1

# Tag and push
docker tag rapid-photo-backend:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/rapid-photo/backend:latest
docker tag rapid-photo-backend:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/rapid-photo/backend:v1.0.0
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/rapid-photo/backend:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/rapid-photo/backend:v1.0.0
```

#### Update ECS Service

```bash
# Update task definition with new image
aws ecs update-service \
  --cluster rapid-photo-prod-cluster \
  --service rapid-photo-prod-backend \
  --force-new-deployment

# Monitor deployment
aws ecs wait services-stable \
  --cluster rapid-photo-prod-cluster \
  --services rapid-photo-prod-backend

# Check service status
aws ecs describe-services \
  --cluster rapid-photo-prod-cluster \
  --services rapid-photo-prod-backend
```

### Lambda (Image Processor)

#### Package and Deploy

```bash
cd lambda

# Install dependencies
pip install -r requirements.txt -t package/

# Package Lambda
cd package
zip -r ../lambda.zip .
cd ..
zip -g lambda.zip src/*.py

# Deploy via Terraform (recommended)
cd ../infrastructure
terraform apply -var-file=environments/prod.tfvars -target=module.compute.aws_lambda_function.image_processor

# Or deploy directly with AWS CLI
aws lambda update-function-code \
  --function-name rapid-photo-prod-image-processor \
  --zip-file fileb://lambda.zip \
  --region us-east-1
```

### Mobile (Flutter)

#### Build and Deploy

```bash
cd mobile

# Build Android APK
flutter build apk --release

# Build iOS (requires macOS)
flutter build ios --release

# Build App Bundle for Play Store
flutter build appbundle --release

# Artifacts location:
# Android: build/app/outputs/flutter-apk/app-release.apk
# iOS: build/ios/archive/
```

### Web (React/Vite)

#### Build and Deploy to S3/CloudFront

```bash
cd web

# Build production bundle
npm run build

# Deploy to S3
aws s3 sync dist/ s3://rapid-photo-prod-web-<account-id>/ --delete

# Invalidate CloudFront cache (if using CloudFront)
aws cloudfront create-invalidation \
  --distribution-id <distribution-id> \
  --paths "/*"
```

## Monitoring & Observability

### CloudWatch Dashboards

Access the main dashboard:
```bash
# Get dashboard URL
aws cloudwatch get-dashboard --dashboard-name rapid-photo-prod-dashboard

# Or via Console
# https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=rapid-photo-prod-dashboard
```

### Key Metrics to Monitor

**ECS Service (RED Metrics)**
- Request Rate: `AWS/ApplicationELB - RequestCount`
- Error Rate: `AWS/ApplicationELB - HTTPCode_Target_5XX_Count`
- Duration: `AWS/ApplicationELB - TargetResponseTime (p50, p95, p99)`

**ECS Service (USE Metrics)**
- Utilization: `AWS/ECS - CPUUtilization`, `MemoryUtilization`
- Saturation: `RunningTaskCount` vs `DesiredTaskCount`
- Errors: Container crashes, health check failures

**Lambda Processing**
- Invocations: `AWS/Lambda - Invocations`
- Errors: `AWS/Lambda - Errors`
- Duration: `AWS/Lambda - Duration (p95)`
- Throttles: `AWS/Lambda - Throttles`

**SQS Queue**
- Queue Depth: `AWS/SQS - ApproximateNumberOfMessagesVisible`
- Message Age: `AWS/SQS - ApproximateAgeOfOldestMessage`
- DLQ Messages: `AWS/SQS - DLQ ApproximateNumberOfMessagesVisible`

### CloudWatch Logs Insights Queries

**Find Errors:**
```sql
fields @timestamp, @message, @logStream
| filter @message like /ERROR|Exception|error/
| sort @timestamp desc
| limit 100
```

**Slow Requests:**
```sql
fields @timestamp, @message, @logStream
| filter @message like /duration/
| parse @message /duration=(?<duration>\d+)/
| filter duration > 1000
| sort duration desc
| limit 50
```

### X-Ray Tracing

View trace maps and service dependencies:
```bash
# Get trace summaries
aws xray get-trace-summaries \
  --start-time $(date -u -d '1 hour ago' +%s) \
  --end-time $(date -u +%s)
```

Access via Console: `https://console.aws.amazon.com/xray/home?region=us-east-1#/traces`

## Rollback Procedures

### ECS Service Rollback

```bash
# List previous task definitions
aws ecs list-task-definitions \
  --family-prefix rapid-photo-prod-backend \
  --sort DESC

# Rollback to previous version
PREVIOUS_TASK_DEF="rapid-photo-prod-backend:N" # Replace N with previous revision

aws ecs update-service \
  --cluster rapid-photo-prod-cluster \
  --service rapid-photo-prod-backend \
  --task-definition $PREVIOUS_TASK_DEF

# Monitor rollback
aws ecs wait services-stable \
  --cluster rapid-photo-prod-cluster \
  --services rapid-photo-prod-backend
```

### Lambda Rollback

```bash
# List function versions
aws lambda list-versions-by-function \
  --function-name rapid-photo-prod-image-processor

# Rollback to previous version
PREVIOUS_VERSION="N" # Replace N with previous version number

aws lambda update-alias \
  --function-name rapid-photo-prod-image-processor \
  --name prod \
  --function-version $PREVIOUS_VERSION
```

### Database Rollback

**IMPORTANT:** Database schema changes should use Flyway migrations and be backward compatible.

```bash
# Connect to RDS via bastion host or VPN
psql -h <db-endpoint> -U rapidphoto_admin -d rapidphoto

# Check current schema version
SELECT version, description, installed_on FROM flyway_schema_history ORDER BY installed_rank DESC;

# Rollback is done via new migration (not recommended)
# Instead, design migrations to be backward compatible
```

### Terraform Rollback

```bash
# View state
terraform show

# Rollback to previous state (if needed)
terraform state pull > backup.tfstate
terraform state push previous-state.tfstate

# Revert specific resource
terraform import <resource-type>.<resource-name> <resource-id>
```

## Common Operations

### Scale ECS Service

```bash
# Scale up
aws ecs update-service \
  --cluster rapid-photo-prod-cluster \
  --service rapid-photo-prod-backend \
  --desired-count 5

# Scale down
aws ecs update-service \
  --cluster rapid-photo-prod-cluster \
  --service rapid-photo-prod-backend \
  --desired-count 2
```

### Access ECS Container

```bash
# List running tasks
aws ecs list-tasks \
  --cluster rapid-photo-prod-cluster \
  --service-name rapid-photo-prod-backend

# Execute command in container
TASK_ID="<task-id>"
aws ecs execute-command \
  --cluster rapid-photo-prod-cluster \
  --task $TASK_ID \
  --container backend \
  --interactive \
  --command "/bin/sh"
```

### Database Maintenance

```bash
# Create manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier rapid-photo-prod-db \
  --db-snapshot-identifier rapid-photo-manual-$(date +%Y%m%d-%H%M%S)

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier rapid-photo-prod-db-restored \
  --db-snapshot-identifier <snapshot-id>
```

### Run Load Tests

```bash
cd tests/load

# Set environment variables
export API_BASE_URL="http://<alb-dns-name>"
export AUTH_TOKEN="<jwt-token>"

# Run load test (100 concurrent users for 90 seconds)
k6 run --vus 100 --duration 90s upload-flow.js

# Run load test (100 iterations)
k6 run --vus 100 --iterations 100 upload-flow.js

# Run with custom thresholds
k6 run --vus 100 --duration 90s \
  --threshold 'http_req_duration{p(95)}<2000' \
  --threshold 'http_req_failed<0.01' \
  upload-flow.js
```

## Troubleshooting

### High Error Rate

1. Check CloudWatch Logs for error patterns
2. Check X-Ray traces for failing requests
3. Verify database connectivity and query performance
4. Check S3 bucket permissions and quotas
5. Verify SQS queue processing

### High Latency

1. Check ECS CPU/Memory utilization
2. Check RDS Performance Insights
3. Review slow query logs
4. Check ALB target health
5. Verify network connectivity between services

### Lambda Throttling

1. Check concurrent executions
2. Review reserved concurrency settings
3. Check SQS queue depth
4. Review Lambda duration metrics
5. Optimize Lambda code or increase memory

### Database Connection Issues

1. Check security group rules
2. Verify subnet routing
3. Check RDS instance status
4. Review connection pool settings
5. Check SSL/TLS certificate validity

### Failed Deployments

1. Check ECS service events
2. Review task definition configuration
3. Verify IAM role permissions
4. Check CloudWatch Logs for startup errors
5. Verify environment variables and secrets

## Emergency Contacts

- **On-Call Engineer:** [Rotation schedule]
- **DevOps Team:** devops@example.com
- **Database Administrator:** dba@example.com
- **Security Team:** security@example.com

## Related Documentation

- [Architecture Overview](./architecture.md)
- [API Documentation](./api.md)
- [Security Guidelines](./security.md)
- [Development Guide](../README.md)
