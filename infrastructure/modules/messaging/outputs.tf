# Outputs for Messaging Module

output "queue_url" {
  description = "URL of the main image processing queue"
  value       = aws_sqs_queue.image_processing.url
}

output "queue_arn" {
  description = "ARN of the main image processing queue"
  value       = aws_sqs_queue.image_processing.arn
}

output "queue_name" {
  description = "Name of the main image processing queue"
  value       = aws_sqs_queue.image_processing.name
}

output "dlq_url" {
  description = "URL of the dead letter queue"
  value       = aws_sqs_queue.dlq.url
}

output "dlq_arn" {
  description = "ARN of the dead letter queue"
  value       = aws_sqs_queue.dlq.arn
}

output "dlq_name" {
  description = "Name of the dead letter queue"
  value       = aws_sqs_queue.dlq.name
}
