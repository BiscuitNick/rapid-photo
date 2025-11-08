#!/bin/bash
# Test LocalStack SQS trigger by uploading to S3

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║        Test LocalStack SQS Trigger (Automatic)            ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Configuration
ENDPOINT="http://localhost:4566"
BUCKET="rapid-photo-uploads-local"
TEST_IMAGE="test-assets/test-image-small.jpg"
USER_ID="test-user"
PHOTO_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
S3_KEY="originals/${USER_ID}/${TIMESTAMP}-${PHOTO_ID}-test-image-small.jpg"

echo "📋 Test Configuration:"
echo "   Photo ID: $PHOTO_ID"
echo "   S3 Key: $S3_KEY"
echo "   Image: $TEST_IMAGE"
echo ""

# Step 1: Create database records
echo "1️⃣  Creating database records..."
source venv/bin/activate
python3 << EOF
import psycopg2
import uuid
from PIL import Image

# Get image dimensions
with Image.open('$TEST_IMAGE') as img:
    width, height = img.size

# Connect to database
conn = psycopg2.connect(
    host='localhost',
    port=5432,
    database='rapidphoto',
    user='rapidphoto',
    password='rapidphoto_dev'
)
cur = conn.cursor()

# Get or create user
cur.execute("SELECT id FROM users WHERE cognito_user_id = %s", ('$USER_ID',))
result = cur.fetchone()
if result:
    user_id = str(result[0])
else:
    user_id = str(uuid.uuid4())
    cur.execute("""
        INSERT INTO users (id, cognito_user_id, email, created_at, updated_at)
        VALUES (%s, %s, %s, NOW(), NOW())
    """, (user_id, '$USER_ID', 'test-$USER_ID@local.dev'))

# Create upload job
upload_job_id = str(uuid.uuid4())
cur.execute("""
    INSERT INTO upload_jobs (id, user_id, s3_key, presigned_url, file_name, file_size, mime_type, status, expires_at, created_at)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, NOW() + INTERVAL '1 hour', NOW())
""", (upload_job_id, user_id, 'temp', 'http://example.com', 'test-image-small.jpg', 8660, 'image/jpeg', 'CONFIRMED'))

# Create photo record
cur.execute("""
    INSERT INTO photos (id, user_id, upload_job_id, original_s3_key, file_name, file_size, mime_type, width, height, status, created_at, updated_at)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
""", ('$PHOTO_ID', user_id, upload_job_id, '$S3_KEY', 'test-image-small.jpg', 8660, 'image/jpeg', width, height, 'PENDING_PROCESSING'))

conn.commit()
cur.close()
conn.close()

print("   ✅ Database records created")
print(f"   User ID: {user_id}")
print(f"   Upload Job ID: {upload_job_id}")
EOF

echo ""
echo "2️⃣  Uploading image to S3..."
AWS_ENDPOINT_URL=$ENDPOINT aws s3 cp \
  $TEST_IMAGE \
  s3://$BUCKET/$S3_KEY

echo "   ✅ Image uploaded to S3"

echo ""
echo "3️⃣  Checking SQS queue..."
QUEUE_URL="http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/photo-upload-events-local"
MSG_COUNT=$(AWS_ENDPOINT_URL=$ENDPOINT aws sqs get-queue-attributes \
  --queue-url $QUEUE_URL \
  --attribute-names ApproximateNumberOfMessages \
  --query 'Attributes.ApproximateNumberOfMessages' \
  --output text)

echo "   Messages in queue: $MSG_COUNT"

echo ""
echo "4️⃣  Waiting for Lambda to process (10 seconds)..."
sleep 10

echo ""
echo "5️⃣  Checking database for results..."
docker exec rapidphoto-postgres psql -U rapidphoto << SQL
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo '📊 Photo Record:'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
SELECT
    id,
    status,
    width || 'x' || height as dimensions,
    to_char(created_at, 'HH24:MI:SS') as created,
    to_char(processed_at, 'HH24:MI:SS') as processed
FROM photos
WHERE id = '$PHOTO_ID';

\echo ''
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo '📸 Photo Versions:'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
SELECT
    version_type,
    width || 'x' || height as dimensions,
    pg_size_pretty(file_size) as size
FROM photo_versions
WHERE photo_id = '$PHOTO_ID'
ORDER BY width;

\echo ''
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo '🏷️  AI Labels:'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
SELECT
    label_name,
    confidence || '%' as confidence
FROM photo_labels
WHERE photo_id = '$PHOTO_ID'
ORDER BY confidence DESC;
SQL

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                   Test Complete!                          ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "📝 Summary:"
echo "   Photo ID: $PHOTO_ID"
echo "   S3 Key: $S3_KEY"
echo ""
echo "To check Lambda logs:"
echo "   AWS_ENDPOINT_URL=$ENDPOINT aws logs tail /aws/lambda/photo-processor --follow"
echo ""
