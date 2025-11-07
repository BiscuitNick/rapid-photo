# Storage Module - S3 Buckets with Lifecycle and Event Notifications
# Manages photo storage buckets with intelligent tiering and SQS notifications

terraform {
  required_version = ">= 1.9.0"
}

# S3 Bucket for Photo Uploads
resource "aws_s3_bucket" "photos" {
  bucket = "${var.project_name}-${var.environment}-photos-${var.bucket_suffix}"

  tags = {
    Name        = "${var.project_name}-${var.environment}-photos"
    Environment = var.environment
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "photos" {
  bucket = aws_s3_bucket.photos.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "photos" {
  bucket = aws_s3_bucket.photos.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "photos" {
  bucket = aws_s3_bucket.photos.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "photos" {
  bucket = aws_s3_bucket.photos.id

  # Transition originals to Glacier after 90 days
  rule {
    id     = "archive-originals"
    status = "Enabled"

    filter {
      prefix = "originals/"
    }

    transition {
      days          = 90
      storage_class = "GLACIER_IR"
    }

    transition {
      days          = 180
      storage_class = "DEEP_ARCHIVE"
    }
  }

  # Transition thumbnails to Intelligent-Tiering
  rule {
    id     = "intelligent-tier-thumbnails"
    status = "Enabled"

    filter {
      prefix = "thumbnails/"
    }

    transition {
      days          = 30
      storage_class = "INTELLIGENT_TIERING"
    }
  }

  # Transition processed images to Intelligent-Tiering
  rule {
    id     = "intelligent-tier-processed"
    status = "Enabled"

    filter {
      prefix = "processed/"
    }

    transition {
      days          = 30
      storage_class = "INTELLIGENT_TIERING"
    }
  }

  # Delete incomplete multipart uploads after 7 days
  rule {
    id     = "cleanup-incomplete-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# CORS configuration
resource "aws_s3_bucket_cors_configuration" "photos" {
  bucket = aws_s3_bucket.photos.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = var.allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# S3 Bucket Notification to SQS
resource "aws_s3_bucket_notification" "photo_upload" {
  bucket = aws_s3_bucket.photos.id

  queue {
    queue_arn     = var.sqs_queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "originals/"
    filter_suffix = ""
  }

  depends_on = [aws_s3_bucket_policy.sqs_notification]
}

# Bucket policy to allow SQS notifications
resource "aws_s3_bucket_policy" "sqs_notification" {
  bucket = aws_s3_bucket.photos.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "SQS:SendMessage"
        Resource = var.sqs_queue_arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_s3_bucket.photos.arn
          }
        }
      }
    ]
  })
}

# CloudWatch Metrics for S3
resource "aws_cloudwatch_metric_alarm" "bucket_size" {
  count               = var.enable_bucket_metrics ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-s3-bucket-size"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period              = "86400" # 1 day
  statistic           = "Average"
  threshold           = var.bucket_size_alarm_threshold
  alarm_description   = "Monitors S3 bucket size"
  alarm_actions       = var.alarm_actions

  dimensions = {
    BucketName  = aws_s3_bucket.photos.id
    StorageType = "StandardStorage"
  }
}

resource "aws_cloudwatch_metric_alarm" "bucket_objects" {
  count               = var.enable_bucket_metrics ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-s3-object-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfObjects"
  namespace           = "AWS/S3"
  period              = "86400" # 1 day
  statistic           = "Average"
  threshold           = var.object_count_alarm_threshold
  alarm_description   = "Monitors S3 object count"
  alarm_actions       = var.alarm_actions

  dimensions = {
    BucketName  = aws_s3_bucket.photos.id
    StorageType = "AllStorageTypes"
  }
}
