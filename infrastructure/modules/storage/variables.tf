# Variables for Storage Module

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "bucket_suffix" {
  description = "Unique suffix for bucket name (e.g., account ID)"
  type        = string
}

variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "allowed_origins" {
  description = "List of allowed CORS origins"
  type        = list(string)
  default     = ["*"]
}

variable "sqs_queue_arn" {
  description = "ARN of SQS queue for S3 event notifications"
  type        = string
}

variable "enable_bucket_metrics" {
  description = "Enable CloudWatch metrics for bucket"
  type        = bool
  default     = true
}

variable "bucket_size_alarm_threshold" {
  description = "Threshold in bytes for bucket size alarm"
  type        = number
  default     = 1099511627776 # 1 TB
}

variable "object_count_alarm_threshold" {
  description = "Threshold for object count alarm"
  type        = number
  default     = 1000000 # 1 million objects
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}
