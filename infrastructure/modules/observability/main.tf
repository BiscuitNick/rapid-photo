# Observability Module - CloudWatch Dashboards, Alarms, X-Ray
# Comprehensive monitoring and tracing for RapidPhotoUpload

terraform {
  required_version = ">= 1.9.0"
}

# ===== X-Ray Tracing =====
resource "aws_xray_sampling_rule" "main" {
  rule_name      = "${var.project_name}-${var.environment}-sampling"
  priority       = 1000
  version        = 1
  reservoir_size = 1
  fixed_rate     = 0.05 # Sample 5% of requests
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"

  attributes = {
    Environment = var.environment
  }
}

# X-Ray Group for filtering traces
resource "aws_xray_group" "main" {
  group_name        = "${var.project_name}-${var.environment}"
  filter_expression = "service(\"${var.project_name}-${var.environment}\")"

  insights_configuration {
    insights_enabled      = true
    notifications_enabled = false
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-xray-group"
  }
}

# ===== CloudWatch Dashboard =====
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # ECS Service Metrics (RED)
      {
        type = "metric"
        properties = {
          title   = "ECS Service - Request Rate"
          region  = var.aws_region
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", { stat = "Sum", label = "Requests" }]
          ]
          period = 300
          stat   = "Sum"
          yAxis = {
            left = {
              label = "Count"
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          title   = "ECS Service - Error Rate"
          region  = var.aws_region
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", { stat = "Sum", label = "5XX Errors" }],
            [".", "HTTPCode_Target_4XX_Count", { stat = "Sum", label = "4XX Errors" }]
          ]
          period = 300
          stat   = "Sum"
        }
      },
      {
        type = "metric"
        properties = {
          title   = "ECS Service - Duration (p50, p95, p99)"
          region  = var.aws_region
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "p50", label = "p50" }],
            ["...", { stat = "p95", label = "p95" }],
            ["...", { stat = "p99", label = "p99" }]
          ]
          period = 300
          yAxis = {
            left = {
              label = "Seconds"
            }
          }
        }
      },

      # ECS USE Metrics
      {
        type = "metric"
        properties = {
          title   = "ECS - CPU & Memory Utilization"
          region  = var.aws_region
          metrics = [
            ["AWS/ECS", "CPUUtilization", { stat = "Average", label = "CPU %" }],
            [".", "MemoryUtilization", { stat = "Average", label = "Memory %" }]
          ]
          period = 300
          yAxis = {
            left = {
              label = "Percent"
              min   = 0
              max   = 100
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          title   = "ECS - Task Count"
          region  = var.aws_region
          metrics = [
            ["AWS/ECS", "RunningTaskCount", { stat = "Average", label = "Running Tasks" }]
          ]
          period = 300
        }
      },

      # Lambda Metrics
      {
        type = "metric"
        properties = {
          title   = "Lambda - Invocations & Errors"
          region  = var.aws_region
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", label = "Invocations" }],
            [".", "Errors", { stat = "Sum", label = "Errors" }],
            [".", "Throttles", { stat = "Sum", label = "Throttles" }]
          ]
          period = 300
        }
      },
      {
        type = "metric"
        properties = {
          title   = "Lambda - Duration & Concurrent Executions"
          region  = var.aws_region
          metrics = [
            ["AWS/Lambda", "Duration", { stat = "Average", label = "Avg Duration (ms)" }],
            [".", "ConcurrentExecutions", { stat = "Maximum", label = "Max Concurrent" }]
          ]
          period = 300
        }
      },

      # SQS Queue Metrics
      {
        type = "metric"
        properties = {
          title   = "SQS - Queue Depth & Age"
          region  = var.aws_region
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", { stat = "Average", label = "Messages in Queue" }],
            [".", "ApproximateAgeOfOldestMessage", { stat = "Maximum", label = "Oldest Message (s)" }]
          ]
          period = 300
        }
      },
      {
        type = "metric"
        properties = {
          title   = "SQS - Dead Letter Queue"
          region  = var.aws_region
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", { stat = "Sum", label = "DLQ Messages" }]
          ]
          period = 300
        }
      },

      # RDS Metrics
      {
        type = "metric"
        properties = {
          title   = "RDS - CPU & Connections"
          region  = var.aws_region
          metrics = [
            ["AWS/RDS", "CPUUtilization", { stat = "Average", label = "CPU %" }],
            [".", "DatabaseConnections", { stat = "Average", label = "Connections" }]
          ]
          period = 300
        }
      },
      {
        type = "metric"
        properties = {
          title   = "RDS - Storage & Memory"
          region  = var.aws_region
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", { stat = "Average", label = "Free Storage (bytes)" }],
            [".", "FreeableMemory", { stat = "Average", label = "Free Memory (bytes)" }]
          ]
          period = 300
        }
      },

      # S3 Metrics
      {
        type = "metric"
        properties = {
          title   = "S3 - Bucket Operations"
          region  = var.aws_region
          metrics = [
            ["AWS/S3", "AllRequests", { stat = "Sum", label = "All Requests" }],
            [".", "4xxErrors", { stat = "Sum", label = "4xx Errors" }],
            [".", "5xxErrors", { stat = "Sum", label = "5xx Errors" }]
          ]
          period = 300
        }
      }
    ]
  })
}

# ===== Composite Alarms =====
# High Error Rate Alarm (ECS)
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "${var.project_name}-${var.environment}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = var.error_rate_threshold
  alarm_description   = "Triggers when 5XX error rate is high"
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-high-error-rate"
  }
}

# High Response Time Alarm
resource "aws_cloudwatch_metric_alarm" "high_response_time" {
  alarm_name          = "${var.project_name}-${var.environment}-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  extended_statistic  = "p99"
  threshold           = var.response_time_threshold
  alarm_description   = "Triggers when p99 response time exceeds threshold"
  alarm_actions       = var.alarm_actions

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-high-response-time"
  }
}

# ECS CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS CPU utilization is too high"
  alarm_actions       = var.alarm_actions

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-cpu-high"
  }
}

# ECS Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "${var.project_name}-${var.environment}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "ECS memory utilization is too high"
  alarm_actions       = var.alarm_actions

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-memory-high"
  }
}

# Lambda Errors Alarm
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.lambda_error_threshold
  alarm_description   = "Lambda function error rate is too high"
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-errors"
  }
}

# Lambda Duration Alarm
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  extended_statistic  = "p95"
  threshold           = var.lambda_duration_threshold
  alarm_description   = "Lambda p95 duration exceeds threshold"
  alarm_actions       = var.alarm_actions

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-duration"
  }
}

# Lambda Throttles Alarm
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Lambda function is being throttled"
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-throttles"
  }
}

# ===== SNS Topic for Alarms =====
resource "aws_sns_topic" "alarms" {
  count = var.create_sns_topic ? 1 : 0
  name  = "${var.project_name}-${var.environment}-alarms"

  tags = {
    Name = "${var.project_name}-${var.environment}-alarms"
  }
}

resource "aws_sns_topic_subscription" "alarms_email" {
  count     = var.create_sns_topic && length(var.alarm_email_endpoints) > 0 ? length(var.alarm_email_endpoints) : 0
  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email_endpoints[count.index]
}

# ===== CloudWatch Log Insights Queries =====
resource "aws_cloudwatch_query_definition" "error_analysis" {
  name = "${var.project_name}-${var.environment}/error-analysis"

  log_group_names = [
    "/ecs/${var.project_name}-${var.environment}/backend",
    "/aws/lambda/${var.lambda_function_name}"
  ]

  query_string = <<-QUERY
    fields @timestamp, @message, @logStream
    | filter @message like /ERROR|Exception|error/
    | sort @timestamp desc
    | limit 100
  QUERY
}

resource "aws_cloudwatch_query_definition" "slow_requests" {
  name = "${var.project_name}-${var.environment}/slow-requests"

  log_group_names = [
    "/ecs/${var.project_name}-${var.environment}/backend"
  ]

  query_string = <<-QUERY
    fields @timestamp, @message, @logStream
    | filter @message like /duration/
    | parse @message /duration=(?<duration>\d+)/
    | filter duration > 1000
    | sort duration desc
    | limit 50
  QUERY
}
