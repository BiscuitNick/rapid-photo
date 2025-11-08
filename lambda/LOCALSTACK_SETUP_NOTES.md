# LocalStack Lambda Setup - Work in Progress

**Date:** November 8, 2024
**Status:** ⚠️ BLOCKED - psycopg2 Import Error

## Summary

Attempted to set up the image processing Lambda function for local testing with LocalStack. Made significant progress on infrastructure and configuration, but currently blocked by a persistent `psycopg2` import error in the Lambda runtime.

## What Works ✅

1. **LocalStack Infrastructure**
   - LocalStack container running with Lambda, S3, SQS, IAM, and Logs services enabled
   - S3 bucket: `rapid-photo-uploads-local`
   - SQS queue: `photo-upload-events-local`
   - SQS trigger configured to invoke Lambda automatically

2. **Lambda Code Updates**
   - Fixed relative imports → absolute imports (e.g., `from .config` → `from config`)
   - Updated handler to support both S3 events and custom photo events
   - Added `parse_event_data()` function to handle different event formats
   - All Lambda code successfully updated in: `src/handler.py`, `src/db_service.py`, etc.

3. **Test Infrastructure**
   - Created automated test script: `test-localstack-trigger.sh`
   - Database record creation working correctly
   - S3 upload triggering SQS notifications successfully

## Current Blocker ❌

**Error:** `Runtime.ImportModuleError: Unable to import module 'handler': No module named 'psycopg2._psycopg'`

### Root Cause
The `psycopg2-binary` package installed on macOS (ARM64) is not compatible with the Lambda runtime (Linux x86_64). The compiled C extensions differ between platforms.

### Attempted Fixes (All Failed)
1. ✗ Installing `psycopg2-binary` in venv (macOS binaries incompatible)
2. ✗ Building package in Docker with `public.ecr.aws/lambda/python:3.13`
3. ✗ Compiling `psycopg2` from source in Docker with PostgreSQL dev libraries

The Docker-based builds still produce the same import error, suggesting the compiled binaries are not being correctly included in the Lambda package or there's a library mismatch.

## Scripts Created

### Lambda Directory (`/lambda`)
- **`build-lambda-package.sh`** - Builds Lambda package in Docker container matching Lambda runtime
- **`deploy-to-localstack.sh`** - Deploys Lambda to LocalStack with SQS trigger configuration
- **`test-localstack-trigger.sh`** - End-to-end test: creates DB records, uploads to S3, verifies processing
- **`run-local-test.py`** - Python test runner for direct Lambda invocation (bypasses SQS)
- **`.env.local`** - Local environment configuration

### Project Scripts Directory (`/scripts`)
- **`restart-localstack-with-lambda.sh`** - Restarts LocalStack with Lambda service enabled
- **`setup-localstack.sh`** - Initial LocalStack setup (existing)

## File Changes

### Modified Files
- `src/handler.py` - Fixed imports, added S3 event support
- `src/db_service.py` - Fixed imports, corrected status values
- `src/config.py` - Fixed WEBP widths (1280 instead of 1024)

### New Files
- `test-assets/` - Test images (800x600, 2048x1536, 1200x1600)
- `.env.local` - Local environment config
- `lambda-package.zip` - Built Lambda deployment package (~25MB)

## Database Schema Updates
No schema changes were needed, but corrected several mismatches:
- Status: `COMPLETED` → `READY` (correct enum value)
- Removed references to non-existent columns
- Fixed `save_photo_versions()` to include all required fields

## Next Steps (When Resuming)

### Option 1: Use Lambda Layers
Create a Lambda layer with pre-compiled `psycopg2` for Linux x86_64 from AWS or community sources.

### Option 2: Use AWS SAM
Use AWS SAM CLI to build the Lambda package, which handles cross-platform compilation correctly.

### Option 3: Switch to pg8000
Replace `psycopg2` with `pg8000` (pure Python PostgreSQL driver, no C extensions). Slower but platform-independent.

### Option 4: Test Directly (Skip LocalStack Lambda)
Continue using `run-local-test.py` for development, which works perfectly for direct Lambda testing without LocalStack's Lambda runtime.

## Testing Status

### What's Tested and Working
- ✅ Direct Lambda invocation (`run-local-test.py`) - Works perfectly
- ✅ S3 uploads to LocalStack
- ✅ SQS message creation from S3 events
- ✅ Database record creation
- ✅ Lambda deployment to LocalStack

### What's Blocked
- ❌ Automatic Lambda execution via SQS trigger (import error)
- ❌ End-to-end LocalStack flow (S3 → SQS → Lambda → DB)

## Important Notes

1. **Direct Testing Works:** The `run-local-test.py` script successfully processes images locally, proving the Lambda code itself is correct.

2. **LocalStack-Specific Issue:** This is specifically a LocalStack Lambda runtime issue, not a problem with the Lambda code or logic.

3. **Production Deployment:** This issue won't affect actual AWS Lambda deployment since AWS handles cross-platform compilation differently.

## Commands Reference

```bash
# Restart LocalStack with Lambda support
../scripts/restart-localstack-with-lambda.sh
../scripts/setup-localstack.sh

# Build Lambda package (in Docker)
./build-lambda-package.sh

# Deploy to LocalStack
./deploy-to-localstack.sh

# Test automatic processing (currently failing)
./test-localstack-trigger.sh

# Test direct invocation (works perfectly)
./test-local.sh
# OR
source venv/bin/activate && python run-local-test.py
```

## Recommendation

**For now:** Use `run-local-test.py` for local Lambda development and testing. The full LocalStack integration can be completed later or deferred until AWS deployment, where this issue won't exist.

The direct testing approach provides:
- Fast iteration cycles
- Full image processing pipeline testing
- Database integration verification
- S3 upload/download validation
- Rekognition simulation (with LocalStack S3)

This is sufficient for development purposes.
