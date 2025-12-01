# RapidPhotoUpload Infrastructure - Main Terraform Configuration
# This is the entry point for the infrastructure setup

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.23"
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

  project_name    = var.project_name
  environment     = var.environment
  bucket_suffix   = data.aws_caller_identity.current.account_id
  sqs_queue_arn   = module.messaging.queue_arn
  allowed_origins = var.cors_allowed_origins

  enable_versioning            = var.s3_enable_versioning
  enable_bucket_metrics        = var.s3_enable_bucket_metrics
  bucket_size_alarm_threshold  = var.s3_bucket_size_alarm_threshold
  object_count_alarm_threshold = var.s3_object_count_alarm_threshold

  depends_on = [module.messaging]
}

# ===== Database Module (ECS Platform) =====
module "database" {
  count  = var.backend_platform == "ecs" ? 1 : 0
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

# ===== Lightsail Database Module (Lightsail Platform) =====
module "lightsail_database" {
  count  = var.backend_platform == "lightsail" ? 1 : 0
  source = "./modules/lightsail_database"

  project_name          = var.project_name
  environment           = var.environment
  db_name               = var.db_name
  db_username           = var.db_username
  database_blueprint_id = var.lightsail_database_blueprint_id
  database_bundle_id    = var.lightsail_database_bundle_id
  publicly_accessible   = var.lightsail_db_publicly_accessible
  skip_final_snapshot   = var.db_skip_final_snapshot
  apply_immediately     = false
}

# ===== Compute Module (ECS Platform) =====
module "compute" {
  count  = var.backend_platform == "ecs" ? 1 : 0
  source = "./modules/compute"

  project_name             = var.project_name
  environment              = var.environment
  aws_region               = var.aws_region
  vpc_id                   = module.networking.vpc_id
  private_subnet_ids       = module.networking.private_subnet_ids
  alb_subnet_ids           = module.networking.public_subnet_ids
  alb_security_group_id    = module.networking.alb_security_group_id
  ecs_security_group_id    = module.networking.ecs_security_group_id
  lambda_security_group_id = module.networking.lambda_security_group_id

  # ECS Configuration
  backend_docker_image       = var.backend_docker_image
  task_cpu                   = var.ecs_task_cpu
  task_memory                = var.ecs_task_memory
  min_capacity               = var.ecs_min_capacity
  max_capacity               = var.ecs_max_capacity
  enable_deletion_protection = var.alb_enable_deletion_protection
  enable_ecs_exec            = var.ecs_enable_exec

  # Lambda Configuration
  lambda_package_path         = var.lambda_package_path
  lambda_reserved_concurrency = var.lambda_reserved_concurrency
  backend_url                 = "http://${module.compute[0].alb_dns_name}"
  lambda_secret               = var.lambda_secret

  # Integration
  s3_bucket_name = module.storage.bucket_name
  sqs_queue_url  = module.messaging.queue_url
  sqs_queue_arn  = module.messaging.queue_arn
  db_secret_arn  = module.database[0].db_secret_arn

  depends_on = [module.networking, module.storage, module.messaging, module.database]
}

# ===== Lightsail Compute Module (Lightsail Platform) =====
module "lightsail_compute" {
  count  = var.backend_platform == "lightsail" ? 1 : 0
  source = "./modules/lightsail_compute"

  project_name         = var.project_name
  environment          = var.environment
  aws_region           = var.aws_region
  container_power      = var.lightsail_container_power
  container_scale      = var.lightsail_container_scale
  backend_docker_image = var.backend_docker_image

  # Integration
  s3_bucket_name      = module.storage.bucket_name
  sqs_queue_url       = module.messaging.queue_url
  sqs_queue_arn       = module.messaging.queue_arn
  lambda_secret       = var.lambda_secret
  cognito_issuer_uri  = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_H2cxGDTU6"
  cognito_jwk_set_uri = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_H2cxGDTU6/.well-known/jwks.json"

  # Database connection from Lightsail database
  db_host     = module.lightsail_database[0].master_endpoint_address
  db_port     = tostring(module.lightsail_database[0].master_endpoint_port)
  db_name     = module.lightsail_database[0].master_database_name
  db_username = module.lightsail_database[0].master_username
  db_password = module.lightsail_database[0].db_password

  # Optional custom domain
  domain_name     = var.lightsail_domain_name
  route53_zone_id = var.lightsail_route53_zone_id

  depends_on = [module.networking, module.storage, module.messaging, module.lightsail_database]
}

# ===== Lambda Function (Shared across both platforms) =====
# Lambda for image processing works with both ECS and Lightsail backends
resource "aws_lambda_function" "image_processor" {
  function_name = "${var.project_name}-${var.environment}-image-processor"
  role          = aws_iam_role.lambda.arn
  handler       = "src/handler.lambda_handler"
  runtime       = "python3.13"
  architectures = ["arm64"]
  timeout       = 900 # 15 minutes
  memory_size   = 2048

  filename         = var.lambda_package_path
  source_code_hash = fileexists(var.lambda_package_path) ? filebase64sha256(var.lambda_package_path) : null

  environment {
    variables = {
      ENVIRONMENT      = var.environment
      S3_BUCKET_NAME   = module.storage.bucket_name
      DB_SECRET_ARN    = var.backend_platform == "ecs" ? module.database[0].db_secret_arn : module.lightsail_database[0].db_secret_arn
      BACKEND_URL      = var.backend_platform == "ecs" ? "http://${module.compute[0].alb_dns_name}" : module.lightsail_compute[0].backend_endpoint
      LAMBDA_SECRET    = var.lambda_secret
      PYTHONUNBUFFERED = "1"
    }
  }

  tracing_config {
    mode = "Active"
  }

  reserved_concurrent_executions = var.lambda_reserved_concurrency

  tags = {
    Name = "${var.project_name}-${var.environment}-image-processor"
  }
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn                   = module.messaging.queue_arn
  function_name                      = aws_lambda_function.image_processor.arn
  batch_size                         = 10
  maximum_batching_window_in_seconds = 5

  scaling_config {
    maximum_concurrency = var.lambda_reserved_concurrency
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-image-processor"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-logs"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-role"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_s3" {
  name = "${var.project_name}-${var.environment}-lambda-s3"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${module.storage.bucket_name}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_sqs" {
  name = "${var.project_name}-${var.environment}-lambda-sqs"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = module.messaging.queue_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_secrets" {
  name = "${var.project_name}-${var.environment}-lambda-secrets"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.backend_platform == "ecs" ? module.database[0].db_secret_arn : module.lightsail_database[0].db_secret_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_rekognition" {
  name = "${var.project_name}-${var.environment}-lambda-rekognition"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rekognition:DetectLabels"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_xray" {
  name = "${var.project_name}-${var.environment}-lambda-xray"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# ===== Observability Module =====
module "observability" {
  count  = var.backend_platform == "ecs" ? 1 : 0
  source = "./modules/observability"

  project_name         = var.project_name
  environment          = var.environment
  aws_region           = var.aws_region
  ecs_cluster_name     = module.compute[0].ecs_cluster_name
  ecs_service_name     = module.compute[0].ecs_service_name
  lambda_function_name = aws_lambda_function.image_processor.function_name
  alb_arn_suffix       = split("/", module.compute[0].alb_arn)[1]

  # Alarm Configuration
  error_rate_threshold      = var.alarm_error_rate_threshold
  response_time_threshold   = var.alarm_response_time_threshold
  lambda_error_threshold    = var.alarm_lambda_error_threshold
  lambda_duration_threshold = var.alarm_lambda_duration_threshold

  # SNS Configuration
  create_sns_topic      = var.create_sns_topic
  alarm_email_endpoints = var.alarm_email_endpoints

  depends_on = [module.compute, aws_lambda_function.image_processor]
}
