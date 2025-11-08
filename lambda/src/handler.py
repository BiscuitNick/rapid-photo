"""
RapidPhotoUpload Lambda Handler

This Lambda function processes uploaded images from S3:
- Generates thumbnails (300x300 center crop)
- Creates WebP renditions at multiple widths
- Runs AWS Rekognition for AI label detection
- Updates PostgreSQL database with processed metadata
- Publishes completion events
"""

import json
import logging
import os
from typing import Any, Dict, List

from config import S3_BUCKET
from db_service import (
    check_photo_status,
    mark_photo_failed,
    save_photo_versions,
    update_photo_metadata,
)
from image_processor import create_thumbnail, get_image_metadata
from metrics import StructuredLogger, increment_counter, timed_operation
from rekognition_service import detect_labels, extract_tags
from s3_service import download_from_s3, generate_processed_keys, upload_to_s3
from webp_converter import create_webp_renditions

# Configure structured logging
logger = logging.getLogger()
logger.setLevel(os.getenv('LOG_LEVEL', 'INFO'))
structured_logger = StructuredLogger(__name__)


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
    with timed_operation('image_processing', dimensions={'user_id': user_id}):
        # Step 1: Check idempotency - skip if already processed
        current_status = check_photo_status(photo_id)
        if current_status in ('READY', 'PROCESSING'):
            structured_logger.info(
                "Photo already processed or in progress, skipping",
                photo_id=photo_id,
                status=current_status
            )
            return {
                'photo_id': photo_id,
                's3_key': s3_key,
                'status': 'skipped',
                'reason': f'Already in status: {current_status}'
            }

        # Step 2: Download original image from S3
        structured_logger.info("Downloading original image", photo_id=photo_id, s3_key=s3_key)
        image_data = download_from_s3(s3_key)
        increment_counter('image.downloaded', dimensions={'user_id': user_id})

        # Step 3: Extract image metadata
        metadata = get_image_metadata(image_data)
        structured_logger.info("Extracted metadata", photo_id=photo_id, metadata=metadata)

        # Step 4: Generate thumbnail
        structured_logger.info("Creating thumbnail", photo_id=photo_id)
        thumbnail_data = create_thumbnail(image_data)
        thumbnail_key = generate_processed_keys(s3_key, width=None)
        upload_to_s3(thumbnail_data, thumbnail_key, content_type='image/jpeg')
        increment_counter('thumbnail.created', dimensions={'user_id': user_id})

        # Step 5: Create WebP renditions
        structured_logger.info("Creating WebP renditions", photo_id=photo_id)
        renditions = create_webp_renditions(image_data)

        # Upload renditions and build version mapping
        version_keys = {}
        for width, webp_data in renditions.items():
            rendition_key = generate_processed_keys(s3_key, width=width)
            upload_to_s3(webp_data, rendition_key, content_type='image/webp')
            version_keys[width] = rendition_key

        increment_counter(
            'renditions.created',
            value=len(renditions),
            dimensions={'user_id': user_id}
        )

        # Step 6: Run Rekognition for label detection
        structured_logger.info("Running Rekognition", photo_id=photo_id, s3_key=s3_key)
        labels = detect_labels(s3_key, bucket=S3_BUCKET)
        tags = extract_tags(labels, max_tags=10)
        increment_counter('rekognition.completed', dimensions={'user_id': user_id})

        # Step 7: Update database with all metadata
        structured_logger.info(
            "Updating database",
            photo_id=photo_id,
            tags_count=len(tags),
            versions_count=len(version_keys)
        )
        update_photo_metadata(
            photo_id=photo_id,
            thumbnail_key=thumbnail_key,
            metadata=metadata,
            tags=tags,
            status='READY'
        )

        # Save photo versions (including thumbnail)
        save_photo_versions(photo_id=photo_id, versions=version_keys, thumbnail_key=thumbnail_key)

        # Save AI labels
        from db_service import save_photo_labels
        label_confidences = {label['name']: label['confidence'] for label in labels}
        save_photo_labels(photo_id=photo_id, labels=tags, confidences=label_confidences)

        structured_logger.info(
            "Image processing completed",
            photo_id=photo_id,
            thumbnail_key=thumbnail_key,
            renditions=len(version_keys),
            tags=len(tags)
        )

        return {
            'photo_id': photo_id,
            's3_key': s3_key,
            'status': 'completed',
            'thumbnail_key': thumbnail_key,
            'renditions': list(version_keys.keys()),
            'tags': tags[:5]  # Return first 5 tags in response
        }


def parse_event_data(record: Dict[str, Any]) -> tuple[str, str, str]:
    """
    Parse event data from either S3 events or custom photo events.

    Supports two event formats:
    1. S3 Event: {"Records": [{"s3": {"object": {"key": "..."}}}]}
    2. Custom Event: {"photoId": "...", "s3Key": "...", "userId": "..."}

    Returns:
        tuple: (photo_id, s3_key, user_id)
    """
    message_body = json.loads(record['body'])

    # Check if it's an S3 event
    if 'Records' in message_body and message_body.get('Records'):
        s3_record = message_body['Records'][0]
        if s3_record.get('eventSource') == 'aws:s3':
            # S3 Event format
            s3_key = s3_record['s3']['object']['key']
            structured_logger.info("Processing S3 event", s3_key=s3_key)

            # Look up photo by S3 key in database
            from db_service import get_db_connection
            with get_db_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        "SELECT id, user_id FROM photos WHERE original_s3_key = %s",
                        (s3_key,)
                    )
                    result = cur.fetchone()
                    if not result:
                        raise ValueError(f"Photo not found for S3 key: {s3_key}")

                    photo_id = str(result[0])
                    user_id = str(result[1])

            return photo_id, s3_key, user_id

    # Custom event format (from backend)
    photo_id = message_body.get('photoId')
    s3_key = message_body.get('s3Key')
    user_id = message_body.get('userId')

    if not all([photo_id, s3_key, user_id]):
        raise ValueError(
            f"Missing required fields. photoId={photo_id}, "
            f"s3Key={s3_key}, userId={user_id}"
        )

    return photo_id, s3_key, user_id


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda entry point for processing SQS messages containing S3 upload events.

    Args:
        event: Lambda event containing SQS records with S3 event payloads
        context: Lambda context object

    Returns:
        Dict with statusCode and processing results

    Supports two event formats:
    1. S3 Events (from S3 bucket notifications)
    2. Custom Photo Events (from backend API)
    """
    records_count = len(event.get('Records', []))
    structured_logger.info("Lambda invocation started", records_count=records_count)

    results: List[Dict[str, Any]] = []
    failures: List[Dict[str, Any]] = []

    try:
        for record in event.get('Records', []):
            message_id = record.get('messageId', 'unknown')

            try:
                structured_logger.info("Processing message", message_id=message_id)

                # Parse event data (handles both S3 and custom events)
                photo_id, s3_key, user_id = parse_event_data(record)

                # Process the image
                result = process_single_image(photo_id, s3_key, user_id)
                result['messageId'] = message_id
                results.append(result)

                structured_logger.info(
                    "Message processed successfully",
                    message_id=message_id,
                    photo_id=photo_id
                )
                increment_counter('message.processed.success')

            except Exception as record_error:
                structured_logger.error(
                    "Failed to process record",
                    message_id=message_id,
                    error=str(record_error)
                )

                # Try to mark photo as failed in database
                try:
                    photo_id = json.loads(record.get('body', '{}')).get('photoId')
                    if photo_id:
                        mark_photo_failed(photo_id, str(record_error))
                except Exception as db_error:
                    logger.warning(f"Failed to mark photo as failed: {db_error}")

                failures.append({
                    'messageId': message_id,
                    'error': str(record_error)
                })
                increment_counter('message.processed.failure')

        # Build response
        response = {
            'statusCode': 200 if not failures else 207,  # 207 Multi-Status
            'body': json.dumps({
                'processed': len(results),
                'failed': len(failures),
                'results': results,
                'failures': failures
            })
        }

        if failures:
            structured_logger.warning(
                "Lambda completed with failures",
                total=records_count,
                succeeded=len(results),
                failed=len(failures)
            )
        else:
            structured_logger.info(
                "Lambda completed successfully",
                total=records_count,
                processed=len(results)
            )

        return response

    except Exception as e:
        structured_logger.error("Fatal error in lambda_handler", error=str(e))
        logger.error(f"Fatal error details:", exc_info=True)
        increment_counter('lambda.fatal_error')

        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e)
            })
        }
