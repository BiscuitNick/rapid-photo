"""
PostgreSQL database service for photo metadata persistence.
"""

import json
import logging
from contextlib import contextmanager
from typing import Dict, List, Optional

import psycopg2
from psycopg2 import pool
from psycopg2.extras import RealDictCursor

from config import DB_HOST, DB_NAME, DB_PASSWORD, DB_PORT, DB_USER

logger = logging.getLogger(__name__)

# Connection pool (initialized lazily)
_connection_pool: Optional[pool.SimpleConnectionPool] = None


def get_connection_pool() -> pool.SimpleConnectionPool:
    """
    Get or create the connection pool.

    Returns:
        SimpleConnectionPool instance
    """
    global _connection_pool

    if _connection_pool is None:
        logger.info("Initializing database connection pool")
        _connection_pool = pool.SimpleConnectionPool(
            minconn=1,
            maxconn=5,
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            keepalives=1,
            keepalives_idle=30,
            keepalives_interval=10,
            keepalives_count=5
        )
        logger.info("Database connection pool initialized")

    return _connection_pool


@contextmanager
def get_db_connection():
    """
    Context manager for database connections from pool.

    Yields:
        psycopg2 connection

    Example:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
    """
    conn = None
    try:
        pool = get_connection_pool()
        conn = pool.getconn()
        yield conn
        conn.commit()
    except Exception as e:
        if conn:
            conn.rollback()
        logger.error(f"Database error: {str(e)}")
        raise
    finally:
        if conn:
            pool.putconn(conn)


def check_photo_status(photo_id: str) -> Optional[str]:
    """
    Check if a photo has already been processed (idempotency check).

    Args:
        photo_id: UUID of the photo

    Returns:
        Current photo status or None if not found
    """
    with get_db_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(
                "SELECT status FROM photos WHERE id = %s",
                (photo_id,)
            )
            row = cur.fetchone()
            if row:
                status = row['status']
                logger.info(f"Photo {photo_id} current status: {status}")
                return status
            else:
                logger.warning(f"Photo {photo_id} not found in database")
                return None


def update_photo_metadata(
    photo_id: str,
    thumbnail_key: str,
    metadata: Dict,
    tags: List[str],
    status: str = 'READY'
) -> None:
    """
    Update photo record with processing results.

    Args:
        photo_id: UUID of the photo
        thumbnail_key: S3 key for the thumbnail
        metadata: Image metadata dictionary
        tags: List of AI-detected tags
        status: Photo status (default: READY)
    """
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            # Update photo record
            cur.execute(
                """
                UPDATE photos
                SET status = %s,
                    width = %s,
                    height = %s,
                    processed_at = NOW()
                WHERE id = %s
                """,
                (
                    status,
                    metadata.get('width'),
                    metadata.get('height'),
                    photo_id
                )
            )

            rows_updated = cur.rowcount
            if rows_updated == 0:
                logger.warning(f"Photo {photo_id} not found, no rows updated")
            else:
                logger.info(f"Updated photo {photo_id} with metadata and {len(tags)} tags")


def save_photo_versions(
    photo_id: str,
    versions: Dict[int, str],
    thumbnail_key: str = None
) -> None:
    """
    Save WebP renditions and thumbnail to photo_versions table.

    Args:
        photo_id: UUID of the photo
        versions: Dictionary mapping width to S3 key (for WebP versions)
        thumbnail_key: Optional S3 key for thumbnail
    """
    import boto3
    from .config import S3_BUCKET, AWS_REGION

    s3_client = boto3.client('s3', region_name=AWS_REGION)

    # Map widths to version type enum values
    width_to_version_type = {
        640: 'WEBP_640',
        1280: 'WEBP_1280',
        1920: 'WEBP_1920',
        2560: 'WEBP_2560'
    }

    with get_db_connection() as conn:
        with conn.cursor() as cur:
            # Save thumbnail if provided
            if thumbnail_key:
                try:
                    thumb_meta = s3_client.head_object(Bucket=S3_BUCKET, Key=thumbnail_key)
                    # Thumbnail is 300x300
                    cur.execute(
                        """
                        INSERT INTO photo_versions (photo_id, version_type, s3_key, file_size, width, height, mime_type)
                        VALUES (%s, %s, %s, %s, %s, %s, %s)
                        ON CONFLICT (photo_id, version_type)
                        DO UPDATE SET s3_key = EXCLUDED.s3_key, file_size = EXCLUDED.file_size, created_at = NOW()
                        """,
                        (photo_id, 'THUMBNAIL', thumbnail_key, thumb_meta['ContentLength'], 300, 300, 'image/jpeg')
                    )
                except Exception as e:
                    logger.warning(f"Failed to save thumbnail version: {e}")

            # Save WebP versions
            for width, s3_key in versions.items():
                version_type = width_to_version_type.get(width)
                if not version_type:
                    logger.warning(f"Unknown width {width}, skipping")
                    continue

                try:
                    # Get file size from S3
                    obj_meta = s3_client.head_object(Bucket=S3_BUCKET, Key=s3_key)
                    file_size = obj_meta['ContentLength']

                    # Calculate height from original aspect ratio
                    # Get original photo dimensions from photos table
                    cur.execute("SELECT width, height FROM photos WHERE id = %s", (photo_id,))
                    result = cur.fetchone()
                    if result and result[0] and result[1]:
                        orig_width, orig_height = result[0], result[1]
                        aspect_ratio = orig_height / orig_width
                        calc_height = int(width * aspect_ratio)
                    else:
                        # Fallback: assume square
                        calc_height = width

                    cur.execute(
                        """
                        INSERT INTO photo_versions (photo_id, version_type, s3_key, file_size, width, height, mime_type)
                        VALUES (%s, %s, %s, %s, %s, %s, %s)
                        ON CONFLICT (photo_id, version_type)
                        DO UPDATE SET s3_key = EXCLUDED.s3_key, file_size = EXCLUDED.file_size, created_at = NOW()
                        """,
                        (photo_id, version_type, s3_key, file_size, width, calc_height, 'image/webp')
                    )
                except Exception as e:
                    logger.error(f"Failed to save version {version_type}: {e}")

            logger.info(f"Saved {len(versions)} renditions for photo {photo_id}")


def save_photo_labels(photo_id: str, labels: List[str], confidences: Dict[str, float]) -> None:
    """
    Save AI-detected labels to photo_labels table.

    Args:
        photo_id: UUID of the photo
        labels: List of label names
        confidences: Dictionary mapping label name to confidence score
    """
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            for label in labels:
                confidence = confidences.get(label, 0.0)
                try:
                    cur.execute(
                        """
                        INSERT INTO photo_labels (photo_id, label_name, confidence)
                        VALUES (%s, %s, %s)
                        ON CONFLICT (photo_id, label_name)
                        DO UPDATE SET confidence = EXCLUDED.confidence, created_at = NOW()
                        """,
                        (photo_id, label, confidence)
                    )
                except Exception as e:
                    logger.error(f"Failed to save label {label}: {e}")

            logger.info(f"Saved {len(labels)} labels for photo {photo_id}")


def mark_photo_failed(photo_id: str, error_message: str) -> None:
    """
    Mark photo as failed with error message.

    Args:
        photo_id: UUID of the photo
        error_message: Error description
    """
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                UPDATE photos
                SET status = 'FAILED',
                    error_message = %s,
                    processed_at = NOW()
                WHERE id = %s
                """,
                (error_message, photo_id)
            )

            logger.warning(f"Marked photo {photo_id} as FAILED: {error_message}")


def close_connection_pool():
    """Close all connections in the pool."""
    global _connection_pool
    if _connection_pool:
        _connection_pool.closeall()
        _connection_pool = None
        logger.info("Database connection pool closed")
