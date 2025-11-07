# RapidPhotoUpload Infrastructure - Main Terraform Configuration
# This is the entry point for the infrastructure setup

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Backend configuration for remote state
  # Uncomment and configure for production use
  # backend "s3" {
  #   bucket         = "rapid-photo-terraform-state"
  #   key            = "terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "rapid-photo-terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "RapidPhotoUpload"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Data source for AWS account ID
data "aws_caller_identity" "current" {}

# ===== Networking Module =====
module "networking" {
  source = "./modules/networking"

  project_name     = var.project_name
  environment      = var.environment
  vpc_cidr         = var.vpc_cidr
  az_count         = var.az_count
  enable_flow_logs = var.enable_flow_logs
}

# ===== Messaging Module (must be created before storage for S3 notifications) =====
module "messaging" {
  source = "./modules/messaging"

  project_name = var.project_name
  environment  = var.environment

  visibility_timeout      = var.sqs_visibility_timeout
  message_retention       = var.sqs_message_retention
  max_receive_count       = var.sqs_max_receive_count
  queue_depth_threshold   = var.sqs_queue_depth_threshold
  message_age_threshold   = var.sqs_message_age_threshold
  enable_detailed_logging = var.sqs_enable_detailed_logging
}

# ===== Storage Module =====
module "storage" {
  source = "./modules/storage"

  project_name   = var.project_name
  environment    = var.environment
  bucket_suffix  = data.aws_caller_identity.current.account_id
  sqs_queue_arn  = module.messaging.queue_arn
  allowed_origins = var.cors_allowed_origins

  enable_versioning             = var.s3_enable_versioning
  enable_bucket_metrics         = var.s3_enable_bucket_metrics
  bucket_size_alarm_threshold   = var.s3_bucket_size_alarm_threshold
  object_count_alarm_threshold  = var.s3_object_count_alarm_threshold

  depends_on = [module.messaging]
}

# ===== Database Module =====
module "database" {
  source = "./modules/database"

  project_name       = var.project_name
  environment        = var.environment
  private_subnet_ids = module.networking.private_subnet_ids
  security_group_id  = module.networking.rds_security_group_id

  db_name                     = var.db_name
  db_username                 = var.db_username
  db_instance_class           = var.db_instance_class
  allocated_storage           = var.db_allocated_storage
  max_allocated_storage       = var.db_max_allocated_storage
  storage_iops                = var.db_storage_iops
  max_connections             = var.db_max_connections
  backup_retention_period     = var.db_backup_retention_period
  multi_az                    = var.db_multi_az
  deletion_protection         = var.db_deletion_protection
  skip_final_snapshot         = var.db_skip_final_snapshot
  enable_performance_insights = var.db_enable_performance_insights
}

# ===== Compute Module =====
module "compute" {
  source = "./modules/compute"

  project_name              = var.project_name
  environment               = var.environment
  aws_region                = var.aws_region
  vpc_id                    = module.networking.vpc_id
  private_subnet_ids        = module.networking.private_subnet_ids
  alb_subnet_ids            = module.networking.public_subnet_ids
  alb_security_group_id     = module.networking.alb_security_group_id
  ecs_security_group_id     = module.networking.ecs_security_group_id
  lambda_security_group_id  = module.networking.lambda_security_group_id

  # ECS Configuration
  backend_docker_image      = var.backend_docker_image
  task_cpu                  = var.ecs_task_cpu
  task_memory               = var.ecs_task_memory
  min_capacity              = var.ecs_min_capacity
  max_capacity              = var.ecs_max_capacity
  enable_deletion_protection = var.alb_enable_deletion_protection
  enable_ecs_exec           = var.ecs_enable_exec

  # Lambda Configuration
  lambda_package_path        = var.lambda_package_path
  lambda_reserved_concurrency = var.lambda_reserved_concurrency

  # Integration
  s3_bucket_name  = module.storage.bucket_name
  sqs_queue_url   = module.messaging.queue_url
  sqs_queue_arn   = module.messaging.queue_arn
  db_secret_arn   = module.database.db_secret_arn

  depends_on = [module.networking, module.storage, module.messaging, module.database]
}

# ===== Observability Module =====
module "observability" {
  source = "./modules/observability"

  project_name         = var.project_name
  environment          = var.environment
  aws_region           = var.aws_region
  ecs_cluster_name     = module.compute.ecs_cluster_name
  ecs_service_name     = module.compute.ecs_service_name
  lambda_function_name = module.compute.lambda_function_name
  alb_arn_suffix       = split("/", module.compute.alb_arn)[1]

  # Alarm Configuration
  error_rate_threshold       = var.alarm_error_rate_threshold
  response_time_threshold    = var.alarm_response_time_threshold
  lambda_error_threshold     = var.alarm_lambda_error_threshold
  lambda_duration_threshold  = var.alarm_lambda_duration_threshold

  # SNS Configuration
  create_sns_topic      = var.create_sns_topic
  alarm_email_endpoints = var.alarm_email_endpoints

  depends_on = [module.compute]
}
