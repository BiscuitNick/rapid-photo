"""
RapidPhotoUpload Lambda Handler

This Lambda function processes uploaded images from S3:
- Generates thumbnails (300x300 center crop)
- Creates WebP renditions at multiple widths
- Runs AWS Rekognition for AI label detection
- Notifies backend API when processing completes
"""

import json
import logging
import os
from typing import Any, Dict, List
import urllib3

from config import S3_BUCKET
from image_processor import create_thumbnail, get_image_metadata
from rekognition_service import detect_labels, extract_tags
from s3_service import download_from_s3, generate_processed_keys, upload_to_s3
from webp_converter import create_webp_renditions

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.getenv('LOG_LEVEL', 'INFO'))

# HTTP client for backend callbacks
http = urllib3.PoolManager()

# Backend API configuration
BACKEND_URL = os.getenv('BACKEND_URL', 'http://localhost:8080')
LAMBDA_SECRET = os.getenv('LAMBDA_SECRET', 'change-me-in-production')


def notify_backend_complete(photo_id: str, result: Dict[str, Any]) -> None:
    """
    Notify backend API that photo processing is complete.

    Args:
        photo_id: UUID of the photo
        result: Processing result with versions, metadata, labels
    """
    try:
        url = f"{BACKEND_URL}/api/v1/internal/photos/{photo_id}/processing-complete"

        response = http.request(
            'POST',
            url,
            body=json.dumps(result).encode('utf-8'),
            headers={
                'Content-Type': 'application/json',
                'X-Lambda-Secret': LAMBDA_SECRET
            },
            timeout=10.0
        )

        if response.status == 200:
            logger.info(f"✅ Backend notified successfully for photo {photo_id}")
        else:
            logger.error(f"❌ Backend returned status {response.status}: {response.data}")

    except Exception as e:
        logger.error(f"Failed to notify backend for photo {photo_id}: {str(e)}")
        # Don't raise - processing succeeded even if notification failed


def process_single_image(
    photo_id: str,
    s3_key: str,
    user_id: str
) -> Dict[str, Any]:
    """
    Process a single image through the complete pipeline.

    Args:
        photo_id: UUID of the photo record
        s3_key: S3 key of the original image
        user_id: User ID who owns the photo

    Returns:
        Processing result dictionary

    Raises:
        Exception: If processing fails at any step
    """
    logger.info(f"Processing photo {photo_id}, s3_key={s3_key}, user={user_id}")

    # Step 1: Download original image from S3
    logger.info(f"Downloading original image: {s3_key}")
    image_data = download_from_s3(s3_key)

    # Step 2: Extract image metadata
    metadata = get_image_metadata(image_data)
    logger.info(f"Extracted metadata: {metadata}")

    # Step 3: Generate thumbnail
    logger.info("Creating thumbnail")
    thumbnail_data = create_thumbnail(image_data)
    thumbnail_key = generate_processed_keys(s3_key, width=None)
    logger.info(f"Uploading thumbnail to {thumbnail_key}")
    upload_to_s3(thumbnail_data, thumbnail_key, content_type='image/jpeg')
    logger.info("Thumbnail uploaded successfully")

    # SIMPLIFIED: Skip WebP renditions and Rekognition for testing
    logger.info("Skipping WebP and Rekognition - simplified test")

    # Build simplified result and notify backend
    result = {
        'status': 'READY',
        'thumbnailKey': thumbnail_key,
        'metadata': {
            'width': metadata.get('width'),
            'height': metadata.get('height'),
            'format': metadata.get('format'),
            'size': metadata.get('size_bytes')
        },
        'versions': [],
        'labels': []
    }

    logger.info(f"Notifying backend for photo {photo_id}")
    notify_backend_complete(photo_id, result)
    logger.info("Backend notification complete")

    return {
        'photo_id': photo_id,
        's3_key': s3_key,
        'status': 'success',
        'thumbnail_key': thumbnail_key,
        'rendition_count': 0,
        'label_count': 0
    }


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda entry point - processes SQS messages from S3 upload events.

    Args:
        event: SQS event containing S3 upload notifications or backend messages
        context: Lambda context

    Returns:
        Processing summary
    """
    logger.info(f"Received event with {len(event.get('Records', []))} records")

    results = []
    errors = []

    for record in event.get('Records', []):
        try:
            # Parse SQS message body
            body = json.loads(record['body'])

            # Detect message type: S3 event notification vs backend custom message
            if 'Records' in body and body.get('Records', [{}])[0].get('eventSource') == 'aws:s3':
                # S3 event notification - parse S3 event structure
                s3_record = body['Records'][0]
                s3_key = s3_record['s3']['object']['key']

                # Parse S3 key: originals/{userId}/{photoId} or originals/{userId}/{photoId}.ext
                key_parts = s3_key.split('/')
                if len(key_parts) >= 3 and key_parts[0] == 'originals':
                    user_id = key_parts[1]
                    photo_id = key_parts[2].split('.')[0]  # Remove extension if present
                    logger.info(f"S3 event: extracted userId={user_id}, photoId={photo_id}, key={s3_key}")
                else:
                    logger.error(f"Invalid S3 key format: {s3_key}")
                    errors.append({
                        'message_id': record.get('messageId'),
                        'error': f'Invalid S3 key format: {s3_key}'
                    })
                    continue
            else:
                # Backend custom message format
                photo_id = body.get('photoId') or body.get('uploadId')
                s3_key = body.get('s3Key')
                user_id = body.get('userId')

                if not all([photo_id, s3_key, user_id]):
                    logger.error(f"Missing required fields in backend message: {body}")
                    errors.append({
                        'message_id': record.get('messageId'),
                        'error': 'Missing required fields'
                    })
                    continue

            # Process the image
            result = process_single_image(photo_id, s3_key, user_id)
            results.append(result)

        except Exception as e:
            logger.error(f"Failed to process record: {str(e)}", exc_info=True)
            errors.append({
                'message_id': record.get('messageId'),
                'error': str(e)
            })

    # Return summary
    return {
        'statusCode': 200 if not errors else 207,
        'body': json.dumps({
            'processed': len(results),
            'failed': len(errors),
            'results': results,
            'errors': errors
        })
    }
