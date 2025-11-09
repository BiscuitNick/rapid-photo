"""
RapidPhotoUpload Lambda Handler

This Lambda function processes uploaded images from S3:
- Generates thumbnails (300x300 center crop)
- Creates WebP renditions at multiple widths
- Runs AWS Rekognition for AI label detection
- Notifies the backend API when processing completes
"""

import json
import logging
import os
from typing import Any, Dict, List, Tuple
from urllib.parse import unquote_plus

import urllib3

from .config import S3_BUCKET
from .image_processor import create_thumbnail, get_image_metadata
from .metrics import StructuredLogger, increment_counter, timed_operation
from .rekognition_service import detect_labels, extract_tags
from .s3_service import download_from_s3, generate_processed_keys, upload_to_s3
from .webp_converter import create_webp_renditions

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.getenv('LOG_LEVEL', 'INFO'))
structured_logger = StructuredLogger(__name__)

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


def extract_ids_from_s3_key(s3_key: str) -> Tuple[str, str]:
    """
    Extract user and photo identifiers from an originals/ S3 key.

    Args:
        s3_key: Key in the format originals/{userId}/{photoId}[.ext]

    Returns:
        Tuple of (user_id, photo_id)

    Raises:
        ValueError: If the key does not match the expected format
    """
    parts = s3_key.split('/')
    if len(parts) < 3 or parts[0] != 'originals':
        raise ValueError(f"Unsupported S3 key format: {s3_key}")

    user_id = parts[1]
    filename = parts[2]
    photo_id = filename.rsplit('.', 1)[0]
    return user_id, photo_id


def extract_from_s3_record(s3_record: Dict[str, Any]) -> Tuple[str, str, str]:
    """
    Extract identifiers from a raw S3 event record.

    Returns:
        Tuple of (photo_id, s3_key, user_id)
    """
    s3_payload = s3_record.get('s3', {})
    object_payload = s3_payload.get('object', {})

    raw_key = object_payload.get('key')
    if not raw_key:
        raise ValueError("S3 event missing object key")

    s3_key = unquote_plus(raw_key)
    user_id, photo_id = extract_ids_from_s3_key(s3_key)
    return photo_id, s3_key, user_id


def parse_record(record: Dict[str, Any]) -> Tuple[str, str, str]:
    """
    Parse a Lambda event record coming from either S3 or SQS.

    Returns:
        Tuple of (photo_id, s3_key, user_id)

    Raises:
        ValueError: If the record cannot be parsed or required fields are missing
    """
    # Direct S3 invocation
    if record.get('eventSource') == 'aws:s3':
        return extract_from_s3_record(record)

    body_raw = record.get('body', '')
    try:
        message_body = json.loads(body_raw)
    except json.JSONDecodeError as exc:
        raise ValueError(f"Invalid JSON body: {exc}") from exc

    # SQS message containing an S3 event
    if isinstance(message_body, dict) and message_body.get('Records'):
        first_inner = message_body['Records'][0]
        if first_inner.get('eventSource') == 'aws:s3':
            return extract_from_s3_record(first_inner)

    # Custom backend message
    photo_id = message_body.get('photoId') or message_body.get('uploadId')
    s3_key = message_body.get('s3Key')
    user_id = message_body.get('userId')

    if not all([photo_id, s3_key, user_id]):
        raise ValueError("Missing required fields (photoId, s3Key, userId)")

    return photo_id, s3_key, user_id


def process_single_image(
    photo_id: str,
    s3_key: str,
    user_id: str,
    notify_backend: bool = True
) -> Dict[str, Any]:
    """
    Process a single image through the complete pipeline and notify the backend.

    Args:
        photo_id: UUID of the photo record
        s3_key: S3 key of the original image
        user_id: User ID who owns the photo
        notify_backend: Whether to notify backend when complete

    Returns:
        Processing result dictionary
    """
    structured_logger.info(
        "Processing photo",
        photo_id=photo_id,
        user_id=user_id,
        s3_key=s3_key
    )

    with timed_operation('image_processing', dimensions={'user_id': user_id}):
        # Step 1: Download original image from S3
        image_data = download_from_s3(s3_key)
        increment_counter('image.downloaded', dimensions={'user_id': user_id})

        # Step 2: Extract metadata
        metadata = get_image_metadata(image_data)

        # Step 3: Generate thumbnail
        thumbnail_data = create_thumbnail(image_data)
        thumbnail_key = generate_processed_keys(s3_key, width=None)
        upload_to_s3(thumbnail_data, thumbnail_key, content_type='image/jpeg')
        increment_counter('thumbnail.created', dimensions={'user_id': user_id})

        # Step 4: Create WebP renditions
        renditions = create_webp_renditions(image_data)
        rendition_entries: List[Dict[str, Any]] = []
        for width in sorted(renditions.keys()):
            webp_data = renditions[width]
            rendition_key = generate_processed_keys(s3_key, width=width)
            upload_to_s3(webp_data, rendition_key, content_type='image/webp')
            rendition_entries.append({
                'width': width,
                's3Key': rendition_key,
                'contentType': 'image/webp',
                'sizeBytes': len(webp_data)
            })

        increment_counter(
            'renditions.created',
            value=len(rendition_entries),
            dimensions={'user_id': user_id}
        )

        # Step 5: Run Rekognition for label detection
        labels = detect_labels(s3_key, bucket=S3_BUCKET)
        tags = extract_tags(labels, max_tags=10)
        increment_counter('rekognition.completed', dimensions={'user_id': user_id})

        # Step 6: Notify backend
        processing_payload = {
            'photoId': photo_id,
            'userId': user_id,
            'status': 'READY',
            'originalKey': s3_key,
            'thumbnailKey': thumbnail_key,
            'metadata': {
                'width': metadata.get('width'),
                'height': metadata.get('height'),
                'format': metadata.get('format'),
                'sizeBytes': metadata.get('size_bytes'),
            },
            'versions': rendition_entries,
            'labels': labels,
            'tags': tags
        }

        if notify_backend:
            notify_backend_complete(photo_id, processing_payload)
            increment_counter('backend.notification.count', dimensions={'user_id': user_id})

        structured_logger.info(
            "Image processing completed",
            photo_id=photo_id,
            thumbnail_key=thumbnail_key,
            renditions=len(rendition_entries),
            tags=len(tags)
        )

        return {
            'photo_id': photo_id,
            's3_key': s3_key,
            'status': 'completed',
            'thumbnail_key': thumbnail_key,
            'metadata': processing_payload['metadata'],
            'renditions': rendition_entries,
            'tags': tags,
            'label_count': len(labels)
        }


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda entry point - processes S3 or SQS messages triggered by uploads.

    Args:
        event: Incoming Lambda event
        context: Lambda context

    Returns:
        Processing summary
    """
    records = event.get('Records', [])
    structured_logger.info("Lambda invoked", records=len(records))

    results: List[Dict[str, Any]] = []
    errors: List[Dict[str, Any]] = []

    for record in records:
        message_id = (
            record.get('messageId')
            or record.get('eventID')
            or record.get('responseElements', {}).get('x-amz-request-id')
            or 'unknown'
        )

        try:
            photo_id, s3_key, user_id = parse_record(record)
        except ValueError as parse_error:
            structured_logger.error(
                "Failed to parse record",
                message_id=message_id,
                error=str(parse_error)
            )
            errors.append({
                'message_id': message_id,
                'error': str(parse_error)
            })
            increment_counter('message.processed.failure')
            continue

        try:
            result = process_single_image(photo_id, s3_key, user_id, notify_backend=True)
            result['message_id'] = message_id
            results.append(result)
            increment_counter('message.processed.success')
        except Exception as processing_error:
            logger.error(f"Failed to process record {message_id}: {processing_error}", exc_info=True)
            structured_logger.error(
                "Processing error",
                message_id=message_id,
                photo_id=photo_id,
                error=str(processing_error)
            )
            errors.append({
                'message_id': message_id,
                'error': str(processing_error)
            })
            increment_counter('message.processed.failure')

    status_code = 200 if not errors else 207
    response_body = {
        'processed': len(results),
        'failed': len(errors),
        'results': results,
        'errors': errors
    }

    if errors:
        structured_logger.warning(
            "Lambda completed with partial failures",
            processed=len(results),
            failed=len(errors)
        )
    else:
        structured_logger.info(
            "Lambda completed successfully",
            processed=len(results)
        )

    return {
        'statusCode': status_code,
        'body': json.dumps(response_body)
    }
