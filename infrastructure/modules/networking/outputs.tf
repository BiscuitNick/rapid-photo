# Outputs for Networking Module

output "vpc_id" {
  description = "VPC ID"
  value       = data.aws_vpc.default.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = data.aws_vpc.default.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs (using default subnets)"
  value       = data.aws_subnets.default.ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs (using default subnets)"
  value       = data.aws_subnets.default.ids
}

output "alb_security_group_id" {
  description = "Security group ID for ALB"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}

output "rds_security_group_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds.id
}

output "lambda_security_group_id" {
  description = "Security group ID for Lambda"
  value       = aws_security_group.lambda.id
}

output "nat_gateway_ips" {
  description = "Elastic IPs of NAT gateways (not used with default VPC)"
  value       = []
}
