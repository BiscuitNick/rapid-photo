"""
Unit tests for Lambda handler
"""

import json
from unittest.mock import MagicMock, patch

import pytest

from src.handler import lambda_handler, process_single_image


class TestLambdaHandler:
    """Test suite for lambda_handler function"""

    def test_handler_with_empty_records(self):
        """Test handler with empty SQS records"""
        event = {'Records': []}
        context = {}

        response = lambda_handler(event, context)

        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['processed'] == 0
        assert body['failed'] == 0

    def test_handler_with_missing_fields(self):
        """Test handler with record missing required fields"""
        event = {
            'Records': [
                {
                    'messageId': 'test-message-123',
                    'body': json.dumps({
                        'photoId': 'photo-123',
                        's3Key': 'originals/user123/photo.jpg'
                        # Missing userId
                    })
                }
            ]
        }
        context = {}

        response = lambda_handler(event, context)

        assert response['statusCode'] == 207  # Multi-status
        body = json.loads(response['body'])
        assert body['processed'] == 0
        assert body['failed'] == 1

    def test_handler_with_invalid_json(self):
        """Test handler with invalid JSON in record body"""
        event = {
            'Records': [
                {
                    'messageId': 'test-message-123',
                    'body': 'invalid json'
                }
            ]
        }
        context = {}

        response = lambda_handler(event, context)

        assert response['statusCode'] == 207
        body = json.loads(response['body'])
        assert body['failed'] == 1


class TestProcessSingleImage:
    """Test suite for process_single_image function"""

    @patch('src.handler.check_photo_status')
    @patch('src.handler.download_from_s3')
    @patch('src.handler.get_image_metadata')
    @patch('src.handler.create_thumbnail')
    @patch('src.handler.upload_to_s3')
    @patch('src.handler.create_webp_renditions')
    @patch('src.handler.detect_labels')
    @patch('src.handler.extract_tags')
    @patch('src.handler.update_photo_metadata')
    @patch('src.handler.save_photo_versions')
    def test_process_single_image_success(
        self,
        mock_save_versions,
        mock_update_metadata,
        mock_extract_tags,
        mock_detect_labels,
        mock_create_webp,
        mock_upload_s3,
        mock_create_thumb,
        mock_get_metadata,
        mock_download_s3,
        mock_check_status,
    ):
        """Test successful image processing"""
        # Setup mocks
        mock_check_status.return_value = 'PENDING_PROCESSING'
        mock_download_s3.return_value = b'fake image data'
        mock_get_metadata.return_value = {
            'width': 1920,
            'height': 1080,
            'format': 'JPEG',
            'size_bytes': 1000
        }
        mock_create_thumb.return_value = b'thumbnail data'
        mock_create_webp.return_value = {
            640: b'webp640',
            1024: b'webp1024'
        }
        mock_detect_labels.return_value = [
            {'name': 'Nature', 'confidence': 95.0}
        ]
        mock_extract_tags.return_value = ['Nature', 'Landscape']

        # Execute
        result = process_single_image(
            photo_id='photo-123',
            s3_key='originals/user456/photo.jpg',
            user_id='user456'
        )

        # Verify
        assert result['status'] == 'completed'
        assert result['photo_id'] == 'photo-123'
        assert 'thumbnail_key' in result
        assert len(result['renditions']) == 2
        assert result['tags'] == ['Nature', 'Landscape']

        # Verify all steps called
        mock_check_status.assert_called_once_with('photo-123')
        mock_download_s3.assert_called_once()
        mock_create_thumb.assert_called_once()
        mock_create_webp.assert_called_once()
        mock_detect_labels.assert_called_once()
        mock_update_metadata.assert_called_once()
        mock_save_versions.assert_called_once()

    @patch('src.handler.check_photo_status')
    def test_process_single_image_already_processed(self, mock_check_status):
        """Test skipping already processed image (idempotency)"""
        mock_check_status.return_value = 'COMPLETED'

        result = process_single_image(
            photo_id='photo-123',
            s3_key='originals/user456/photo.jpg',
            user_id='user456'
        )

        assert result['status'] == 'skipped'
        assert 'Already in status: COMPLETED' in result['reason']

    @patch('src.handler.check_photo_status')
    @patch('src.handler.download_from_s3')
    def test_process_single_image_download_failure(
        self,
        mock_download_s3,
        mock_check_status,
    ):
        """Test handling of S3 download failure"""
        mock_check_status.return_value = 'PENDING_PROCESSING'
        mock_download_s3.side_effect = Exception('S3 download failed')

        with pytest.raises(Exception, match='S3 download failed'):
            process_single_image(
                photo_id='photo-123',
                s3_key='originals/user456/photo.jpg',
                user_id='user456'
            )
