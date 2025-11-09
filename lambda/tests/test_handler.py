"""
Unit tests for Lambda handler
"""

import json
from unittest.mock import patch

import pytest

from src.handler import lambda_handler, process_single_image


class TestLambdaHandler:
    """Test suite for lambda_handler function."""

    @patch('src.handler.increment_counter')
    def test_handler_with_empty_records(self, mock_counter):
        """Handler should return success when no records are provided."""
        event = {'Records': []}

        response = lambda_handler(event, context={})

        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['processed'] == 0
        assert body['failed'] == 0
        mock_counter.assert_not_called()

    @patch('src.handler.increment_counter')
    def test_handler_with_missing_fields(self, mock_counter):
        """Handler should record failures when fields are missing."""
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

        response = lambda_handler(event, context={})

        assert response['statusCode'] == 207
        body = json.loads(response['body'])
        assert body['processed'] == 0
        assert body['failed'] == 1
        mock_counter.assert_called_once()

    @patch('src.handler.increment_counter')
    def test_handler_with_invalid_json(self, mock_counter):
        """Handler should handle invalid JSON payloads gracefully."""
        event = {
            'Records': [
                {
                    'messageId': 'test-message-123',
                    'body': 'invalid json'
                }
            ]
        }

        response = lambda_handler(event, context={})

        assert response['statusCode'] == 207
        body = json.loads(response['body'])
        assert body['failed'] == 1
        mock_counter.assert_called_once()

    @patch('src.handler.process_single_image')
    @patch('src.handler.increment_counter')
    def test_handler_processes_s3_event(self, mock_counter, mock_process):
        """Handler should parse direct S3 events and process the image."""
        mock_process.return_value = {
            'photo_id': 'photo-abc',
            's3_key': 'originals/user123/photo-abc.jpg',
            'status': 'completed',
            'thumbnail_key': 'thumbnails/user123/photo-abc.jpg',
            'metadata': {},
            'renditions': [],
            'tags': [],
            'label_count': 0
        }

        event = {
            'Records': [
                {
                    'eventSource': 'aws:s3',
                    'eventID': 'evt-123',
                    's3': {
                        'bucket': {'name': 'rapid-photo-uploads'},
                        'object': {'key': 'originals/user123/photo-abc.jpg'}
                    }
                }
            ]
        }

        response = lambda_handler(event, context={})

        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['processed'] == 1
        mock_process.assert_called_once_with('photo-abc', 'originals/user123/photo-abc.jpg', 'user123', notify_backend=True)
        assert mock_counter.call_count == 1  # Handler success increment


class TestProcessSingleImage:
    """Test suite for process_single_image function."""

    @patch('src.handler.timed_operation')
    @patch('src.handler.increment_counter')
    @patch('src.handler.notify_backend_complete')
    @patch('src.handler.extract_tags')
    @patch('src.handler.detect_labels')
    @patch('src.handler.create_webp_renditions')
    @patch('src.handler.upload_to_s3')
    @patch('src.handler.create_thumbnail')
    @patch('src.handler.get_image_metadata')
    @patch('src.handler.download_from_s3')
    def test_process_single_image_success(
        self,
        mock_download,
        mock_metadata,
        mock_thumbnail,
        mock_upload,
        mock_webp,
        mock_detect_labels,
        mock_extract_tags,
        mock_notify_backend,
        mock_increment,
        mock_timed_operation,
    ):
        """Image processing should generate thumbnail, renditions, labels, and notify backend."""
        mock_download.return_value = b'fake image data'
        mock_metadata.return_value = {
            'width': 1920,
            'height': 1080,
            'format': 'JPEG',
            'size_bytes': 2048
        }
        mock_thumbnail.return_value = b'thumbnail data'
        mock_webp.return_value = {
            640: b'webp640',
            1280: b'webp1280',
        }
        mock_detect_labels.return_value = [
            {'name': 'Nature', 'confidence': 95.0, 'parents': []}
        ]
        mock_extract_tags.return_value = ['Nature']
        mock_timed_operation.return_value.__enter__.return_value = None
        mock_timed_operation.return_value.__exit__.return_value = None

        result = process_single_image(
            photo_id='photo-123',
            s3_key='originals/user456/photo.jpg',
            user_id='user456'
        )

        assert result['status'] == 'completed'
        assert result['thumbnail_key'] == 'thumbnails/user456/photo.jpg'
        assert len(result['renditions']) == 2
        assert result['renditions'][0]['width'] == 640
        assert result['tags'] == ['Nature']
        assert result['label_count'] == 1
        assert mock_upload.call_count == 3  # 1 thumbnail + 2 renditions
        mock_notify_backend.assert_called_once()

    @patch('src.handler.timed_operation')
    @patch('src.handler.increment_counter')
    @patch('src.handler.notify_backend_complete')
    @patch('src.handler.extract_tags')
    @patch('src.handler.detect_labels')
    @patch('src.handler.create_webp_renditions')
    @patch('src.handler.upload_to_s3')
    @patch('src.handler.create_thumbnail')
    @patch('src.handler.get_image_metadata')
    @patch('src.handler.download_from_s3')
    def test_process_single_image_can_skip_backend(
        self,
        mock_download,
        mock_metadata,
        mock_thumbnail,
        mock_upload,
        mock_webp,
        mock_detect_labels,
        mock_extract_tags,
        mock_notify_backend,
        mock_increment,
        mock_timed_operation,
    ):
        """Backend notification can be skipped when requested."""
        mock_download.return_value = b'data'
        mock_metadata.return_value = {'width': 100, 'height': 100, 'format': 'JPEG', 'size_bytes': 10}
        mock_thumbnail.return_value = b'thumb'
        mock_webp.return_value = {640: b'webp'}
        mock_detect_labels.return_value = [{'name': 'Sky', 'confidence': 90.0, 'parents': []}]
        mock_extract_tags.return_value = ['Sky']
        mock_timed_operation.return_value.__enter__.return_value = None
        mock_timed_operation.return_value.__exit__.return_value = None

        result = process_single_image(
            photo_id='photo-999',
            s3_key='originals/user999/photo-999.jpg',
            user_id='user999',
            notify_backend=False
        )

        assert result['status'] == 'completed'
        mock_notify_backend.assert_not_called()

    @patch('src.handler.timed_operation')
    @patch('src.handler.increment_counter')
    @patch('src.handler.download_from_s3')
    def test_process_single_image_download_failure(
        self,
        mock_download,
        mock_increment,
        mock_timed_operation,
    ):
        """Download failures should bubble up to the caller."""
        mock_download.side_effect = Exception('S3 download failed')
        mock_timed_operation.return_value.__enter__.return_value = None
        mock_timed_operation.return_value.__exit__.return_value = None

        with pytest.raises(Exception, match='S3 download failed'):
            process_single_image(
                photo_id='photo-123',
                s3_key='originals/user456/photo.jpg',
                user_id='user456'
            )
