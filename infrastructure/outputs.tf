# Outputs for RapidPhotoUpload Infrastructure

# Networking Outputs
# output "vpc_id" {
#   description = "VPC ID"
#   value       = module.networking.vpc_id
# }

# output "private_subnet_ids" {
#   description = "Private subnet IDs"
#   value       = module.networking.private_subnet_ids
# }

# output "public_subnet_ids" {
#   description = "Public subnet IDs"
#   value       = module.networking.public_subnet_ids
# }

# Database Outputs
# output "db_endpoint" {
#   description = "RDS endpoint"
#   value       = module.database.db_endpoint
#   sensitive   = true
# }

# output "db_name" {
#   description = "Database name"
#   value       = module.database.db_name
# }

# Storage Outputs
# output "s3_bucket_name" {
#   description = "S3 bucket name for uploads"
#   value       = module.storage.bucket_name
# }

# output "s3_bucket_arn" {
#   description = "S3 bucket ARN"
#   value       = module.storage.bucket_arn
# }

# Messaging Outputs
# output "sqs_queue_url" {
#   description = "SQS queue URL for image processing"
#   value       = module.messaging.queue_url
# }

# output "sqs_queue_arn" {
#   description = "SQS queue ARN"
#   value       = module.messaging.queue_arn
# }

# Compute Outputs
# output "alb_dns_name" {
#   description = "Application Load Balancer DNS name"
#   value       = module.compute.alb_dns_name
# }

# output "backend_api_endpoint" {
#   description = "Backend API endpoint URL"
#   value       = "https://${module.compute.alb_dns_name}"
# }

# output "lambda_function_name" {
#   description = "Lambda function name"
#   value       = module.compute.lambda_function_name
# }
