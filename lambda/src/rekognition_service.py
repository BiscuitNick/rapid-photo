"""
AWS Rekognition service for AI-powered label detection.
"""

import logging
from typing import Dict, List

import boto3
from botocore.exceptions import ClientError

from .config import (
    AWS_REGION,
    REKOGNITION_MAX_LABELS,
    REKOGNITION_MIN_CONFIDENCE,
    S3_BUCKET
)

logger = logging.getLogger(__name__)

# Initialize Rekognition client
rekognition_client = boto3.client('rekognition', region_name=AWS_REGION)


def detect_labels(
    s3_key: str,
    bucket: str = S3_BUCKET,
    min_confidence: float = REKOGNITION_MIN_CONFIDENCE,
    max_labels: int = REKOGNITION_MAX_LABELS
) -> List[Dict[str, any]]:
    """
    Detect labels in an image using AWS Rekognition.

    Args:
        s3_key: S3 object key
        bucket: S3 bucket name
        min_confidence: Minimum confidence threshold (0-100)
        max_labels: Maximum number of labels to return

    Returns:
        List of detected labels with confidence scores

    Example:
        [
            {"Name": "Person", "Confidence": 99.5, "Parents": [{"Name": "Human"}]},
            {"Name": "Outdoors", "Confidence": 95.2, "Parents": []}
        ]

    Raises:
        ClientError: If Rekognition API call fails
    """
    try:
        logger.info(
            f"Detecting labels for s3://{bucket}/{s3_key} "
            f"(min_confidence={min_confidence}, max_labels={max_labels})"
        )

        response = rekognition_client.detect_labels(
            Image={
                'S3Object': {
                    'Bucket': bucket,
                    'Name': s3_key
                }
            },
            MaxLabels=max_labels,
            MinConfidence=min_confidence
        )

        labels = response.get('Labels', [])

        # Extract relevant information
        processed_labels = []
        for label in labels:
            processed_label = {
                'name': label['Name'],
                'confidence': round(label['Confidence'], 2),
                'parents': [p['Name'] for p in label.get('Parents', [])]
            }
            processed_labels.append(processed_label)

        logger.info(
            f"Detected {len(processed_labels)} labels: "
            f"{[l['name'] for l in processed_labels[:5]]}..."
        )

        return processed_labels

    except ClientError as e:
        error_code = e.response.get('Error', {}).get('Code', 'Unknown')
        logger.error(f"Failed to detect labels: {error_code} - {str(e)}")
        raise


def extract_tags(labels: List[Dict[str, any]], max_tags: int = 10) -> List[str]:
    """
    Extract tag names from Rekognition labels.

    Args:
        labels: List of labels from detect_labels()
        max_tags: Maximum number of tags to extract

    Returns:
        List of tag names sorted by confidence
    """
    # Sort by confidence (descending) and take top tags
    sorted_labels = sorted(labels, key=lambda x: x['confidence'], reverse=True)
    tags = [label['name'] for label in sorted_labels[:max_tags]]

    logger.info(f"Extracted {len(tags)} tags from {len(labels)} labels")
    return tags
