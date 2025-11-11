# Production Deployment Guide

## Overview

This guide outlines the process for deploying the Rapid Photo application to production using AWS Lightsail, following the same successful pattern used for the development environment.

## Prerequisites

- [ ] All development testing completed successfully
- [ ] Mobile and web apps tested with Lightsail dev environment
- [ ] CloudWatch monitoring reviewed for at least 3-5 days
- [ ] Performance metrics within acceptable ranges (CPU < 80%, Memory < 80%)
- [ ] No critical bugs or issues in dev environment

## Pre-Production Checklist

### 1. Configuration Review

- [ ] Review all environment variables for production
- [ ] Update `LAMBDA_SECRET` to a strong production secret
- [ ] Verify Cognito user pool configuration for production
- [ ] Update CORS allowed origins to include production domains
- [ ] Review database password strength
- [ ] Verify S3 bucket names for production
- [ ] Update SQS queue names for production

### 2. Infrastructure Preparation

- [ ] Create production Cognito user pool (or use existing)
- [ ] Create production S3 bucket
- [ ] Create production SQS queue
- [ ] Create production Lambda function
- [ ] Create production Lightsail database
- [ ] Create production Lightsail container service

### 3. Security Hardening

- [ ] Rotate all secrets and passwords
- [ ] Enable MFA for production Cognito users
- [ ] Review IAM policies for least privilege
- [ ] Enable AWS CloudTrail for audit logging
- [ ] Configure security group rules
- [ ] Enable S3 bucket encryption
- [ ] Review database security settings

## Deployment Steps

### Step 1: Create Production Infrastructure

```bash
# Set production environment variables
export ENV=prod
export AWS_REGION=us-east-1

# Create Lightsail database (similar to dev)
aws lightsail create-relational-database \
  --relational-database-name rapid-photo-prod-db \
  --relational-database-blueprint-id postgres_17 \
  --relational-database-bundle-id micro_2_0 \
  --master-database-name rapidphoto \
  --master-username rapidphoto_admin \
  --master-user-password "STRONG_PASSWORD_HERE" \
  --publicly-accessible \
  --region $AWS_REGION

# Create Lightsail container service
aws lightsail create-container-service \
  --service-name rapid-photo-prod-backend \
  --power micro \
  --scale 1 \
  --tags key=Environment,value=prod key=Project,value=RapidPhotoUpload \
  --region $AWS_REGION
```

### Step 2: Build and Push Docker Image

```bash
# Build the backend application
cd backend
./gradlew clean build -x test

# Build Docker image
docker build -t rapid-photo-prod-backend:latest .

# Push to Lightsail
aws lightsail push-container-image \
  --service-name rapid-photo-prod-backend \
  --label backend \
  --image rapid-photo-prod-backend:latest \
  --region $AWS_REGION
```

### Step 3: Deploy Container

```bash
# Get the pushed image tag
IMAGE_TAG=$(aws lightsail get-container-images \
  --service-name rapid-photo-prod-backend \
  --region $AWS_REGION | jq -r '.containerImages[0].image')

# Create deployment configuration (update with production values)
cat > deployment-prod.json <<EOF
{
  "containers": {
    "backend": {
      "image": "$IMAGE_TAG",
      "environment": {
        "SPRING_PROFILES_ACTIVE": "lightsail",
        "DB_HOST": "PROD_DB_HOST",
        "DB_PORT": "5432",
        "DB_NAME": "rapidphoto",
        "DB_USERNAME": "rapidphoto_admin",
        "DB_PASSWORD": "PROD_DB_PASSWORD",
        "AWS_REGION": "us-east-1",
        "AWS_ACCESS_KEY_ID": "PROD_ACCESS_KEY",
        "AWS_SECRET_ACCESS_KEY": "PROD_SECRET_KEY",
        "S3_BUCKET_NAME": "rapid-photo-prod-photos",
        "SQS_QUEUE_URL": "PROD_SQS_QUEUE_URL",
        "LAMBDA_SECRET": "PROD_LAMBDA_SECRET",
        "COGNITO_ISSUER_URI": "PROD_COGNITO_ISSUER_URI",
        "COGNITO_JWK_SET_URI": "PROD_COGNITO_JWK_SET_URI",
        "CLOUDWATCH_ENABLED": "true",
        "CLOUDWATCH_NAMESPACE": "RapidPhoto-Prod"
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

# Deploy to Lightsail
aws lightsail create-container-service-deployment \
  --service-name rapid-photo-prod-backend \
  --cli-input-json file://deployment-prod.json \
  --region $AWS_REGION
```

### Step 4: Update Frontend Configuration

#### Mobile App (Flutter)

Update `mobile/lib/config/api_config.dart`:
```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://rapid-photo-prod-backend.XXXXXXXXXX.us-east-1.cs.amazonlightsail.com',
);
```

Build and release:
```bash
cd mobile
flutter build apk --release  # For Android
flutter build ios --release  # For iOS
```

#### Web App (React)

Update `web/.env.production`:
```bash
VITE_API_BASE_URL=https://rapid-photo-prod-backend.XXXXXXXXXX.us-east-1.cs.amazonlightsail.com
VITE_COGNITO_USER_POOL_ID=PROD_USER_POOL_ID
VITE_COGNITO_CLIENT_ID=PROD_CLIENT_ID
VITE_COGNITO_IDENTITY_POOL_ID=PROD_IDENTITY_POOL_ID
VITE_AWS_REGION=us-east-1
VITE_S3_BUCKET_NAME=rapid-photo-prod-photos
```

Build and deploy:
```bash
cd web
npm run build
# Deploy to hosting platform (S3, Netlify, Vercel, etc.)
```

### Step 5: Deploy Lambda Image Processor

```bash
cd lambda

# Build Lambda package
./build-lambda-package.sh

# Update Lambda function
aws lambda update-function-code \
  --function-name rapid-photo-prod-image-processor \
  --zip-file fileb://lambda-package.zip \
  --region $AWS_REGION

# Update environment variables
aws lambda update-function-configuration \
  --function-name rapid-photo-prod-image-processor \
  --environment "Variables={
    DB_HOST=PROD_DB_HOST,
    DB_NAME=rapidphoto,
    DB_USER=rapidphoto_admin,
    DB_PASSWORD=PROD_DB_PASSWORD,
    S3_BUCKET=rapid-photo-prod-photos,
    LAMBDA_SECRET=PROD_LAMBDA_SECRET,
    BACKEND_URL=https://rapid-photo-prod-backend.XXXXXXXXXX.us-east-1.cs.amazonlightsail.com
  }" \
  --region $AWS_REGION
```

## Post-Deployment Verification

### 1. Health Checks

```bash
# Test health endpoint
curl https://rapid-photo-prod-backend.XXXXXXXXXX.us-east-1.cs.amazonlightsail.com/actuator/health

# Expected: {"status":"UP"}
```

### 2. API Endpoint Testing

```bash
# Run test script (update URL first)
./test-lightsail-api.sh
```

### 3. End-to-End Testing

- [ ] User registration and login via mobile app
- [ ] Photo upload via mobile app
- [ ] Photo upload via web app
- [ ] Lambda processing completes successfully
- [ ] Gallery displays processed photos
- [ ] Photo download works
- [ ] Photo search works
- [ ] Photo deletion works

### 4. Performance Testing

- [ ] Load test with 100 concurrent uploads
- [ ] Verify CloudWatch metrics are being exported
- [ ] Check database connection pool usage
- [ ] Monitor memory and CPU usage under load

## Monitoring Setup

### CloudWatch Alarms

```bash
# CPU alarm
aws cloudwatch put-metric-alarm \
  --alarm-name rapid-photo-prod-high-cpu \
  --alarm-description "Production CPU > 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/Lightsail \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:us-east-1:ACCOUNT_ID:production-alerts

# Error rate alarm
aws cloudwatch put-metric-alarm \
  --alarm-name rapid-photo-prod-high-errors \
  --alarm-description "Production error rate > 5%" \
  --metric-name http.server.requests \
  --namespace RapidPhoto-Prod \
  --statistic Sum \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:us-east-1:ACCOUNT_ID:production-alerts
```

### Logging

- Enable CloudWatch Logs for all services
- Set up log aggregation and analysis
- Configure log retention policies (30-90 days for production)

## Rollback Plan

If issues occur in production:

### Quick Rollback

```bash
# Revert to previous container deployment
aws lightsail get-container-service-deployments \
  --service-name rapid-photo-prod-backend \
  --region $AWS_REGION

# Get previous deployment version number
PREVIOUS_VERSION=<VERSION_NUMBER>

# Create new deployment with previous version
aws lightsail create-container-service-deployment \
  --service-name rapid-photo-prod-backend \
  --containers file://previous-deployment.json \
  --region $AWS_REGION
```

### Database Rollback

- Restore from automated RDS snapshot
- Verify data integrity after restore

## Scaling Considerations

### Vertical Scaling (Upgrade Container Power)

```bash
# Upgrade to nano (512 MB RAM, 0.25 vCPU)
aws lightsail update-container-service \
  --service-name rapid-photo-prod-backend \
  --power nano \
  --region $AWS_REGION

# Or small (2 GB RAM, 1 vCPU)
aws lightsail update-container-service \
  --service-name rapid-photo-prod-backend \
  --power small \
  --region $AWS_REGION
```

### Horizontal Scaling

```bash
# Scale to 2 containers
aws lightsail update-container-service \
  --service-name rapid-photo-prod-backend \
  --scale 2 \
  --region $AWS_REGION
```

## Cost Monitoring

- Set up AWS Cost Explorer alerts
- Monitor Lightsail container service costs
- Track S3 storage costs
- Monitor Lambda invocation costs
- Review database instance costs

## Maintenance Windows

- Schedule regular database backups
- Plan for dependency updates (Spring Boot, Flutter, etc.)
- Review security patches monthly
- Update SSL/TLS certificates as needed

## Support and Contacts

- AWS Support: [link to support]
- On-call rotation: [link to PagerDuty/etc]
- Runbook: [link to runbook]

## Additional Resources

- Development environment: https://rapid-photo-dev-backend.51qxcte01q11c.us-east-1.cs.amazonlightsail.com
- Monitoring guide: LIGHTSAIL_MONITORING.md
- API test script: test-lightsail-api.sh
- Architecture docs: [link to architecture]
