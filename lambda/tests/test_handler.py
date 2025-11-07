"""
Unit tests for Lambda handler
"""

import json
import pytest
from src.handler import lambda_handler


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

    def test_handler_with_valid_record(self):
        """Test handler with valid SQS record"""
        event = {
            'Records': [
                {
                    'messageId': 'test-message-123',
                    'body': json.dumps({
                        's3Key': 'originals/user123/photo.jpg',
                        'uploadJobId': 'job-456'
                    })
                }
            ]
        }
        context = {}

        response = lambda_handler(event, context)

        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['processed'] == 1
        assert body['failed'] == 0

    def test_handler_with_missing_fields(self):
        """Test handler with record missing required fields"""
        event = {
            'Records': [
                {
                    'messageId': 'test-message-123',
                    'body': json.dumps({
                        's3Key': 'originals/user123/photo.jpg'
                        # Missing uploadJobId
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
