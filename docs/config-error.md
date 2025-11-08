# Rapid Photo Backend Configuration Issues - Complete Resolution

## Issues Encountered and Fixed

### Issue 1: PostgreSQL ENUM Type Conversion ✅ FIXED
**Problem**: R2DBC couldn't automatically convert Java String/Enum types to PostgreSQL ENUM types.

**Error Message**:
```
column "status" is of type upload_job_status but expression is of type character varying
```

**Root Cause**: R2DBC PostgreSQL driver doesn't automatically cast String values to PostgreSQL ENUM types during INSERT/UPDATE operations.

**Solution Implemented**:
1. Changed entity fields from enum types to String types in:
   - `UploadJob.java` - Changed status from UploadJobStatus enum to String
   - `Photo.java` - Changed status from PhotoStatus enum to String

2. Created custom repository methods with explicit ENUM casting:
   - Added `saveWithEnumCast()` and `updateStatusWithEnumCast()` to UploadJobRepository
   - Added `saveWithEnumCast()` and `updateStatusWithEnumCast()` to PhotoRepository
   - These methods use PostgreSQL's `::enum_type` casting syntax

3. Updated handlers to use custom repository methods:
   - `GeneratePresignedUrlHandler.java` - Uses `saveWithEnumCast()` instead of `save()`
   - `ConfirmUploadHandler.java` - Uses custom methods for both saves and updates

### Issue 2: Foreign Key Constraint Violation ✅ FIXED
**Problem**: Upload jobs couldn't be created because the user didn't exist in the database.

**Error Message**:
```
insert or update on table "upload_jobs" violates foreign key constraint "upload_jobs_user_id_fkey"
Key (user_id)=(9428c418-f0e1-70e1-510e-d12afbf34cdd) is not present in table "users".
```

**Root Cause**: The JWT token contains a Cognito user ID, but the database requires this user to exist in the users table.

**Solution Implemented**:
```sql
INSERT INTO users (id, cognito_user_id, email, name, created_at)
VALUES (
  '9428c418-f0e1-70e1-510e-d12afbf34cdd'::uuid,
  '9428c418-f0e1-70e1-510e-d12afbf34cdd',
  'test@example.com',
  'Test User',
  NOW()
);
```
- Used the Cognito user ID as both the primary key (id) and cognito_user_id
- This ensures the foreign key constraint is satisfied

### Issue 3: Entity ID and Timestamp Generation ✅ FIXED
**Problem**: Entity factory methods weren't generating IDs and timestamps.

**Solution Implemented**:
Updated factory methods in both UploadJob and Photo entities:
```java
// UploadJob.create() now includes:
.id(UUID.randomUUID())
.status("INITIATED")
.createdAt(Instant.now())

// Photo.fromUploadJob() now includes:
.id(UUID.randomUUID())
.status("PENDING_PROCESSING")
.createdAt(Instant.now())
```

## Files Modified

### Backend Entity Files
- `/backend/src/main/java/com/rapidphoto/domain/UploadJob.java`
- `/backend/src/main/java/com/rapidphoto/domain/Photo.java`

### Repository Files
- `/backend/src/main/java/com/rapidphoto/repository/UploadJobRepository.java`
- `/backend/src/main/java/com/rapidphoto/repository/PhotoRepository.java`

### Handler Files
- `/backend/src/main/java/com/rapidphoto/features/upload/application/GeneratePresignedUrlHandler.java`
- `/backend/src/main/java/com/rapidphoto/features/upload/application/ConfirmUploadHandler.java`
- `/backend/src/main/java/com/rapidphoto/features/gallery/application/PhotoReadModelMapper.java`
- `/backend/src/main/java/com/rapidphoto/features/upload/application/BatchUploadStatusHandler.java`

### Security Files
- `/backend/src/main/java/com/rapidphoto/security/SecurityContextUtils.java`
- `/backend/src/main/java/com/rapidphoto/config/SecurityConfig.java`

### Frontend Files
- `/web/src/hooks/useUploadQueue.ts`

## Database Schema Notes

The `users` table structure:
- `id` (UUID) - Primary key
- `cognito_user_id` (VARCHAR) - Unique Cognito identifier
- `email` (VARCHAR) - User email
- `name` (VARCHAR) - User display name
- Foreign key constraints from `upload_jobs` and `photos` tables reference `users.id`

## Environment Variables Required
```bash
DB_PASSWORD=rapidphoto_dev
COGNITO_ISSUER_URI=https://cognito-idp.us-east-1.amazonaws.com/us-east-1_H2cxGDTU6
COGNITO_JWK_SET_URI=https://cognito-idp.us-east-1.amazonaws.com/us-east-1_H2cxGDTU6/.well-known/jwks.json
S3_BUCKET_NAME=amplify-rapidphotoweb-nic-rapidphotouploadsbucketc-cvzqed1qst7p
AWS_REGION=us-east-1
```

## Current Status
✅ ENUM type conversion issue - RESOLVED
✅ Foreign key constraint issue - RESOLVED
✅ Entity ID generation issue - RESOLVED
✅ Backend starts successfully
✅ Database properly configured with user

## Testing Steps
1. Backend must be restarted after database changes (to clear connection pool cache)
2. User must exist in database before attempting uploads
3. Frontend should be accessed at http://localhost:3000
4. Upload attempts will now:
   - Create upload job with proper ENUM status
   - Generate presigned URL for S3
   - Allow direct upload to S3

## Lessons Learned
1. R2DBC doesn't handle PostgreSQL ENUM types automatically - explicit casting required
2. JWT user IDs must match database user IDs for foreign key constraints
3. Entity factory methods must generate all required fields including IDs and timestamps
4. Database connection pools may cache state - restart backend after database changes

## Next Context Window Requirements
If issues persist in a new context window, ensure:
1. This file is referenced for context
2. Backend is freshly restarted
3. Database user exists with correct ID mapping
4. All custom repository methods are being used (not default save())