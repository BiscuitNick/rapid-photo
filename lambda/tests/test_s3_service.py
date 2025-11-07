"""
Tests for s3_service module
"""

import boto3
import pytest
from moto import mock_aws

from src.s3_service import (
    download_from_s3,
    generate_processed_keys,
    upload_to_s3,
)


@mock_aws
class TestS3Service:
    """Test suite for S3 service functions"""

    def setup_method(self):
        """Setup S3 mock before each test"""
        self.s3_client = boto3.client('s3', region_name='us-east-1')
        self.bucket = 'test-bucket'
        self.s3_client.create_bucket(Bucket=self.bucket)

    def test_upload_to_s3(self):
        """Test uploading data to S3"""
        data = b'test image data'
        key = 'test/image.jpg'

        s3_uri = upload_to_s3(data, key, bucket=self.bucket, content_type='image/jpeg')

        assert s3_uri == f's3://{self.bucket}/{key}'

        # Verify upload
        obj = self.s3_client.get_object(Bucket=self.bucket, Key=key)
        assert obj['Body'].read() == data
        assert obj['ContentType'] == 'image/jpeg'

    def test_upload_to_s3_with_metadata(self):
        """Test uploading with custom metadata"""
        data = b'test data'
        key = 'test/file.txt'
        metadata = {'user': 'test-user', 'version': '1.0'}

        upload_to_s3(data, key, bucket=self.bucket, metadata=metadata)

        obj = self.s3_client.get_object(Bucket=self.bucket, Key=key)
        assert obj['Metadata'] == metadata

    def test_download_from_s3(self):
        """Test downloading data from S3"""
        data = b'test download data'
        key = 'test/download.jpg'

        # Upload first
        self.s3_client.put_object(Bucket=self.bucket, Key=key, Body=data)

        # Download
        downloaded = download_from_s3(key, bucket=self.bucket)

        assert downloaded == data

    def test_download_from_s3_not_found(self):
        """Test downloading non-existent object"""
        from botocore.exceptions import ClientError

        with pytest.raises(ClientError):
            download_from_s3('non-existent-key', bucket=self.bucket)

    def test_generate_processed_keys_thumbnail(self):
        """Test generating thumbnail key"""
        original_key = 'originals/user123/photo-abc.jpg'

        thumbnail_key = generate_processed_keys(original_key, width=None)

        assert thumbnail_key == 'thumbnails/user123/photo-abc.jpg'

    def test_generate_processed_keys_webp_rendition(self):
        """Test generating WebP rendition key"""
        original_key = 'originals/user456/image-xyz.png'

        rendition_key = generate_processed_keys(original_key, width=1024)

        assert rendition_key == 'processed/user456/image-xyz-1024.webp'

    def test_generate_processed_keys_various_widths(self):
        """Test generating keys for different widths"""
        original_key = 'originals/user789/photo.jpg'

        key_640 = generate_processed_keys(original_key, width=640)
        key_1920 = generate_processed_keys(original_key, width=1920)

        assert key_640 == 'processed/user789/photo-640.webp'
        assert key_1920 == 'processed/user789/photo-1920.webp'

    def test_generate_processed_keys_invalid_format(self):
        """Test generating keys with invalid original key format"""
        with pytest.raises(ValueError):
            generate_processed_keys('invalid/key.jpg', width=None)

        with pytest.raises(ValueError):
            generate_processed_keys('wrong-prefix/user/file.jpg', width=1024)
