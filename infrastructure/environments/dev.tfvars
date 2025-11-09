# Dev Environment Configuration

environment = "dev"
aws_region  = "us-east-1"

# Networking
vpc_cidr         = "10.0.0.0/16"
az_count         = 2
enable_flow_logs = false # Disable in dev to save costs

# Database - smaller instance for dev
db_instance_class           = "db.t4g.small"
db_allocated_storage        = 20
db_max_allocated_storage    = 100
db_storage_iops             = null # Don't specify IOPS for small storage (<400 GB)
db_backup_retention_period  = 1  # Minimal backups in dev
db_multi_az                 = false # Single AZ in dev
db_deletion_protection      = false
db_skip_final_snapshot      = true # Skip snapshot in dev
db_enable_performance_insights = false

# ECS - smaller configuration for dev
ecs_task_cpu    = 512 # 0.5 vCPU
ecs_task_memory = 1024 # 1 GB
ecs_min_capacity = 1
ecs_max_capacity = 3
alb_enable_deletion_protection = false

# Lambda
lambda_reserved_concurrency = 10 # Lower concurrency for dev

# Observability
create_sns_topic = false # Disable SNS notifications in dev
alarm_email_endpoints = []

# Cost optimization for dev
s3_enable_versioning = false
s3_enable_bucket_metrics = false
sqs_enable_detailed_logging = false
