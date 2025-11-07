# RapidPhotoUpload Infrastructure - Main Terraform Configuration
# This is the entry point for the infrastructure setup

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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

# Placeholder module calls - will be implemented in subsequent tasks
# module "networking" {
#   source = "./modules/networking"
#
#   environment = var.environment
#   vpc_cidr    = var.vpc_cidr
# }

# module "database" {
#   source = "./modules/database"
#
#   environment = var.environment
#   vpc_id      = module.networking.vpc_id
#   subnet_ids  = module.networking.private_subnet_ids
# }

# module "storage" {
#   source = "./modules/storage"
#
#   environment = var.environment
#   bucket_name = var.s3_bucket_name
# }

# module "messaging" {
#   source = "./modules/messaging"
#
#   environment = var.environment
# }

# module "compute" {
#   source = "./modules/compute"
#
#   environment           = var.environment
#   vpc_id                = module.networking.vpc_id
#   private_subnet_ids    = module.networking.private_subnet_ids
#   alb_subnet_ids        = module.networking.public_subnet_ids
#   backend_image         = var.backend_docker_image
#   lambda_package_path   = var.lambda_package_path
# }
