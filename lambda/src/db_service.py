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

from .config import DB_HOST, DB_NAME, DB_PASSWORD, DB_PORT, DB_USER

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
    status: str = 'COMPLETED'
) -> None:
    """
    Update photo record with processing results.

    Args:
        photo_id: UUID of the photo
        thumbnail_key: S3 key for the thumbnail
        metadata: Image metadata dictionary
        tags: List of AI-detected tags
        status: Photo status (default: COMPLETED)
    """
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            # Update photo record
            cur.execute(
                """
                UPDATE photos
                SET status = %s,
                    thumbnail_s3_key = %s,
                    width = %s,
                    height = %s,
                    size_bytes = %s,
                    format = %s,
                    tags = %s,
                    processed_at = NOW()
                WHERE id = %s
                """,
                (
                    status,
                    thumbnail_key,
                    metadata.get('width'),
                    metadata.get('height'),
                    metadata.get('size_bytes'),
                    metadata.get('format'),
                    json.dumps(tags),
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
    versions: Dict[int, str]
) -> None:
    """
    Save WebP renditions to photo_versions table.

    Args:
        photo_id: UUID of the photo
        versions: Dictionary mapping width to S3 key
    """
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            for width, s3_key in versions.items():
                cur.execute(
                    """
                    INSERT INTO photo_versions (photo_id, version_type, width, s3_key)
                    VALUES (%s, %s, %s, %s)
                    ON CONFLICT (photo_id, version_type, width)
                    DO UPDATE SET s3_key = EXCLUDED.s3_key, created_at = NOW()
                    """,
                    (photo_id, 'WEBP', width, s3_key)
                )

            logger.info(f"Saved {len(versions)} renditions for photo {photo_id}")


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
