"""
Image processing utilities for thumbnail generation.
"""

import io
import logging
from typing import BinaryIO, Tuple

from PIL import Image, ImageOps

from config import THUMBNAIL_SIZE

logger = logging.getLogger(__name__)


def create_thumbnail(
    image_data: bytes,
    size: Tuple[int, int] = THUMBNAIL_SIZE,
    format: str = 'JPEG'
) -> bytes:
    """
    Create a center-cropped thumbnail from image data.

    Args:
        image_data: Raw image bytes
        size: Target thumbnail size (width, height)
        format: Output format (JPEG, PNG, etc.)

    Returns:
        Thumbnail image as bytes

    Raises:
        ValueError: If image data is invalid
        IOError: If image processing fails
    """
    try:
        # Open image from bytes
        with Image.open(io.BytesIO(image_data)) as img:
            # Convert to RGB if necessary (handles RGBA, P, etc.)
            if img.mode not in ('RGB', 'L'):
                img = img.convert('RGB')

            # Apply EXIF orientation
            img = ImageOps.exif_transpose(img)

            # Calculate center crop dimensions
            img_width, img_height = img.size
            target_width, target_height = size
            target_aspect = target_width / target_height
            img_aspect = img_width / img_height

            if img_aspect > target_aspect:
                # Image is wider than target - crop width
                new_width = int(img_height * target_aspect)
                left = (img_width - new_width) // 2
                img = img.crop((left, 0, left + new_width, img_height))
            elif img_aspect < target_aspect:
                # Image is taller than target - crop height
                new_height = int(img_width / target_aspect)
                top = (img_height - new_height) // 2
                img = img.crop((0, top, img_width, top + new_height))

            # Resize to target dimensions
            img = img.resize(size, Image.Resampling.LANCZOS)

            # Save to bytes buffer
            output = io.BytesIO()
            save_kwargs = {'format': format}

            if format.upper() == 'JPEG':
                save_kwargs['quality'] = 85
                save_kwargs['optimize'] = True

            img.save(output, **save_kwargs)
            thumbnail_bytes = output.getvalue()

            logger.info(
                f"Created thumbnail: original={img_width}x{img_height}, "
                f"thumbnail={target_width}x{target_height}, "
                f"size={len(thumbnail_bytes)} bytes"
            )

            return thumbnail_bytes

    except Exception as e:
        logger.error(f"Failed to create thumbnail: {str(e)}")
        raise


def get_image_metadata(image_data: bytes) -> dict:
    """
    Extract metadata from image.

    Args:
        image_data: Raw image bytes

    Returns:
        Dictionary containing image metadata
    """
    try:
        with Image.open(io.BytesIO(image_data)) as img:
            return {
                'width': img.size[0],
                'height': img.size[1],
                'format': img.format,
                'mode': img.mode,
                'size_bytes': len(image_data)
            }
    except Exception as e:
        logger.error(f"Failed to extract image metadata: {str(e)}")
        return {}
