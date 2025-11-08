# Local Development Environment - Setup Complete

## ✅ What's Already Running

Your local development environment is now configured with:

1. **PostgreSQL Database** (Port 5432)
   - Container: `rapidphoto-postgres`
   - Database: `rapidphoto`
   - User: `rapidphoto`
   - Password: `rapidphoto_dev`
   - All schema migrations applied (6 tables)

2. **LocalStack** (Port 4566)
   - Container: `localstack-rapid`
   - S3 Buckets created:
     - `rapid-photo-uploads-local`
     - `amplify-rapidphotoweb-nic-rapidphotouploadsbucketc-cvzqed1qst7p`
   - SQS Queues created:
     - `photo-upload-events-local` (with DLQ)
     - `photo-upload-events-local-dlq`
   - S3 event notifications configured

3. **Spring Boot Backend** (Port 8080)
   - Running with production AWS resources
   - Auth: Real Cognito
   - S3: Real AWS S3 bucket
   - Database: Local PostgreSQL

## 🚀 Next Steps

### Option 1: Continue with Real AWS (Recommended for Now)

**Since your auth and S3 upload already work**, you can keep using real AWS services:

```bash
# Your current environment variables (keep these):
DB_PASSWORD=rapidphoto_dev
COGNITO_ISSUER_URI=https://cognito-idp.us-east-1.amazonaws.com/us-east-1_H2cxGDTU6
COGNITO_JWK_SET_URI=https://cognito-idp.us-east-1.amazonaws.com/us-east-1_H2cxGDTU6/.well-known/jwks.json
S3_BUCKET_NAME=amplify-rapidphotoweb-nic-rapidphotouploadsbucketc-cvzqed1qst7p
AWS_REGION=us-east-1
```

**What you can test now:**
1. Upload photos through your web/mobile app
2. Photos get stored in real S3
3. Database gets updated locally
4. View uploaded photos in gallery

### Option 2: Switch to LocalStack for Offline Development

To use LocalStack instead of real AWS:

```bash
# Stop your backend
kill 26966 27303  # Or use Ctrl+C in the terminal running gradle

# Set these environment variables:
export DB_PASSWORD=rapidphoto_dev
export AWS_ENDPOINT=http://localhost:4566
export S3_BUCKET_NAME=rapid-photo-uploads-local
export SQS_PHOTO_UPLOAD_QUEUE=photo-upload-events-local
export AWS_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

# For local auth testing, you'd need to mock Cognito (more complex)
# Or disable auth temporarily in SecurityConfig

# Restart backend
cd backend
./gradlew bootRun
```

### Setting Up Lambda Image Processing (Local)

The Lambda function processes uploaded images. Here's how to test it locally:

#### 1. Install Python Dependencies

```bash
cd lambda

# Create virtual environment
python3.13 -m venv venv

# Activate it
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

#### 2. Test Lambda Locally (Option A: Direct Invocation)

Create a test event file:

```bash
cat > lambda/test-event.json <<EOF
{
  "Records": [
    {
      "body": "{\"bucket\": \"rapid-photo-uploads-local\", \"key\": \"originals/test-user/test-image.jpg\", \"photoId\": \"123e4567-e89b-12d3-a456-426614174000\"}"
    }
  ]
}
EOF
```

Run the Lambda handler directly:

```bash
cd lambda
python -c "
import json
from src.handler import lambda_handler

with open('test-event.json') as f:
    event = json.load(f)

result = lambda_handler(event, None)
print(json.dumps(result, indent=2))
"
```

#### 3. Deploy Lambda to LocalStack (Option B: More Realistic)

```bash
# Package the Lambda
cd lambda
mkdir -p dist
pip install -r requirements.txt -t dist/
cp -r src/* dist/
cd dist && zip -r ../lambda-package.zip . && cd ..

# Deploy to LocalStack
aws lambda create-function \
  --function-name photo-processor \
  --runtime python3.13 \
  --handler handler.lambda_handler \
  --zip-file fileb://lambda-package.zip \
  --role arn:aws:iam::000000000000:role/lambda-role \
  --environment "Variables={DB_HOST=host.docker.internal,DB_PORT=5432,DB_NAME=rapidphoto,DB_USERNAME=rapidphoto,DB_PASSWORD=rapidphoto_dev,AWS_ENDPOINT=http://localhost:4566,S3_BUCKET_NAME=rapid-photo-uploads-local}" \
  --endpoint-url=http://localhost:4566

# Test it
aws lambda invoke \
  --function-name photo-processor \
  --payload file://test-event.json \
  --endpoint-url=http://localhost:4566 \
  output.json
```

## 🧪 Testing the Complete Pipeline

### End-to-End Test (With Real AWS)

1. **Upload a photo** through your web or mobile app
2. **Check S3**: Photo should be in `originals/` folder
3. **Check Database**: `upload_jobs` and `photos` tables should have entries
4. **Manually trigger processing** (since Lambda isn't watching S3 yet):
   ```bash
   # Get the S3 key from database
   docker exec rapidphoto-postgres psql -U rapidphoto -c "SELECT s3_key FROM photos ORDER BY created_at DESC LIMIT 1;"

   # Trigger Lambda processing manually (if deployed to LocalStack)
   # Or process the image using the Python script directly
   ```

### Verify Everything Works

```bash
# Check database has data
docker exec rapidphoto-postgres psql -U rapidphoto -c "SELECT COUNT(*) FROM photos;"

# Check LocalStack S3
AWS_ENDPOINT_URL=http://localhost:4566 aws s3 ls s3://rapid-photo-uploads-local/originals/

# Check backend is running
curl http://localhost:8080/actuator/health

# Check LocalStack SQS (should be empty for now)
AWS_ENDPOINT_URL=http://localhost:4566 aws sqs receive-message \
  --queue-url http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/photo-upload-events-local
```

## 📝 Development Workflow

### Daily Development

```bash
# 1. Start Docker containers (if not running)
docker start rapidphoto-postgres localstack-rapid

# 2. Start backend
cd backend
./gradlew bootRun

# 3. Start web app (in another terminal)
cd web
npm run dev

# 4. Start mobile app (optional, in another terminal)
cd mobile
flutter run
```

### Making Changes

1. **Backend changes**: DevTools will auto-reload
2. **Database changes**: Add new migration in `backend/src/main/resources/db/migration/`
3. **Lambda changes**: Redeploy to LocalStack or test directly with Python

## 🎯 What You Should Do Next

Based on your setup, here's my recommendation:

### Immediate Next Steps (Choose One Path):

**Path A: Keep It Simple** (Recommended)
1. ✅ Keep using real AWS (auth + S3 working)
2. Test upload flow end-to-end with a real image
3. Manually test Lambda processing locally with Python
4. Deploy Lambda to real AWS when ready
5. Use Terraform to deploy to dev environment

**Path B: Go Full Local** (More setup, but fully offline)
1. Switch backend to LocalStack (set AWS_ENDPOINT)
2. Set up Lambda in LocalStack with SQS trigger
3. Mock or disable Cognito auth for local testing
4. Test entire pipeline offline

### When You're Ready for AWS Deployment:

```bash
cd infrastructure

# Deploy to dev environment
terraform init
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars

# This will create:
# - RDS PostgreSQL (production database)
# - ECS Fargate (for backend)
# - Lambda (for image processing)
# - S3 buckets with lifecycle policies
# - SQS queues
# - CloudWatch monitoring
```

## 🐛 Troubleshooting

### LocalStack Issues
```bash
# Restart LocalStack
docker restart localstack-rapid

# Re-run setup script
./scripts/setup-localstack.sh

# Check LocalStack logs
docker logs localstack-rapid
```

### Database Issues
```bash
# Connect to database
docker exec -it rapidphoto-postgres psql -U rapidphoto

# Check migrations
docker exec rapidphoto-postgres psql -U rapidphoto -c "SELECT * FROM flyway_schema_history;"

# Restart database
docker restart rapidphoto-postgres
```

### Backend Issues
```bash
# Check backend logs in the terminal running bootRun

# Verify environment variables
env | grep -E "(DB_|AWS_|COGNITO_|S3_)"

# Restart with clean build
cd backend
./gradlew clean bootRun
```

## 📚 Additional Resources

- **Backend API**: http://localhost:8080
- **API Docs**: http://localhost:8080/actuator (when running)
- **LocalStack Dashboard**: http://localhost:4566/_localstack/health
- **Database**: `docker exec -it rapidphoto-postgres psql -U rapidphoto`

## ✨ Summary

You now have:
- ✅ Complete local development environment
- ✅ Working database with schema
- ✅ LocalStack AWS resources ready
- ✅ Backend running and tested
- ✅ Auth + S3 upload working with real AWS
- ⏳ Lambda ready to deploy (when you need it)
- ⏳ Terraform ready for AWS deployment (when you're ready)

**Your environment is production-ready for local development!** 🎉
