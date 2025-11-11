# Outputs for Lightsail Compute Module

output "container_service_name" {
  description = "Name of the Lightsail container service"
  value       = aws_lightsail_container_service.backend.name
}

output "container_service_arn" {
  description = "ARN of the Lightsail container service"
  value       = aws_lightsail_container_service.backend.arn
}

output "container_service_url" {
  description = "Public URL of the container service"
  value       = aws_lightsail_container_service.backend.url
}

output "static_ip_address" {
  description = "Static IP address assigned to the container service"
  value       = aws_lightsail_static_ip.backend.ip_address
}

output "certificate_arn" {
  description = "ARN of the TLS certificate (if created)"
  value       = length(aws_lightsail_certificate.backend) > 0 ? aws_lightsail_certificate.backend[0].arn : null
}

output "iam_user_name" {
  description = "IAM user name for container service"
  value       = aws_iam_user.lightsail_backend.name
}

output "iam_user_arn" {
  description = "IAM user ARN"
  value       = aws_iam_user.lightsail_backend.arn
}

output "credentials_secret_arn" {
  description = "ARN of Secrets Manager secret containing IAM and DB credentials"
  value       = aws_secretsmanager_secret.lightsail_credentials.arn
}

output "backend_endpoint" {
  description = "Backend endpoint URL (custom domain if configured, otherwise Lightsail URL)"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "https://${aws_lightsail_container_service.backend.url}"
}
