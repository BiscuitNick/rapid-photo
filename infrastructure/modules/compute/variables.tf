# Variables for Compute Module

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS and Lambda"
  type        = list(string)
}

variable "alb_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "lambda_security_group_id" {
  description = "Security group ID for Lambda"
  type        = string
}

# ECS Variables
variable "backend_docker_image" {
  description = "Docker image for backend service"
  type        = string
}

variable "task_cpu" {
  description = "ECS task CPU units (1024 = 1 vCPU)"
  type        = number
  default     = 1024
}

variable "task_memory" {
  description = "ECS task memory in MB"
  type        = number
  default     = 2048
}

variable "min_capacity" {
  description = "Minimum number of ECS tasks"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of ECS tasks"
  type        = number
  default     = 10
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

variable "enable_ecs_exec" {
  description = "Enable ECS Exec for debugging"
  type        = bool
  default     = true
}

# Lambda Variables
variable "lambda_package_path" {
  description = "Path to Lambda deployment package"
  type        = string
}

variable "lambda_reserved_concurrency" {
  description = "Reserved concurrent executions for Lambda"
  type        = number
  default     = 100
}

variable "backend_url" {
  description = "Backend API URL for Lambda callbacks"
  type        = string
}

variable "lambda_secret" {
  description = "Shared secret for Lambda->Backend authentication"
  type        = string
  sensitive   = true
}

# Integration Variables
variable "s3_bucket_name" {
  description = "S3 bucket name for photo storage"
  type        = string
}

variable "sqs_queue_url" {
  description = "SQS queue URL"
  type        = string
}

variable "sqs_queue_arn" {
  description = "SQS queue ARN"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of database credentials secret"
  type        = string
}
