# Variables for Observability Module

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

# Resource References
variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name"
  type        = string
}

variable "lambda_function_name" {
  description = "Lambda function name"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch metrics"
  type        = string
}

# Alarm Thresholds
variable "error_rate_threshold" {
  description = "Threshold for 5XX error count alarm"
  type        = number
  default     = 10
}

variable "response_time_threshold" {
  description = "Threshold for p99 response time in seconds"
  type        = number
  default     = 2.0
}

variable "lambda_error_threshold" {
  description = "Threshold for Lambda error count"
  type        = number
  default     = 5
}

variable "lambda_duration_threshold" {
  description = "Threshold for Lambda p95 duration in milliseconds"
  type        = number
  default     = 60000 # 60 seconds
}

# SNS Configuration
variable "create_sns_topic" {
  description = "Create SNS topic for alarms"
  type        = bool
  default     = true
}

variable "alarm_email_endpoints" {
  description = "Email addresses to receive alarm notifications"
  type        = list(string)
  default     = []
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarms trigger"
  type        = list(string)
  default     = []
}
