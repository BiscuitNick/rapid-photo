# Infrastructure Workspace

Terraform 1.9+ infrastructure as code for RapidPhotoUpload AWS deployment.

## Technology Stack
- Terraform 1.9+
- AWS Provider
- Modules for reusable components

## Platform Selection

This infrastructure supports **two backend platforms** via the `backend_platform` variable:

### ECS Platform (Original)
- **Cost**: ~$200-300/month
- **Compute**: ECS Fargate with auto-scaling (2-10 tasks)
- **Database**: Multi-AZ RDS PostgreSQL 17.6 (db.t4g.medium, 100GB)
- **Use case**: Production workloads requiring high availability and scaling

### Lightsail Platform (Cost-Optimized)
- **Cost**: ~$25-30/month (85-90% savings)
- **Compute**: Lightsail Container Service (micro power, 1 instance)
- **Database**: Lightsail PostgreSQL (micro_2_0 bundle)
- **Use case**: Demo environments, low-traffic applications

**Shared components** (used by both platforms):
- Lambda ARM64 for image processing
- S3 for photo storage
- SQS for event queuing
- CloudWatch for observability

To switch platforms:
```bash
terraform apply -var="backend_platform=lightsail"  # or "ecs"
```

## Networking Architecture

### Lightsail Platform Networking
- **No VPC peering required** for demo/dev environments
- Lightsail container service runs in isolated Lightsail VPC
- Database is publicly accessible (TLS enforced)
- Lambda accesses database via public endpoint
- Container accesses S3/SQS via AWS public APIs

**Communication paths:**
```
Web/Mobile → Lightsail Container (HTTPS) → Lightsail DB (TLS)
                ↓ (S3/SQS APIs)
             Lambda → S3 → SQS → Lightsail DB
```

**Production recommendations:**
- Enable VPC peering for private communication
- Restrict database public access
- Use AWS PrivateLink for S3/SQS access

### ECS Platform Networking
- VPC with public/private subnets
- ECS tasks in private subnets with NAT gateway
- RDS in private subnets (multi-AZ)
- Private communication via VPC

## Structure
- `modules/` - Reusable Terraform modules
  - `networking/` - VPC and subnets
  - `database/` - RDS PostgreSQL 17.6
  - `lightsail_database/` - Lightsail PostgreSQL
  - `compute/` - ECS Fargate
  - `lightsail_compute/` - Lightsail Container Service
  - `storage/` - S3 buckets
  - `messaging/` - SQS queues
  - `lambda/` - Lambda functions
  - `observability/` - CloudWatch, X-Ray
- `environments/` - Environment-specific configurations (dev, prod)

## AWS Resources

### Platform-Conditional Resources
**ECS Platform:**
- VPC with public/private subnets
- Multi-AZ RDS PostgreSQL 17.6 (db.t4g.medium)
- ECS Fargate service with ALB
- NAT Gateway

**Lightsail Platform:**
- Lightsail Container Service (micro)
- Lightsail PostgreSQL (micro_2_0)
- Static IP with TLS
- IAM user for AWS API access

### Shared Resources
- S3 with lifecycle policies
- SQS with DLQ
- Lambda (ARM64)
- CloudWatch dashboards and alarms
- X-Ray tracing
- Secrets Manager
