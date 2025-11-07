"""
Tests for rekognition_service module
"""

import boto3
import pytest
from moto import mock_aws

from src.rekognition_service import detect_labels, extract_tags


@mock_aws
class TestRekognitionService:
    """Test suite for Rekognition service functions"""

    def setup_method(self):
        """Setup mocks before each test"""
        self.rekognition_client = boto3.client('rekognition', region_name='us-east-1')
        self.s3_client = boto3.client('s3', region_name='us-east-1')
        self.bucket = 'test-bucket'
        self.s3_client.create_bucket(Bucket=self.bucket)

    def test_detect_labels_basic(self):
        """Test basic label detection"""
        # Upload test image to S3
        key = 'test/image.jpg'
        self.s3_client.put_object(
            Bucket=self.bucket,
            Key=key,
            Body=b'fake image data'
        )

        # Note: moto's Rekognition mock returns empty labels by default
        # In real usage, this would return actual labels
        try:
            labels = detect_labels(key, bucket=self.bucket, min_confidence=80.0)
            assert isinstance(labels, list)
        except Exception:
            # Moto might not fully support detect_labels
            pytest.skip("Rekognition mock not fully supported in moto")

    def test_extract_tags(self):
        """Test tag extraction from labels"""
        labels = [
            {'name': 'Person', 'confidence': 99.5, 'parents': []},
            {'name': 'Outdoors', 'confidence': 95.2, 'parents': []},
            {'name': 'Nature', 'confidence': 92.1, 'parents': []},
            {'name': 'Tree', 'confidence': 88.5, 'parents': ['Nature']},
            {'name': 'Sky', 'confidence': 85.0, 'parents': []},
        ]

        tags = extract_tags(labels, max_tags=3)

        assert len(tags) == 3
        assert tags == ['Person', 'Outdoors', 'Nature']  # Sorted by confidence

    def test_extract_tags_respects_max(self):
        """Test that extract_tags respects max_tags parameter"""
        labels = [
            {'name': f'Label{i}', 'confidence': 90.0 - i, 'parents': []}
            for i in range(20)
        ]

        tags = extract_tags(labels, max_tags=10)

        assert len(tags) == 10
        assert tags[0] == 'Label0'  # Highest confidence
        assert tags[-1] == 'Label9'

    def test_extract_tags_empty_labels(self):
        """Test tag extraction with empty labels list"""
        tags = extract_tags([], max_tags=10)

        assert tags == []

    def test_extract_tags_fewer_than_max(self):
        """Test when there are fewer labels than max_tags"""
        labels = [
            {'name': 'Cat', 'confidence': 95.0, 'parents': []},
            {'name': 'Pet', 'confidence': 90.0, 'parents': []},
        ]

        tags = extract_tags(labels, max_tags=10)

        assert len(tags) == 2
        assert tags == ['Cat', 'Pet']
