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

# Networking Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Database Variables
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.medium"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "rapidphoto"
}

# Storage Variables
variable "s3_bucket_name" {
  description = "S3 bucket name for photo uploads"
  type        = string
  default     = ""
}

# Compute Variables
variable "backend_docker_image" {
  description = "Docker image for backend ECS service"
  type        = string
  default     = ""
}

variable "lambda_package_path" {
  description = "Path to Lambda deployment package"
  type        = string
  default     = "../lambda/dist/lambda.zip"
}

variable "ecs_task_cpu" {
  description = "ECS task CPU units"
  type        = number
  default     = 1024
}

variable "ecs_task_memory" {
  description = "ECS task memory (MB)"
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
