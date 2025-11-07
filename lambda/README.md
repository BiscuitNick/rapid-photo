# RapidPhoto Lambda - Image Processing Pipeline

Python 3.13 Lambda function for processing uploaded images with thumbnail generation, WebP conversion, and AI labeling.

## Technology Stack
- **Python 3.13** - Runtime
- **Pillow 11.x** - Image processing (thumbnails, WebP)
- **boto3 1.35+** - AWS SDK (S3, Rekognition, CloudWatch)
- **psycopg2-binary** - PostgreSQL database adapter
- **AWS Rekognition** - AI label detection

## Architecture

```
SQS Event → Lambda Handler → Process Pipeline → Update Database
                                    ↓
                           1. Download from S3
                           2. Generate Thumbnail (300x300)
                           3. Create WebP Renditions (640, 1024, 1920, 2560)
                           4. Detect Labels (Rekognition, 80% confidence)
                           5. Upload Processed Assets
                           6. Update PostgreSQL with Metadata
```

## Project Structure

```
lambda/
├── src/
│   ├── handler.py              # Main Lambda handler
│   ├── config.py               # Configuration management
│   ├── image_processor.py      # Thumbnail generation (300x300 center crop)
│   ├── webp_converter.py       # WebP conversion at multiple widths
│   ├── s3_service.py          # S3 upload/download helpers
│   ├── rekognition_service.py # AI label detection wrapper
│   ├── db_service.py          # PostgreSQL persistence with connection pooling
│   └── metrics.py             # Structured logging and CloudWatch metrics
├── tests/                      # Pytest test suite with moto mocks
│   ├── test_handler.py
│   ├── test_image_processor.py
│   ├── test_webp_converter.py
│   ├── test_s3_service.py
│   └── test_rekognition_service.py
├── requirements.txt            # Production dependencies
└── requirements-dev.txt        # Development dependencies (pytest, moto, etc.)
```

## Features

✅ **Thumbnail Generation**: 300x300 center-cropped JPEG thumbnails
✅ **WebP Renditions**: 4 resolutions (640, 1024, 1920, 2560px) at 80% quality
✅ **AI Labeling**: AWS Rekognition with 80% confidence, max 20 labels
✅ **Idempotency**: Prevents duplicate processing via status checks
✅ **Structured Logging**: JSON logs for CloudWatch Insights
✅ **CloudWatch Metrics**: Processing duration, success/failure counters
✅ **Error Handling**: DLQ routing, retry logic, failure tracking
✅ **Connection Pooling**: Efficient PostgreSQL connections with keepalive

## Event Format

SQS message body structure:

```json
{
  "photoId": "550e8400-e29b-41d4-a716-446655440000",
  "s3Key": "originals/user123/photo-uuid.jpg",
  "userId": "user123"
}
```

## Processing Pipeline

1. **Idempotency Check**: Verify photo status isn't `COMPLETED` or `PROCESSING`
2. **Download Original**: Fetch image from S3
3. **Extract Metadata**: Width, height, format, file size
4. **Generate Thumbnail**: 300x300 center crop, JPEG 85% quality
5. **Create WebP Renditions**: 4 sizes maintaining aspect ratio
6. **Upload Assets**: Save to `thumbnails/` and `processed/` prefixes
7. **Rekognition**: Detect labels (min 80% confidence, max 20)
8. **Extract Tags**: Top 10 labels by confidence
9. **Update Database**: Save metadata, tags, and version mappings
10. **Emit Metrics**: Log duration, counters, dimensions

## Configuration

Environment variables:

```bash
# AWS
AWS_REGION=us-east-1
S3_BUCKET=rapid-photo-uploads

# Database
DB_HOST=rapidphoto-db.us-east-1.rds.amazonaws.com
DB_PORT=5432
DB_NAME=rapidphoto
DB_USER=lambda_user
DB_PASSWORD=<from-secrets-manager>

# Processing
LOG_LEVEL=INFO
```

## Testing

```bash
# Install dev dependencies
pip install -r requirements-dev.txt

# Run all tests
pytest

# Run with coverage
pytest --cov=src --cov-report=html

# Run specific test file
pytest tests/test_image_processor.py -v

# Run with moto for AWS service mocks
pytest tests/test_s3_service.py -v
```

## Observability

### Structured Logging

All logs are JSON-formatted for CloudWatch Insights:

```json
{
  "message": "Image processing completed",
  "photo_id": "uuid",
  "thumbnail_key": "thumbnails/user123/photo.jpg",
  "renditions": 4,
  "tags": 8,
  "timestamp": 1699564800.0
}
```

### CloudWatch Metrics

**Namespace**: `RapidPhoto/Lambda`

- `image.downloaded` (Count) - Images downloaded from S3
- `thumbnail.created` (Count) - Thumbnails generated
- `renditions.created` (Count) - WebP renditions created
- `rekognition.completed` (Count) - Rekognition API calls
- `image_processing.duration` (Seconds) - Total processing time
- `image_processing.count` (Count) - Success/error status
- `message.processed.success` (Count) - Successful messages
- `message.processed.failure` (Count) - Failed messages

## Error Handling

- **Transient Failures**: Lambda retries automatically
- **DLQ Routing**: Failed messages after max retries
- **Idempotency**: Duplicate processing prevented
- **Partial Batch Failures**: Returns 207 status with failure details
- **Database Errors**: Failed photos marked with error message
- **Graceful Degradation**: Continues if optional steps fail

## Performance

- **Target SLA**: 100 images in ≤90 seconds
- **Memory**: 2048 MB recommended
- **Timeout**: 60 seconds
- **Concurrency**: 100 parallel invocations
- **Batch Size**: 10 SQS messages per invocation

## Deployment

Package for Lambda:

```bash
# Create deployment package
cd lambda
pip install -r requirements.txt -t package/
cp -r src/* package/
cd package && zip -r ../lambda.zip . && cd ..

# Deploy with AWS CLI
aws lambda update-function-code \
  --function-name rapid-photo-processor \
  --zip-file fileb://lambda.zip
```

Or use Terraform/SAM:

```hcl
resource "aws_lambda_function" "image_processor" {
  filename         = "lambda.zip"
  function_name    = "rapid-photo-processor"
  role            = aws_iam_role.lambda_exec.arn
  handler         = "handler.lambda_handler"
  runtime         = "python3.13"
  timeout         = 60
  memory_size     = 2048

  environment {
    variables = {
      S3_BUCKET = var.s3_bucket
      DB_HOST   = var.db_host
    }
  }
}
```

## Development

### Code Quality

```bash
# Format code
black src/ tests/

# Lint
ruff check src/ tests/

# Type checking
mypy src/
```

### Local Testing

Use LocalStack or moto for AWS service mocking:

```python
from moto import mock_aws
import boto3

@mock_aws
def test_s3_operations():
    s3 = boto3.client('s3', region_name='us-east-1')
    s3.create_bucket(Bucket='test-bucket')
    # Your test code
```

## Monitoring Checklist

- [ ] Lambda error rate < 1%
- [ ] Average duration < 15s per image
- [ ] DLQ message count = 0
- [ ] Database connection pool healthy
- [ ] S3 throttling errors = 0
- [ ] Rekognition API limits not exceeded
- [ ] CloudWatch logs searchable

## Related Tasks

- Task 3: Upload Command Slices (publishes to SQS)
- Task 4: Gallery Query Slices (reads processed metadata)
- Task 10: Infrastructure (deploys Lambda + monitoring)

## License

Internal use only - Part of RapidPhoto v2.0
