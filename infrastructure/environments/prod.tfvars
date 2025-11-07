# Production Environment Configuration

environment = "prod"
aws_region  = "us-east-1"

# Networking
vpc_cidr         = "10.0.0.0/16"
az_count         = 3 # Use 3 AZs for high availability
enable_flow_logs = true

# Database - production-grade RDS
db_instance_class           = "db.r6g.xlarge" # 4 vCPU, 32 GB RAM
db_allocated_storage        = 500
db_max_allocated_storage    = 2000
db_storage_iops             = 12000 # Higher IOPS for prod
db_max_connections          = 500
db_backup_retention_period  = 14 # 2 weeks retention
db_multi_az                 = true
db_deletion_protection      = true
db_skip_final_snapshot      = false
db_enable_performance_insights = true

# ECS - production configuration per PRD
ecs_task_cpu    = 1024 # 1 vCPU
ecs_task_memory = 2048 # 2 GB
ecs_min_capacity = 2
ecs_max_capacity = 10
alb_enable_deletion_protection = true
ecs_enable_exec = false # Disable in prod for security

# Lambda
lambda_reserved_concurrency = 100 # Full concurrency for prod

# Observability
create_sns_topic = true
alarm_email_endpoints = [
  # Add production team emails here
  # "devops@example.com",
  # "oncall@example.com"
]

# Alarm thresholds tuned for production
alarm_error_rate_threshold      = 5   # Stricter threshold
alarm_response_time_threshold   = 1.0 # 1 second p99
alarm_lambda_error_threshold    = 3
alarm_lambda_duration_threshold = 30000 # 30 seconds

# SQS configuration for production load
sqs_queue_depth_threshold   = 200
sqs_message_age_threshold   = 180 # 3 minutes

# Full feature set enabled in production
s3_enable_versioning = true
s3_enable_bucket_metrics = true
sqs_enable_detailed_logging = true

# CORS - restrict in production (update with actual domain)
cors_allowed_origins = [
  "https://rapid-photo.example.com",
  "https://www.rapid-photo.example.com"
]
