"""
WebP conversion utilities for creating multi-resolution renditions.
"""

import io
import logging
from typing import Any, Dict, List, Tuple

from PIL import Image, ImageOps

from .config import WEBP_QUALITY, WEBP_WIDTHS

logger = logging.getLogger(__name__)


def convert_to_webp(
    image_data: bytes,
    width: int,
    quality: int = WEBP_QUALITY
) -> Tuple[bytes, int, int]:
    """
    Convert image to WebP format at specified width while maintaining aspect ratio.

    Args:
        image_data: Raw image bytes
        width: Target width in pixels
        quality: WebP quality (0-100)

    Returns:
        Tuple of (WebP bytes, width, height)

    Raises:
        ValueError: If image data is invalid or width is non-positive
        IOError: If conversion fails
    """
    if width <= 0:
        raise ValueError(f"Width must be positive, got {width}")

    if not 0 <= quality <= 100:
        raise ValueError(f"Quality must be between 0-100, got {quality}")

    try:
        # Open image from bytes
        with Image.open(io.BytesIO(image_data)) as img:
            # Convert to RGB if necessary
            if img.mode not in ('RGB', 'L'):
                img = img.convert('RGB')

            # Apply EXIF orientation
            img = ImageOps.exif_transpose(img)

            original_width, original_height = img.size

            # Skip if image is smaller than target width
            if original_width <= width:
                target_width = original_width
                target_height = original_height
                logger.info(
                    f"Image smaller than target width {width}px, "
                    f"using original size {original_width}x{original_height}"
                )
            else:
                # Calculate target height maintaining aspect ratio
                aspect_ratio = original_height / original_width
                target_width = width
                target_height = int(width * aspect_ratio)

                # Resize image
                img = img.resize(
                    (target_width, target_height),
                    Image.Resampling.LANCZOS
                )

            # Convert to WebP
            output = io.BytesIO()
            img.save(
                output,
                format='WEBP',
                quality=quality,
                method=6  # Best quality/compression trade-off
            )
            webp_bytes = output.getvalue()

            logger.info(
                f"Converted to WebP: {original_width}x{original_height} -> "
                f"{target_width}x{target_height}, quality={quality}, "
                f"size={len(webp_bytes)} bytes"
            )

            return webp_bytes, target_width, target_height

    except Exception as e:
        logger.error(f"Failed to convert to WebP at width {width}: {str(e)}")
        raise


def create_webp_renditions(
    image_data: bytes,
    widths: List[int] = None,
    quality: int = WEBP_QUALITY
) -> Dict[int, Dict[str, Any]]:
    """
    Create multiple WebP renditions at different widths.

    Args:
        image_data: Raw image bytes
        widths: List of target widths (defaults to WEBP_WIDTHS from config)
        quality: WebP quality (0-100)

    Returns:
        Dictionary mapping width to metadata dict with keys:
        - data: WebP bytes
        - width: actual width
        - height: actual height

    Raises:
        ValueError: If any width is invalid
        IOError: If conversion fails for any rendition
    """
    if widths is None:
        widths = WEBP_WIDTHS

    renditions: Dict[int, Dict[str, bytes | int]] = {}
    errors = []

    for width in widths:
        try:
            webp_data, actual_width, actual_height = convert_to_webp(image_data, width, quality)
            renditions[width] = {
                'data': webp_data,
                'width': actual_width,
                'height': actual_height
            }
        except Exception as e:
            error_msg = f"Failed to create {width}px rendition: {str(e)}"
            logger.error(error_msg)
            errors.append(error_msg)

    if errors and not renditions:
        # All conversions failed
        raise IOError(f"Failed to create any WebP renditions: {'; '.join(errors)}")

    logger.info(
        f"Created {len(renditions)} WebP renditions at widths: "
        f"{sorted(renditions.keys())}"
    )

    return renditions
