# Infrastructure Workspace

Terraform 1.9+ infrastructure as code for RapidPhotoUpload AWS deployment.

## Technology Stack
- Terraform 1.9+
- AWS Provider
- Modules for reusable components

## Structure
- `modules/` - Reusable Terraform modules
  - VPC and networking
  - RDS PostgreSQL 17.6
  - S3 buckets
  - SQS queues
  - ECS Fargate
  - Lambda
  - CloudFront (optional)
- `environments/` - Environment-specific configurations (dev, prod)

## AWS Resources
- VPC with public/private subnets
- RDS PostgreSQL 17.6
- S3 with lifecycle policies
- SQS with DLQ
- ECS Fargate service
- Lambda (ARM64)
- CloudWatch dashboards and alarms
- X-Ray tracing
