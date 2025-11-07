# Variables for Messaging Module

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "visibility_timeout" {
  description = "SQS visibility timeout in seconds (should match Lambda timeout + buffer)"
  type        = number
  default     = 900 # 15 minutes
}

variable "message_retention" {
  description = "Message retention period in seconds"
  type        = number
  default     = 345600 # 4 days
}

variable "max_receive_count" {
  description = "Max receives before sending to DLQ"
  type        = number
  default     = 3
}

variable "queue_depth_threshold" {
  description = "Threshold for queue depth alarm"
  type        = number
  default     = 100
}

variable "message_age_threshold" {
  description = "Threshold in seconds for message age alarm"
  type        = number
  default     = 300 # 5 minutes
}

variable "enable_detailed_logging" {
  description = "Enable detailed logging for queue"
  type        = bool
  default     = false
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}
