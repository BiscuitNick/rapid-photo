# Outputs for Lightsail Database Module

output "database_name" {
  description = "Name of the Lightsail database"
  value       = aws_lightsail_database.postgres.relational_database_name
}

output "database_arn" {
  description = "ARN of the Lightsail database"
  value       = aws_lightsail_database.postgres.arn
}

output "master_endpoint_address" {
  description = "Database master endpoint address"
  value       = aws_lightsail_database.postgres.master_endpoint_address
}

output "master_endpoint_port" {
  description = "Database master endpoint port"
  value       = aws_lightsail_database.postgres.master_endpoint_port
}

output "master_database_name" {
  description = "Master database name"
  value       = aws_lightsail_database.postgres.master_database_name
}

output "master_username" {
  description = "Master username"
  value       = aws_lightsail_database.postgres.master_username
  sensitive   = true
}

output "db_password" {
  description = "Generated database password"
  value       = random_password.db_password.result
  sensitive   = true
}

output "db_secret_arn" {
  description = "ARN of Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "support_code" {
  description = "Support code for the database (for support requests)"
  value       = aws_lightsail_database.postgres.support_code
}
