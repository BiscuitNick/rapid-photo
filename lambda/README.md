# Lambda Workspace

Python 3.13 image processing Lambda function for RapidPhotoUpload.

## Technology Stack
- Python 3.13
- Pillow 11.x for image processing
- boto3 1.35+ for AWS SDK
- psycopg2-binary for PostgreSQL
- AWS Rekognition for AI labeling

## Structure
- `src/` - Lambda function source code
- `tests/` - Unit and integration tests
- `requirements.txt` - Python dependencies

## Functionality
- Process uploaded images (thumbnails, WebP conversions)
- AI label detection via AWS Rekognition
- Database updates with processed metadata
