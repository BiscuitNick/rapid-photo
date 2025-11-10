# Outputs for RapidPhotoUpload Infrastructure

# ===== Platform Information =====
output "backend_platform" {
  description = "Active backend platform (ecs or lightsail)"
  value       = var.backend_platform
}

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

# ===== Database Outputs (Platform-aware) =====
output "db_endpoint" {
  description = "Database endpoint"
  value       = var.backend_platform == "ecs" ? module.database[0].db_endpoint : module.lightsail_database[0].master_endpoint_address
  sensitive   = true
}

output "db_name" {
  description = "Database name"
  value       = var.backend_platform == "ecs" ? module.database[0].db_name : module.lightsail_database[0].master_database_name
}

output "db_secret_arn" {
  description = "ARN of database credentials secret"
  value       = var.backend_platform == "ecs" ? module.database[0].db_secret_arn : module.lightsail_database[0].db_secret_arn
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

# ===== Compute Outputs (Platform-aware) =====
output "backend_api_endpoint" {
  description = "Backend API endpoint URL"
  value       = var.backend_platform == "ecs" ? "http://${module.compute[0].alb_dns_name}" : module.lightsail_compute[0].backend_endpoint
}

output "backend_dns_name" {
  description = "Backend DNS name or URL"
  value       = var.backend_platform == "ecs" ? module.compute[0].alb_dns_name : module.lightsail_compute[0].container_service_url
}

# ECS-specific outputs (only when using ECS platform)
output "alb_dns_name" {
  description = "Application Load Balancer DNS name (ECS only)"
  value       = var.backend_platform == "ecs" ? module.compute[0].alb_dns_name : null
}

output "ecs_cluster_name" {
  description = "ECS cluster name (ECS only)"
  value       = var.backend_platform == "ecs" ? module.compute[0].ecs_cluster_name : null
}

output "ecs_service_name" {
  description = "ECS service name (ECS only)"
  value       = var.backend_platform == "ecs" ? module.compute[0].ecs_service_name : null
}

# Lightsail-specific outputs (only when using Lightsail platform)
output "lightsail_container_service_name" {
  description = "Lightsail container service name (Lightsail only)"
  value       = var.backend_platform == "lightsail" ? module.lightsail_compute[0].container_service_name : null
}

output "lightsail_static_ip" {
  description = "Lightsail static IP address (Lightsail only)"
  value       = var.backend_platform == "lightsail" ? module.lightsail_compute[0].static_ip_address : null
}

output "lightsail_iam_user_name" {
  description = "IAM user name for Lightsail container (Lightsail only)"
  value       = var.backend_platform == "lightsail" ? module.lightsail_compute[0].iam_user_name : null
}

output "lightsail_credentials_secret_arn" {
  description = "Secrets Manager ARN for Lightsail credentials (Lightsail only)"
  value       = var.backend_platform == "lightsail" ? module.lightsail_compute[0].credentials_secret_arn : null
}

# ===== Lambda Outputs (Shared across platforms) =====
output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.image_processor.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.image_processor.arn
}

# ===== Observability Outputs (ECS platform only) =====
output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name (ECS only)"
  value       = var.backend_platform == "ecs" ? module.observability[0].dashboard_name : null
}

output "xray_group_name" {
  description = "X-Ray group name (ECS only)"
  value       = var.backend_platform == "ecs" ? module.observability[0].xray_group_name : null
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alarms (ECS only)"
  value       = var.backend_platform == "ecs" ? module.observability[0].sns_topic_arn : null
}

output "alarm_names" {
  description = "List of CloudWatch alarm names (ECS only)"
  value       = var.backend_platform == "ecs" ? module.observability[0].alarm_names : null
}
