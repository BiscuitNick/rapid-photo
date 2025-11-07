"""
Tests for image_processor module
"""

import io

import pytest
from PIL import Image

from src.image_processor import create_thumbnail, get_image_metadata


def create_test_image(width: int = 1000, height: int = 1000, mode: str = 'RGB') -> bytes:
    """Helper to create test image bytes."""
    img = Image.new(mode, (width, height), color='blue')
    buffer = io.BytesIO()
    img.save(buffer, format='JPEG')
    return buffer.getvalue()


class TestImageProcessor:
    """Test suite for image processing functions"""

    def test_create_thumbnail_square_image(self):
        """Test thumbnail creation from square image"""
        image_data = create_test_image(1000, 1000)

        thumbnail = create_thumbnail(image_data, size=(300, 300))

        assert thumbnail is not None
        assert isinstance(thumbnail, bytes)

        # Verify thumbnail dimensions
        thumb_img = Image.open(io.BytesIO(thumbnail))
        assert thumb_img.size == (300, 300)

    def test_create_thumbnail_wide_image(self):
        """Test thumbnail creation from wide image (crops width)"""
        image_data = create_test_image(2000, 1000)

        thumbnail = create_thumbnail(image_data, size=(300, 300))

        thumb_img = Image.open(io.BytesIO(thumbnail))
        assert thumb_img.size == (300, 300)

    def test_create_thumbnail_tall_image(self):
        """Test thumbnail creation from tall image (crops height)"""
        image_data = create_test_image(1000, 2000)

        thumbnail = create_thumbnail(image_data, size=(300, 300))

        thumb_img = Image.open(io.BytesIO(thumbnail))
        assert thumb_img.size == (300, 300)

    def test_create_thumbnail_rgba_conversion(self):
        """Test thumbnail handles RGBA images by converting to RGB"""
        image_data = create_test_image(1000, 1000, mode='RGBA')

        thumbnail = create_thumbnail(image_data, format='JPEG')

        thumb_img = Image.open(io.BytesIO(thumbnail))
        assert thumb_img.mode == 'RGB'

    def test_create_thumbnail_custom_size(self):
        """Test thumbnail with custom dimensions"""
        image_data = create_test_image(1000, 1000)

        thumbnail = create_thumbnail(image_data, size=(200, 100))

        thumb_img = Image.open(io.BytesIO(thumbnail))
        assert thumb_img.size == (200, 100)

    def test_create_thumbnail_invalid_data(self):
        """Test thumbnail creation with invalid image data"""
        with pytest.raises(Exception):
            create_thumbnail(b'invalid image data')

    def test_get_image_metadata(self):
        """Test metadata extraction"""
        image_data = create_test_image(1920, 1080)

        metadata = get_image_metadata(image_data)

        assert metadata['width'] == 1920
        assert metadata['height'] == 1080
        assert metadata['format'] == 'JPEG'
        assert metadata['mode'] == 'RGB'
        assert metadata['size_bytes'] == len(image_data)

    def test_get_image_metadata_invalid_data(self):
        """Test metadata extraction with invalid data"""
        metadata = get_image_metadata(b'invalid')

        assert metadata == {}
