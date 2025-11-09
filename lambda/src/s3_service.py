"""
S3 service for downloading and uploading image assets.
"""

import logging
from typing import Optional

import boto3
from botocore.exceptions import ClientError

from config import AWS_REGION, S3_BUCKET

logger = logging.getLogger(__name__)

# Initialize S3 client
s3_client = boto3.client('s3', region_name=AWS_REGION)


def download_from_s3(s3_key: str, bucket: str = S3_BUCKET) -> bytes:
    """
    Download file from S3.

    Args:
        s3_key: S3 object key
        bucket: S3 bucket name

    Returns:
        File contents as bytes

    Raises:
        ClientError: If download fails
    """
    try:
        logger.info(f"Downloading from S3: s3://{bucket}/{s3_key}")
        response = s3_client.get_object(Bucket=bucket, Key=s3_key)
        data = response['Body'].read()
        logger.info(f"Downloaded {len(data)} bytes from S3")
        return data

    except ClientError as e:
        error_code = e.response.get('Error', {}).get('Code', 'Unknown')
        logger.error(f"Failed to download from S3: {error_code} - {str(e)}")
        raise


def upload_to_s3(
    data: bytes,
    s3_key: str,
    bucket: str = S3_BUCKET,
    content_type: Optional[str] = None,
    metadata: Optional[dict] = None
) -> str:
    """
    Upload data to S3.

    Args:
        data: Data to upload
        s3_key: S3 object key
        bucket: S3 bucket name
        content_type: MIME type of the content
        metadata: Optional metadata dictionary

    Returns:
        S3 URI (s3://bucket/key)

    Raises:
        ClientError: If upload fails
    """
    try:
        logger.info(f"Uploading to S3: s3://{bucket}/{s3_key}")

        extra_args = {}
        if content_type:
            extra_args['ContentType'] = content_type
        if metadata:
            extra_args['Metadata'] = metadata

        s3_client.put_object(
            Bucket=bucket,
            Key=s3_key,
            Body=data,
            **extra_args
        )

        s3_uri = f"s3://{bucket}/{s3_key}"
        logger.info(f"Uploaded {len(data)} bytes to {s3_uri}")
        return s3_uri

    except ClientError as e:
        error_code = e.response.get('Error', {}).get('Code', 'Unknown')
        logger.error(f"Failed to upload to S3: {error_code} - {str(e)}")
        raise


def generate_processed_keys(original_key: str, width: Optional[int] = None) -> str:
    """
    Generate S3 key for processed images.

    Args:
        original_key: Original S3 key (e.g., "originals/userId/uuid.jpg" or "uploads/file.jpg")
        width: Optional width for renditions (None for thumbnails)

    Returns:
        Processed S3 key

    Example:
        >>> generate_processed_keys("originals/user123/photo-uuid.jpg", None)
        "thumbnails/user123/photo-uuid.jpg"
        >>> generate_processed_keys("originals/user123/photo-uuid.jpg", 1024)
        "processed/user123/photo-uuid-1024.webp"
        >>> generate_processed_keys("uploads/test.jpg", None)
        "thumbnails/test.jpg"
    """
    # Extract filename from original key
    parts = original_key.split('/')

    # Handle different key formats
    if len(parts) >= 3 and parts[0] == 'originals':
        # Format: originals/{userId}/{uuid}.{ext}
        user_id = parts[1]
        filename = parts[2]
        base_name = filename.rsplit('.', 1)[0]

        if width is None:
            return f"thumbnails/{user_id}/{base_name}.jpg"
        else:
            return f"processed/{user_id}/{base_name}-{width}.webp"
    else:
        # Simple format: uploads/file.ext or just file.ext
        filename = parts[-1]
        base_name = filename.rsplit('.', 1)[0]

        if width is None:
            return f"thumbnails/{base_name}.jpg"
        else:
            return f"processed/{base_name}-{width}.webp"
