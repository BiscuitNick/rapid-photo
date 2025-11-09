# Global Variables for RapidPhotoUpload Infrastructure

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "rapid-photo"
}

# ===== Networking Variables =====
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs"
  type        = bool
  default     = true
}

# ===== Database Variables =====
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "rapidphoto"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "rapidphoto_admin"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.medium"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 100
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for autoscaling in GB"
  type        = number
  default     = 500
}

variable "db_storage_iops" {
  description = "IOPS for gp3 storage (null to use default, requires >= 400 GB to customize)"
  type        = number
  default     = null
}

variable "db_max_connections" {
  description = "Maximum database connections"
  type        = number
  default     = 200
}

variable "db_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "db_multi_az" {
  description = "Enable multi-AZ deployment"
  type        = bool
  default     = true
}

variable "db_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot on deletion (dev only)"
  type        = bool
  default     = false
}

variable "db_enable_performance_insights" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

# ===== Storage (S3) Variables =====
variable "s3_enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "cors_allowed_origins" {
  description = "Allowed CORS origins"
  type        = list(string)
  default     = ["*"]
}

variable "s3_enable_bucket_metrics" {
  description = "Enable CloudWatch metrics for bucket"
  type        = bool
  default     = true
}

variable "s3_bucket_size_alarm_threshold" {
  description = "Bucket size alarm threshold in bytes"
  type        = number
  default     = 1099511627776 # 1 TB
}

variable "s3_object_count_alarm_threshold" {
  description = "Object count alarm threshold"
  type        = number
  default     = 1000000
}

# ===== Messaging (SQS) Variables =====
variable "sqs_visibility_timeout" {
  description = "SQS visibility timeout in seconds"
  type        = number
  default     = 900
}

variable "sqs_message_retention" {
  description = "Message retention period in seconds"
  type        = number
  default     = 345600 # 4 days
}

variable "sqs_max_receive_count" {
  description = "Max receives before sending to DLQ"
  type        = number
  default     = 3
}

variable "sqs_queue_depth_threshold" {
  description = "Queue depth alarm threshold"
  type        = number
  default     = 100
}

variable "sqs_message_age_threshold" {
  description = "Message age alarm threshold in seconds"
  type        = number
  default     = 300
}

variable "sqs_enable_detailed_logging" {
  description = "Enable detailed logging for queue"
  type        = bool
  default     = false
}

# ===== ECS Compute Variables =====
variable "backend_docker_image" {
  description = "Docker image for backend ECS service"
  type        = string
  default     = "nginx:latest" # Placeholder
}

variable "ecs_task_cpu" {
  description = "ECS task CPU units (1024 = 1 vCPU)"
  type        = number
  default     = 1024
}

variable "ecs_task_memory" {
  description = "ECS task memory in MB"
  type        = number
  default     = 2048
}

variable "ecs_min_capacity" {
  description = "Minimum number of ECS tasks"
  type        = number
  default     = 2
}

variable "ecs_max_capacity" {
  description = "Maximum number of ECS tasks"
  type        = number
  default     = 10
}

variable "alb_enable_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

variable "ecs_enable_exec" {
  description = "Enable ECS Exec for debugging"
  type        = bool
  default     = true
}

# ===== Lambda Variables =====
variable "lambda_package_path" {
  description = "Path to Lambda deployment package"
  type        = string
  default     = "../lambda/lambda-package.zip"
}

variable "lambda_reserved_concurrency" {
  description = "Reserved concurrent executions for Lambda"
  type        = number
  default     = 100
}

variable "lambda_secret" {
  description = "Shared secret for Lambda->Backend authentication"
  type        = string
  sensitive   = true
  default     = "rapid-photo-lambda-secret-change-in-production"
}

# ===== Observability Variables =====
variable "alarm_error_rate_threshold" {
  description = "Threshold for 5XX error count alarm"
  type        = number
  default     = 10
}

variable "alarm_response_time_threshold" {
  description = "Threshold for p99 response time in seconds"
  type        = number
  default     = 2.0
}

variable "alarm_lambda_error_threshold" {
  description = "Threshold for Lambda error count"
  type        = number
  default     = 5
}

variable "alarm_lambda_duration_threshold" {
  description = "Threshold for Lambda p95 duration in milliseconds"
  type        = number
  default     = 60000
}

variable "create_sns_topic" {
  description = "Create SNS topic for alarms"
  type        = bool
  default     = true
}

variable "alarm_email_endpoints" {
  description = "Email addresses for alarm notifications"
  type        = list(string)
  default     = []
}
