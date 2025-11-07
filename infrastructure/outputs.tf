# Outputs for RapidPhotoUpload Infrastructure

# ===== Networking Outputs =====
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

# ===== Database Outputs =====
output "db_endpoint" {
  description = "RDS endpoint"
  value       = module.database.db_endpoint
  sensitive   = true
}

output "db_name" {
  description = "Database name"
  value       = module.database.db_name
}

output "db_secret_arn" {
  description = "ARN of database credentials secret"
  value       = module.database.db_secret_arn
}

# ===== Storage Outputs =====
output "s3_bucket_name" {
  description = "S3 bucket name for uploads"
  value       = module.storage.bucket_name
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = module.storage.bucket_arn
}

output "s3_bucket_domain_name" {
  description = "S3 bucket domain name"
  value       = module.storage.bucket_domain_name
}

# ===== Messaging Outputs =====
output "sqs_queue_url" {
  description = "SQS queue URL for image processing"
  value       = module.messaging.queue_url
}

output "sqs_queue_arn" {
  description = "SQS queue ARN"
  value       = module.messaging.queue_arn
}

output "sqs_dlq_url" {
  description = "SQS dead letter queue URL"
  value       = module.messaging.dlq_url
}

# ===== Compute Outputs =====
output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.compute.alb_dns_name
}

output "backend_api_endpoint" {
  description = "Backend API endpoint URL"
  value       = "http://${module.compute.alb_dns_name}"
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.compute.ecs_cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.compute.ecs_service_name
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.compute.lambda_function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = module.compute.lambda_function_arn
}

# ===== Observability Outputs =====
output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = module.observability.dashboard_name
}

output "xray_group_name" {
  description = "X-Ray group name"
  value       = module.observability.xray_group_name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = module.observability.sns_topic_arn
}

output "alarm_names" {
  description = "List of CloudWatch alarm names"
  value       = module.observability.alarm_names
}
