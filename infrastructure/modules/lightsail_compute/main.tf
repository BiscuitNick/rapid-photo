# Lightsail Compute Module - Container Service
# Manages Lightsail container service, load balancer, and TLS certificate

terraform {
  required_version = ">= 1.9.0"
}

# ===== Lightsail Container Service =====
resource "aws_lightsail_container_service" "backend" {
  name  = "${var.project_name}-${var.environment}-backend"
  power = var.container_power # nano, micro, small, medium, large, xlarge
  scale = var.container_scale # 1-20

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend"
    Environment = var.environment
  }
}

# ===== Container Service Deployment =====
# NOTE: Deployments are managed manually via AWS CLI/Console
# See docs/lightsail-deployment.md for deployment procedures
# Reason: Deployments require Docker images which need to be built and pushed first
#
# resource "aws_lightsail_container_service_deployment_version" "backend" {
#   container {
#     container_name = "backend"
#     image          = var.backend_docker_image
#
#     environment = {
#       SPRING_PROFILES_ACTIVE = var.environment
#       AWS_REGION             = var.aws_region
#       S3_BUCKET_NAME         = var.s3_bucket_name
#       SQS_QUEUE_URL          = var.sqs_queue_url
#       SQS_PHOTO_UPLOAD_QUEUE = var.sqs_queue_url
#       DB_SSL_MODE            = "require"
#       LAMBDA_SECRET          = var.lambda_secret
#       COGNITO_ISSUER_URI     = var.cognito_issuer_uri
#       COGNITO_JWK_SET_URI    = var.cognito_jwk_set_uri
#     }
#
#     # Secrets will be injected via AWS credentials
#     # Database credentials from Lightsail database connection
#     ports = {
#       8080 = "HTTP"
#     }
#   }
#
#   public_endpoint {
#     container_name = "backend"
#     container_port = 8080
#
#     health_check {
#       healthy_threshold   = 2
#       unhealthy_threshold = 3
#       timeout_seconds     = 5
#       interval_seconds    = 30
#       path                = "/actuator/health"
#       success_codes       = "200"
#     }
#   }
#
#   service_name = aws_lightsail_container_service.backend.name
# }

# ===== Static IP for Load Balancer =====
# NOTE: Lightsail container services get a public endpoint URL automatically
# Static IPs are for EC2 instances, not container services
# Container service URL: https://<service-name>.<random-id>.<region>.cs.amazonlightsail.com/
#
resource "aws_lightsail_static_ip" "backend" {
  name = "${var.project_name}-${var.environment}-backend-ip"
}

# NOTE: Static IP attachment doesn't work for container services
# Commented out to prevent Terraform errors
#
# resource "aws_lightsail_static_ip_attachment" "backend" {
#   static_ip_name = aws_lightsail_static_ip.backend.name
#   instance_name  = aws_lightsail_container_service.backend.name
# }

# ===== TLS Certificate (if custom domain provided) =====
resource "aws_lightsail_certificate" "backend" {
  count = var.domain_name != "" ? 1 : 0

  name        = "${var.project_name}-${var.environment}-cert"
  domain_name = var.domain_name

  subject_alternative_names = var.subject_alternative_names

  tags = {
    Name = "${var.project_name}-${var.environment}-cert"
  }
}

# ===== Route53 DNS Record (if domain provided) =====
data "aws_route53_zone" "main" {
  count = var.domain_name != "" && var.route53_zone_id != "" ? 1 : 0

  zone_id = var.route53_zone_id
}

resource "aws_route53_record" "backend" {
  count = var.domain_name != "" && var.route53_zone_id != "" ? 1 : 0

  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = [aws_lightsail_static_ip.backend.ip_address]
}

# ===== IAM User for Container Service =====
# Least-privilege IAM user for S3 and SQS access
resource "aws_iam_user" "lightsail_backend" {
  name = "${var.project_name}-${var.environment}-lightsail-backend"

  tags = {
    Name = "${var.project_name}-${var.environment}-lightsail-backend"
  }
}

resource "aws_iam_access_key" "lightsail_backend" {
  user = aws_iam_user.lightsail_backend.name
}

# S3 Policy
resource "aws_iam_user_policy" "lightsail_s3" {
  name = "${var.project_name}-${var.environment}-lightsail-s3"
  user = aws_iam_user.lightsail_backend.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

# SQS Policy
resource "aws_iam_user_policy" "lightsail_sqs" {
  name = "${var.project_name}-${var.environment}-lightsail-sqs"
  user = aws_iam_user.lightsail_backend.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.sqs_queue_arn
      }
    ]
  })
}

# ===== Secrets Manager for IAM Credentials =====
resource "aws_secretsmanager_secret" "lightsail_credentials" {
  name                    = "${var.project_name}-${var.environment}-lightsail-credentials"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-lightsail-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "lightsail_credentials" {
  secret_id = aws_secretsmanager_secret.lightsail_credentials.id
  secret_string = jsonencode({
    aws_access_key_id     = aws_iam_access_key.lightsail_backend.id
    aws_secret_access_key = aws_iam_access_key.lightsail_backend.secret
    db_host               = var.db_host
    db_port               = var.db_port
    db_name               = var.db_name
    db_username           = var.db_username
    db_password           = var.db_password
  })
}

# ===== CloudWatch Alarms for Container Service =====
resource "aws_cloudwatch_metric_alarm" "container_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-lightsail-container-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/Lightsail"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Lightsail container service CPU utilization is high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ServiceName = aws_lightsail_container_service.backend.name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-lightsail-container-cpu"
  }
}

resource "aws_cloudwatch_metric_alarm" "container_memory" {
  alarm_name          = "${var.project_name}-${var.environment}-lightsail-container-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/Lightsail"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "Lightsail container service memory utilization is high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ServiceName = aws_lightsail_container_service.backend.name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-lightsail-container-memory"
  }
}
