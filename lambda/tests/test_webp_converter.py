"""
Tests for webp_converter module
"""

import io

import pytest
from PIL import Image, ImageChops

from src.webp_converter import convert_to_webp, create_webp_renditions


def create_test_image(width: int = 1920, height: int = 1080) -> bytes:
    """Helper to create test image bytes with meaningful detail."""
    gradient_x = Image.linear_gradient('L').resize((width, height))
    gradient_y = Image.linear_gradient('L').transpose(Image.Transpose.ROTATE_90).resize((width, height))
    gradient_mix = ImageChops.add_modulo(gradient_x, gradient_y)
    img = Image.merge('RGB', (gradient_x, gradient_y, gradient_mix))
    buffer = io.BytesIO()
    img.save(buffer, format='JPEG', quality=90)
    return buffer.getvalue()


class TestWebPConverter:
    """Test suite for WebP conversion functions"""

    def test_convert_to_webp_basic(self):
        """Test basic WebP conversion"""
        image_data = create_test_image(1920, 1080)

        webp_data, out_width, out_height = convert_to_webp(image_data, width=1024, quality=80)

        assert webp_data is not None
        assert isinstance(webp_data, bytes)
        assert out_width == 1024
        assert out_height > 0

        # Verify format is WebP
        webp_img = Image.open(io.BytesIO(webp_data))
        assert webp_img.format == 'WEBP'

    def test_convert_to_webp_maintains_aspect_ratio(self):
        """Test WebP conversion maintains aspect ratio"""
        image_data = create_test_image(1920, 1080)

        webp_data, out_width, out_height = convert_to_webp(image_data, width=960)

        assert (out_width, out_height) == (960, 540)

    def test_convert_to_webp_smaller_than_target(self):
        """Test conversion when image is smaller than target width"""
        image_data = create_test_image(640, 480)

        webp_data, out_width, out_height = convert_to_webp(image_data, width=1920)

        assert (out_width, out_height) == (640, 480)

    def test_convert_to_webp_custom_quality(self):
        """Test WebP conversion with different quality settings"""
        image_data = create_test_image(1920, 1080)

        high_quality, *_ = convert_to_webp(image_data, width=1024, quality=95)
        low_quality, *_ = convert_to_webp(image_data, width=1024, quality=50)

        # Higher quality should result in larger file size
        assert len(high_quality) > len(low_quality)

    def test_convert_to_webp_invalid_width(self):
        """Test conversion with invalid width"""
        image_data = create_test_image(1920, 1080)

        with pytest.raises(ValueError):
            convert_to_webp(image_data, width=0)

        with pytest.raises(ValueError):
            convert_to_webp(image_data, width=-100)

    def test_convert_to_webp_invalid_quality(self):
        """Test conversion with invalid quality"""
        image_data = create_test_image(1920, 1080)

        with pytest.raises(ValueError):
            convert_to_webp(image_data, width=1024, quality=101)

        with pytest.raises(ValueError):
            convert_to_webp(image_data, width=1024, quality=-1)

    def test_convert_to_webp_invalid_data(self):
        """Test conversion with invalid image data"""
        with pytest.raises(Exception):
            convert_to_webp(b'invalid data', width=1024)

    def test_create_webp_renditions_default_widths(self):
        """Test creating multiple renditions with default widths"""
        image_data = create_test_image(3840, 2160)  # 4K image

        renditions = create_webp_renditions(image_data)

        # Should have renditions for all default widths
        assert len(renditions) >= 3
        assert all(isinstance(width, int) for width in renditions.keys())
        assert all(
            isinstance(info['data'], bytes) and isinstance(info['height'], int)
            for info in renditions.values()
        )

    def test_create_webp_renditions_custom_widths(self):
        """Test creating renditions with custom widths"""
        image_data = create_test_image(2000, 1500)
        custom_widths = [320, 640, 1280]

        renditions = create_webp_renditions(image_data, widths=custom_widths)

        assert len(renditions) == 3
        assert set(renditions.keys()) == set(custom_widths)

    def test_create_webp_renditions_verifies_dimensions(self):
        """Test that renditions have correct dimensions"""
        image_data = create_test_image(1920, 1080)

        renditions = create_webp_renditions(image_data, widths=[640, 1024])

        # Verify 640px rendition
        img_640 = Image.open(io.BytesIO(renditions[640]['data']))
        assert img_640.size == (640, 360)  # Maintains 16:9 ratio

        # Verify 1024px rendition
        img_1024 = Image.open(io.BytesIO(renditions[1024]['data']))
        assert img_1024.size == (1024, 576)

    def test_create_webp_renditions_invalid_data(self):
        """Test renditions creation with invalid image data"""
        with pytest.raises(IOError):
            create_webp_renditions(b'invalid data', widths=[640, 1024])
