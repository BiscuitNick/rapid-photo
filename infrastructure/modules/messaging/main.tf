# Messaging Module - SQS Queues with DLQ
# Manages SQS queues for image processing with dead letter queue

terraform {
  required_version = ">= 1.9.0"
}

# Dead Letter Queue
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.project_name}-${var.environment}-image-processing-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Name        = "${var.project_name}-${var.environment}-image-processing-dlq"
    Environment = var.environment
  }
}

# Main Image Processing Queue
resource "aws_sqs_queue" "image_processing" {
  name                       = "${var.project_name}-${var.environment}-image-processing"
  visibility_timeout_seconds = var.visibility_timeout
  message_retention_seconds  = var.message_retention
  max_message_size           = 262144 # 256 KB
  delay_seconds              = 0
  receive_wait_time_seconds  = 20 # Long polling

  # Redrive policy to send messages to DLQ after max_receive_count
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-image-processing"
    Environment = var.environment
  }
}

# Queue Policy for S3 to send messages
resource "aws_sqs_queue_policy" "image_processing" {
  queue_url = aws_sqs_queue.image_processing.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "SQS:SendMessage"
        Resource = aws_sqs_queue.image_processing.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:s3:::${var.project_name}-${var.environment}-photos-*"
          }
        }
      }
    ]
  })
}

# CloudWatch Alarms for Queue Monitoring
resource "aws_cloudwatch_metric_alarm" "queue_depth" {
  alarm_name          = "${var.project_name}-${var.environment}-queue-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.queue_depth_threshold
  alarm_description   = "Monitors SQS queue depth"
  alarm_actions       = var.alarm_actions

  dimensions = {
    QueueName = aws_sqs_queue.image_processing.name
  }
}

resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "${var.project_name}-${var.environment}-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Alerts when messages appear in DLQ"
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }
}

resource "aws_cloudwatch_metric_alarm" "queue_age" {
  alarm_name          = "${var.project_name}-${var.environment}-queue-message-age"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Maximum"
  threshold           = var.message_age_threshold
  alarm_description   = "Monitors age of oldest message in queue"
  alarm_actions       = var.alarm_actions

  dimensions = {
    QueueName = aws_sqs_queue.image_processing.name
  }
}

# CloudWatch Log Group for Queue Monitoring
resource "aws_cloudwatch_log_group" "queue_monitoring" {
  count             = var.enable_detailed_logging ? 1 : 0
  name              = "/aws/sqs/${var.project_name}-${var.environment}-image-processing"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-queue-logs"
  }
}
