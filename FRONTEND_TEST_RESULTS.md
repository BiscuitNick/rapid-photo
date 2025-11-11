# Frontend Testing Results - Lightsail Migration

## Test Environment

### Backend
- **URL**: https://rapid-photo-dev-backend.51qxcte01q11c.us-east-1.cs.amazonlightsail.com
- **Status**: ✅ Running
- **Health Check**: ✅ Passing

### Frontend Applications

#### Web App (React + Vite)
- **Status**: 🏃 Running on http://localhost:3000/
- **Framework**: React 19 + Vite
- **API URL**: https://rapid-photo-dev-backend.51qxcte01q11c.us-east-1.cs.amazonlightsail.com
- **Configuration**: `web/.env`

#### Mobile App (Flutter)
- **Status**: 🏗️ Building for iOS Simulator (iPhone 17 Pro)
- **Framework**: Flutter 3.27
- **API URL**: https://rapid-photo-dev-backend.51qxcte01q11c.us-east-1.cs.amazonlightsail.com
- **Configuration**: `mobile/lib/config/api_config.dart`

## Test Plan

### 1. Authentication Testing
- [ ] Web: Sign up new user
- [ ] Web: Login with existing user
- [ ] Web: Logout and re-login
- [ ] Mobile: Sign up new user
- [ ] Mobile: Login with existing user
- [ ] Mobile: Logout and re-login

### 2. Upload Testing
- [ ] Web: Upload single photo
- [ ] Web: Upload multiple photos
- [ ] Web: Verify presigned URL generation
- [ ] Web: Verify upload progress tracking
- [ ] Mobile: Upload single photo
- [ ] Mobile: Upload multiple photos
- [ ] Mobile: Verify upload from camera
- [ ] Mobile: Verify upload from gallery

### 3. Lambda Processing
- [ ] Verify SQS message sent after upload
- [ ] Check Lambda function invocation
- [ ] Verify thumbnail generation
- [ ] Verify processed photo creation
- [ ] Check database update with photo metadata

### 4. Gallery Testing
- [ ] Web: View uploaded photos
- [ ] Web: Photo pagination works
- [ ] Web: Photo details display correctly
- [ ] Web: Thumbnail loading
- [ ] Mobile: View uploaded photos
- [ ] Mobile: Photo pagination works
- [ ] Mobile: Photo details display correctly

### 5. Download Testing
- [ ] Web: Download original photo
- [ ] Web: Download processed versions
- [ ] Mobile: Download original photo
- [ ] Mobile: Download processed versions

### 6. Search Testing
- [ ] Web: Search photos by tags
- [ ] Web: Search results display correctly
- [ ] Mobile: Search photos by tags
- [ ] Mobile: Search results display correctly

### 7. Delete Testing
- [ ] Web: Delete single photo
- [ ] Web: Verify S3 deletion
- [ ] Web: Verify database deletion
- [ ] Mobile: Delete single photo

### 8. Error Handling
- [ ] Verify 401 error on expired token
- [ ] Verify token refresh works
- [ ] Verify network error handling
- [ ] Verify upload failure handling

## Manual Testing Instructions

### Web App Testing

1. **Start the web app** (if not already running):
   ```bash
   cd web
   npm run dev
   # Opens at http://localhost:3000/
   ```

2. **Test authentication**:
   - Navigate to http://localhost:3000/
   - Click "Sign Up" or "Sign In"
   - Use Cognito credentials
   - Verify JWT token is included in API requests (check Network tab)

3. **Test upload**:
   - Drag and drop photos or click to select
   - Verify upload progress shows
   - Check `/api/v1/uploads/initiate` returns presigned URL
   - Check `/api/v1/uploads/{id}/confirm` is called after S3 upload
   - Verify batch status endpoint shows upload

4. **Test gallery**:
   - Navigate to gallery view
   - Verify photos load
   - Click on photo for details
   - Test pagination if > 20 photos

5. **Test download**:
   - Click download button on photo
   - Verify presigned download URL is generated
   - Verify file downloads

### Mobile App Testing

1. **Wait for build to complete** (will open simulator automatically)

2. **Test authentication**:
   - App should open to auth screen
   - Sign up or sign in with Cognito
   - Verify login persists on app restart

3. **Test upload**:
   - Tap upload button
   - Select photos from simulator
   - Verify upload progress
   - Check photos appear in gallery

4. **Test gallery**:
   - View uploaded photos
   - Tap for details
   - Test scrolling/pagination

5. **Test download**:
   - Tap photo to view
   - Tap download button
   - Verify download completes

## API Endpoint Verification

Run the test script to verify backend connectivity:

```bash
./test-lightsail-api.sh
```

Expected results:
- Health endpoint: 200 OK
- Info endpoint: 200 OK
- Authenticated endpoints without token: 401 Unauthorized

## Monitoring During Tests

### Watch Application Logs

```bash
# Watch backend logs
aws lightsail get-container-log \
  --service-name rapid-photo-dev-backend \
  --container-name backend \
  --region us-east-1 | jq '.logEvents[-20:] | .[] | {timestamp: .createdAt, message: .message}'
```

### Monitor SQS Queue

```bash
# Check SQS queue depth
aws sqs get-queue-attributes \
  --queue-url https://sqs.us-east-1.amazonaws.com/971422717446/rapid-photo-dev-image-processing \
  --attribute-names ApproximateNumberOfMessages \
  --region us-east-1
```

### Monitor Lambda Processing

```bash
# Check Lambda logs
aws logs tail /aws/lambda/rapid-photo-dev-image-processor \
  --region us-east-1 \
  --follow
```

### Check S3 Uploads

```bash
# List recent uploads
aws s3 ls s3://rapid-photo-dev-photos-971422717446/originals/ \
  --recursive \
  --human-readable \
  --summarize
```

## Expected Behavior

### Successful Upload Flow

1. **Frontend initiates upload**:
   - POST `/api/v1/uploads/initiate`
   - Response includes `uploadId` and `presignedUrl`

2. **Frontend uploads to S3**:
   - PUT to presigned URL
   - Response includes `ETag`

3. **Frontend confirms upload**:
   - POST `/api/v1/uploads/{uploadId}/confirm`
   - Backend creates `UploadJob` and sends SQS message

4. **Lambda processes image**:
   - Receives SQS message
   - Downloads original from S3
   - Generates thumbnail and processed versions
   - Uploads to S3
   - Updates database with `Photo` record
   - Calls backend `/api/v1/internal/upload-complete`

5. **Photo appears in gallery**:
   - GET `/api/v1/photos` includes new photo
   - Thumbnail URL is accessible
   - Photo status is "COMPLETED"

## Troubleshooting

### Web App Issues

**CORS errors**:
- Check SecurityConfig.java allows localhost:3000
- Verify VITE_API_BASE_URL in .env

**Authentication errors**:
- Check Cognito user pool configuration
- Verify amplify_outputs.json matches backend config
- Check JWT token in Network tab

**Upload failures**:
- Check presigned URL expiration (15 minutes)
- Verify S3 bucket permissions
- Check file size < 50MB

### Mobile App Issues

**Build failures**:
- Run `flutter clean && flutter pub get`
- Check iOS deployment target matches

**API connection errors**:
- Verify API_BASE_URL in api_config.dart
- Check network permissions in Info.plist
- Verify HTTPS certificate is trusted

**Upload failures**:
- Check photo picker permissions
- Verify file size limits
- Check S3 upload logs

## Known Issues

1. **CloudWatch Metrics**: Application metrics may not appear immediately
   - Metrics export is enabled in config
   - May take 5-10 minutes for first metrics to appear

2. **CORS Configuration**: Currently allows only localhost origins
   - Update SecurityConfig.java for production domains

3. **SSL Certificate**: Lightsail provides SSL automatically
   - Certificate is valid for *.cs.amazonlightsail.com domain

## Test Results Summary

| Test Category | Web App | Mobile App | Backend | Status |
|--------------|---------|------------|---------|--------|
| Authentication | ⏳ Testing | ⏳ Testing | ✅ Ready | In Progress |
| Upload | ⏳ Pending | ⏳ Pending | ✅ Ready | In Progress |
| Processing | ⏳ Pending | ⏳ Pending | ✅ Ready | In Progress |
| Gallery | ⏳ Pending | ⏳ Pending | ✅ Ready | In Progress |
| Download | ⏳ Pending | ⏳ Pending | ✅ Ready | In Progress |
| Search | ⏳ Pending | ⏳ Pending | ✅ Ready | In Progress |
| Delete | ⏳ Pending | ⏳ Pending | ✅ Ready | In Progress |

## Next Steps

1. ✅ Start web app - RUNNING
2. ✅ Start mobile app - BUILDING
3. ⏳ Complete manual testing
4. ⏳ Document any issues found
5. ⏳ Update test results table
6. ⏳ Verify end-to-end flow works

## Testing Notes

- Test with actual photos (JPG, PNG, HEIC)
- Test with various file sizes
- Test concurrent uploads
- Test network interruption scenarios
- Monitor CloudWatch logs during testing
- Verify all processed versions are generated

---

**Test Started**: 2025-11-10
**Tester**: Claude Code
**Environment**: Development (Lightsail)
