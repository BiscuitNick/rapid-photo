#!/usr/bin/env python3
"""
Local test runner for Lambda image processing function.

Usage:
    python run-local-test.py [test-image.jpg]

If no image is specified, uses test-assets/test-image-small.jpg
"""

import os
import sys
import json
import uuid
from pathlib import Path
from datetime import datetime
from typing import Optional

# Load environment variables
from dotenv import load_dotenv
load_dotenv('.env.local')

import boto3
from src.handler import lambda_handler

# Configuration
S3_BUCKET = os.getenv('S3_BUCKET', 'amplify-rapidphotoweb-nic-rapidphotouploadsbucketc-cvzqed1qst7p')
AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')
TEST_USER_ID = 'test-user-local'


def create_test_user_and_upload_job() -> tuple[str, str]:
    """
    Create a test user and upload job in the database.

    Returns:
        tuple: (user_id, upload_job_id)
    """
    import psycopg2

    user_id = str(uuid.uuid4())
    upload_job_id = str(uuid.uuid4())

    try:
        conn = psycopg2.connect(
            host=os.getenv('DB_HOST', 'localhost'),
            port=int(os.getenv('DB_PORT', 5432)),
            database=os.getenv('DB_NAME', 'rapidphoto'),
            user=os.getenv('DB_USER', 'rapidphoto'),
            password=os.getenv('DB_PASSWORD', 'rapidphoto_dev')
        )
        cur = conn.cursor()

        # Create user if not exists
        cur.execute("""
            INSERT INTO users (id, cognito_user_id, email, created_at, updated_at)
            VALUES (%s, %s, %s, NOW(), NOW())
            ON CONFLICT (cognito_user_id) DO NOTHING
        """, (user_id, 'test-user-local', 'test@local.dev'))

        # Create upload job
        cur.execute("""
            INSERT INTO upload_jobs (id, user_id, s3_key, presigned_url, file_name, file_size, mime_type, status, expires_at, created_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, NOW() + INTERVAL '1 hour', NOW())
        """, (upload_job_id, user_id, 'temp', 'http://example.com', 'test.jpg', 8660, 'image/jpeg', 'CONFIRMED'))

        conn.commit()
        cur.close()
        conn.close()

        return user_id, upload_job_id

    except Exception as e:
        print(f"   ⚠️  Failed to create test user/upload job: {e}")
        raise


def upload_test_image_to_s3(image_path: str, user_id: str, upload_job_id: str) -> tuple[str, str]:
    """
    Upload a test image to S3 and create photo record in database.

    Returns:
        tuple: (s3_key, photo_id)
    """
    import psycopg2
    from PIL import Image

    print(f"\n📤 Uploading test image to S3...")
    print(f"   Image: {image_path}")
    print(f"   Bucket: {S3_BUCKET}")

    # Generate unique identifiers
    photo_id = str(uuid.uuid4())
    timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
    filename = Path(image_path).name
    s3_key = f"originals/{TEST_USER_ID}/{timestamp}-{photo_id}-{filename}"

    # Get image dimensions
    with Image.open(image_path) as img:
        width, height = img.size

    # Upload to S3
    s3_client = boto3.client('s3', region_name=AWS_REGION)

    try:
        with open(image_path, 'rb') as f:
            file_size = os.path.getsize(image_path)
            s3_client.upload_fileobj(
                f,
                S3_BUCKET,
                s3_key,
                ExtraArgs={'ContentType': 'image/jpeg'}
            )

        print(f"   ✅ Uploaded to s3://{S3_BUCKET}/{s3_key}")
        print(f"   Photo ID: {photo_id}")

        # Create photo record in database
        print(f"\n📝 Creating photo record in database...")
        conn = psycopg2.connect(
            host=os.getenv('DB_HOST', 'localhost'),
            port=int(os.getenv('DB_PORT', 5432)),
            database=os.getenv('DB_NAME', 'rapidphoto'),
            user=os.getenv('DB_USER', 'rapidphoto'),
            password=os.getenv('DB_PASSWORD', 'rapidphoto_dev')
        )
        cur = conn.cursor()

        cur.execute("""
            INSERT INTO photos (id, user_id, upload_job_id, original_s3_key, file_name, file_size, mime_type, width, height, status, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
        """, (photo_id, user_id, upload_job_id, s3_key, filename, file_size, 'image/jpeg', width, height, 'PENDING_PROCESSING'))

        conn.commit()
        cur.close()
        conn.close()

        print(f"   ✅ Photo record created with status PENDING_PROCESSING")

        return s3_key, photo_id

    except Exception as e:
        print(f"   ❌ Upload failed: {e}")
        raise


def create_sqs_event(s3_key: str, photo_id: str) -> dict:
    """
    Create a mock SQS event payload for the Lambda handler.
    """
    body = {
        "photoId": photo_id,
        "s3Key": s3_key,
        "userId": TEST_USER_ID
    }

    event = {
        "Records": [
            {
                "messageId": f"test-msg-{uuid.uuid4()}",
                "receiptHandle": "test-receipt-handle",
                "body": json.dumps(body),
                "attributes": {
                    "ApproximateReceiveCount": "1",
                    "SentTimestamp": str(int(datetime.now().timestamp() * 1000)),
                    "SenderId": "local-test",
                    "ApproximateFirstReceiveTimestamp": str(int(datetime.now().timestamp() * 1000))
                },
                "messageAttributes": {},
                "md5OfBody": "test-md5",
                "eventSource": "aws:sqs",
                "eventSourceARN": f"arn:aws:sqs:{AWS_REGION}:123456789012:photo-upload-events",
                "awsRegion": AWS_REGION
            }
        ]
    }

    return event


def check_database_before_after(photo_id: str, check_type: str):
    """
    Check database for photo record.
    """
    import psycopg2

    try:
        conn = psycopg2.connect(
            host=os.getenv('DB_HOST', 'localhost'),
            port=int(os.getenv('DB_PORT', 5432)),
            database=os.getenv('DB_NAME', 'rapidphoto'),
            user=os.getenv('DB_USER', 'rapidphoto'),
            password=os.getenv('DB_PASSWORD', 'rapidphoto_dev')
        )
        cur = conn.cursor()

        # Check photo record
        cur.execute("""
            SELECT id, user_id, original_s3_key, status, width, height
            FROM photos
            WHERE id = %s
        """, (photo_id,))

        photo = cur.fetchone()

        # Check photo versions
        cur.execute("""
            SELECT id, version_type, s3_key, width, height
            FROM photo_versions
            WHERE photo_id = %s
        """, (photo_id,))

        versions = cur.fetchall()

        # Check labels
        cur.execute("""
            SELECT label_name, confidence
            FROM photo_labels
            WHERE photo_id = %s
        """, (photo_id,))

        labels = cur.fetchall()

        print(f"\n{'='*60}")
        print(f"📊 Database State ({check_type})")
        print(f"{'='*60}")

        if photo:
            print(f"\n✅ Photo Record Found:")
            print(f"   ID: {photo[0]}")
            print(f"   User ID: {photo[1]}")
            print(f"   S3 Key: {photo[2]}")
            print(f"   Status: {photo[3]}")
            print(f"   Dimensions: {photo[4]}x{photo[5]} px" if photo[4] else "   Dimensions: Not set")
        else:
            print(f"\n❌ No photo record found for ID: {photo_id}")

        if versions:
            print(f"\n📸 Photo Versions ({len(versions)}):")
            for v in versions:
                print(f"   - {v[1]}: {v[2]} ({v[3]}x{v[4]})")
        else:
            print(f"\n   No photo versions yet")

        if labels:
            print(f"\n🏷️  AI Labels ({len(labels)}):")
            for label, confidence in labels[:10]:  # Show top 10
                print(f"   - {label}: {confidence:.1f}%")
        else:
            print(f"\n   No labels detected yet")

        print(f"{'='*60}\n")

        cur.close()
        conn.close()

    except Exception as e:
        print(f"\n⚠️  Database check failed: {e}")


def verify_s3_outputs(s3_key: str, photo_id: str):
    """
    Verify that processed images were uploaded to S3.
    """
    print(f"\n{'='*60}")
    print(f"☁️  S3 Output Verification")
    print(f"{'='*60}\n")

    s3_client = boto3.client('s3', region_name=AWS_REGION)

    # Expected outputs
    base_path = f"{TEST_USER_ID}/{photo_id}"
    expected_keys = [
        f"thumbnails/{base_path}/thumbnail.jpg",
        f"processed/{base_path}/640.webp",
        f"processed/{base_path}/1024.webp",
        f"processed/{base_path}/1920.webp",
        f"processed/{base_path}/2560.webp",
    ]

    print(f"Checking for processed images in bucket: {S3_BUCKET}\n")

    found_count = 0
    for key in expected_keys:
        try:
            response = s3_client.head_object(Bucket=S3_BUCKET, Key=key)
            size_kb = response['ContentLength'] / 1024
            print(f"   ✅ {key} ({size_kb:.1f} KB)")
            found_count += 1
        except s3_client.exceptions.NoSuchKey:
            print(f"   ❌ {key} (not found)")
        except Exception as e:
            print(f"   ⚠️  {key} (error: {e})")

    print(f"\n   Found {found_count}/{len(expected_keys)} expected outputs")
    print(f"{'='*60}\n")


def main():
    """
    Main test runner.
    """
    # Determine which test image to use
    if len(sys.argv) > 1:
        image_path = sys.argv[1]
    else:
        image_path = 'test-assets/test-image-small.jpg'

    if not os.path.exists(image_path):
        print(f"❌ Error: Image not found: {image_path}")
        sys.exit(1)

    print(f"\n{'='*60}")
    print(f"🚀 Lambda Local Test Runner")
    print(f"{'='*60}")
    print(f"\nConfiguration:")
    print(f"   S3 Bucket: {S3_BUCKET}")
    print(f"   AWS Region: {AWS_REGION}")
    print(f"   Database: {os.getenv('DB_NAME')}@{os.getenv('DB_HOST')}")
    print(f"   Test Image: {image_path}")
    print(f"   Image Size: {os.path.getsize(image_path):,} bytes")

    try:
        # Step 1: Create test user and upload job
        user_id, upload_job_id = create_test_user_and_upload_job()

        # Step 2: Upload test image to S3 and create photo record
        s3_key, photo_id = upload_test_image_to_s3(image_path, user_id, upload_job_id)

        # Step 2: Check database BEFORE processing
        check_database_before_after(photo_id, "BEFORE Processing")

        # Step 3: Create SQS event
        event = create_sqs_event(s3_key, photo_id)

        print(f"\n⚙️  Invoking Lambda Handler...")
        print(f"   Event: {json.dumps(event, indent=2)}\n")

        # Step 4: Invoke Lambda handler
        result = lambda_handler(event, None)

        print(f"\n📋 Lambda Response:")
        print(f"   Status Code: {result.get('statusCode', 'N/A')}")
        print(f"   Body: {result.get('body', 'N/A')}")

        # Step 5: Check database AFTER processing
        import time
        print(f"\n⏳ Waiting 2 seconds for async operations...")
        time.sleep(2)

        check_database_before_after(photo_id, "AFTER Processing")

        # Step 6: Verify S3 outputs
        verify_s3_outputs(s3_key, photo_id)

        print(f"\n{'='*60}")
        print(f"✅ Test Complete!")
        print(f"{'='*60}\n")
        print(f"📝 Summary:")
        print(f"   Photo ID: {photo_id}")
        print(f"   Original: s3://{S3_BUCKET}/{s3_key}")
        print(f"   Check the database and S3 bucket for processed results")
        print(f"\n{'='*60}\n")

    except Exception as e:
        print(f"\n{'='*60}")
        print(f"❌ Test Failed!")
        print(f"{'='*60}")
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
