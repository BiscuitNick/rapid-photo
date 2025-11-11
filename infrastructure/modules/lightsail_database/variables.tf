# Variables for Lightsail Database Module

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "db_name" {
  description = "Master database name"
  type        = string
}

variable "db_username" {
  description = "Master username"
  type        = string
}

variable "database_blueprint_id" {
  description = "Database blueprint ID (postgres_15, postgres_16, etc.)"
  type        = string
  default     = "postgres_15"
}

variable "database_bundle_id" {
  description = "Database bundle ID (micro_2_0, small_2_0, medium_2_0, large_2_0, xlarge_2_0)"
  type        = string
  default     = "micro_2_0"
  validation {
    condition     = contains(["micro_2_0", "small_2_0", "medium_2_0", "large_2_0", "xlarge_2_0"], var.database_bundle_id)
    error_message = "Database bundle must be one of: micro_2_0, small_2_0, medium_2_0, large_2_0, xlarge_2_0"
  }
}

variable "availability_zone" {
  description = "Availability zone for the database (optional)"
  type        = string
  default     = null
}

variable "publicly_accessible" {
  description = "Whether the database should be publicly accessible"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion (dev/demo only)"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Apply changes immediately instead of during maintenance window"
  type        = bool
  default     = false
}

variable "max_connections_threshold" {
  description = "CloudWatch alarm threshold for database connections"
  type        = number
  default     = 40 # Adjust based on bundle size
}

variable "free_storage_threshold_bytes" {
  description = "CloudWatch alarm threshold for free storage in bytes"
  type        = number
  default     = 2147483648 # 2 GB
}
