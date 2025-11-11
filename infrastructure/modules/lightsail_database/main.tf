# Lightsail Database Module - PostgreSQL Managed Database
# Manages Lightsail PostgreSQL database with automated backups and TLS

terraform {
  required_version = ">= 1.9.0"
}

# ===== Lightsail PostgreSQL Database =====
resource "aws_lightsail_database" "postgres" {
  relational_database_name = "${var.project_name}-${var.environment}-db"
  master_database_name     = var.db_name
  master_username          = var.db_username
  master_password          = random_password.db_password.result

  # Instance configuration
  blueprint_id = var.database_blueprint_id # postgres_15 or postgres_16
  bundle_id    = var.database_bundle_id    # micro_2_0, small_2_0, medium_2_0, large_2_0

  # Availability zone (optional)
  availability_zone = var.availability_zone

  # Backup configuration
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "mon:04:00-mon:05:00"
  backup_retention_enabled     = true

  # Public accessibility (set to false for production)
  publicly_accessible = var.publicly_accessible

  # Skip final snapshot for dev/demo
  skip_final_snapshot = var.skip_final_snapshot
  final_snapshot_name = var.skip_final_snapshot ? null : "${var.project_name}-${var.environment}-final-snapshot"
  apply_immediately   = var.apply_immediately

  tags = {
    Name        = "${var.project_name}-${var.environment}-db"
    Environment = var.environment
  }
}

# ===== Random Password Generation =====
resource "random_password" "db_password" {
  length  = 32
  special = true
  # Lightsail has specific password requirements
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# ===== Secrets Manager for Database Credentials =====
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.project_name}-${var.environment}-lightsail-db-credentials"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-lightsail-db-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = aws_lightsail_database.postgres.master_username
    password = random_password.db_password.result
    engine   = "postgres"
    host     = aws_lightsail_database.postgres.master_endpoint_address
    port     = aws_lightsail_database.postgres.master_endpoint_port
    dbname   = aws_lightsail_database.postgres.master_database_name
  })
}

# ===== CloudWatch Alarms for Database =====
resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-lightsail-db-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/Lightsail"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Lightsail database CPU utilization is high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DatabaseName = aws_lightsail_database.postgres.relational_database_name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-lightsail-db-cpu"
  }
}

resource "aws_cloudwatch_metric_alarm" "database_connections" {
  alarm_name          = "${var.project_name}-${var.environment}-lightsail-db-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/Lightsail"
  period              = "300"
  statistic           = "Average"
  threshold           = var.max_connections_threshold
  alarm_description   = "Lightsail database connection count is high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DatabaseName = aws_lightsail_database.postgres.relational_database_name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-lightsail-db-connections"
  }
}

resource "aws_cloudwatch_metric_alarm" "database_free_storage" {
  alarm_name          = "${var.project_name}-${var.environment}-lightsail-db-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/Lightsail"
  period              = "300"
  statistic           = "Average"
  threshold           = var.free_storage_threshold_bytes
  alarm_description   = "Lightsail database free storage is low"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DatabaseName = aws_lightsail_database.postgres.relational_database_name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-lightsail-db-storage"
  }
}
