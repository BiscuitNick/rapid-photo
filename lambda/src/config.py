"""
Configuration management for Lambda function.
"""

import os
from typing import List

# AWS Configuration
AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')
S3_BUCKET = os.getenv('S3_BUCKET', 'rapid-photo-uploads')

# Database Configuration
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = int(os.getenv('DB_PORT', '5432'))
DB_NAME = os.getenv('DB_NAME', 'rapidphoto')
DB_USER = os.getenv('DB_USER', 'postgres')
DB_PASSWORD = os.getenv('DB_PASSWORD', '')

# Image Processing Configuration
THUMBNAIL_SIZE = (300, 300)
WEBP_QUALITY = 80
WEBP_WIDTHS: List[int] = [640, 1280, 1920, 2560]

# Rekognition Configuration
REKOGNITION_MIN_CONFIDENCE = 80.0
REKOGNITION_MAX_LABELS = 20

# Logging Configuration
LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
