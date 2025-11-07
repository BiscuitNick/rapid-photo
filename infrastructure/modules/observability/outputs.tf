# Outputs for Observability Module

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "xray_group_name" {
  description = "X-Ray group name"
  value       = aws_xray_group.main.group_name
}

output "xray_group_arn" {
  description = "X-Ray group ARN"
  value       = aws_xray_group.main.arn
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = var.create_sns_topic ? aws_sns_topic.alarms[0].arn : null
}

output "alarm_names" {
  description = "List of created alarm names"
  value = [
    aws_cloudwatch_metric_alarm.high_error_rate.alarm_name,
    aws_cloudwatch_metric_alarm.high_response_time.alarm_name,
    aws_cloudwatch_metric_alarm.ecs_cpu_high.alarm_name,
    aws_cloudwatch_metric_alarm.ecs_memory_high.alarm_name,
    aws_cloudwatch_metric_alarm.lambda_errors.alarm_name,
    aws_cloudwatch_metric_alarm.lambda_duration.alarm_name,
    aws_cloudwatch_metric_alarm.lambda_throttles.alarm_name
  ]
}
