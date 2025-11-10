# Variables for Lightsail Compute Module

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

variable "container_power" {
  description = "Container service power (nano, micro, small, medium, large, xlarge)"
  type        = string
  default     = "micro"
  validation {
    condition     = contains(["nano", "micro", "small", "medium", "large", "xlarge"], var.container_power)
    error_message = "Container power must be one of: nano, micro, small, medium, large, xlarge"
  }
}

variable "container_scale" {
  description = "Number of container instances (1-20)"
  type        = number
  default     = 1
  validation {
    condition     = var.container_scale >= 1 && var.container_scale <= 20
    error_message = "Container scale must be between 1 and 20"
  }
}

variable "backend_docker_image" {
  description = "Docker image for backend container"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for uploads"
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

variable "lambda_secret" {
  description = "Shared secret for Lambda->Backend authentication"
  type        = string
  sensitive   = true
}

variable "cognito_issuer_uri" {
  description = "Cognito issuer URI for authentication"
  type        = string
}

variable "cognito_jwk_set_uri" {
  description = "Cognito JWK set URI"
  type        = string
}

variable "db_host" {
  description = "Database host from Lightsail database"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = string
  default     = "5432"
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Custom domain name for TLS certificate (optional)"
  type        = string
  default     = ""
}

variable "subject_alternative_names" {
  description = "Subject alternative names for TLS certificate"
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for DNS record (optional)"
  type        = string
  default     = ""
}
