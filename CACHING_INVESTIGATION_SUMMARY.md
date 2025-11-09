# Image Caching Investigation - Summary Report

**Date:** November 9, 2025
**Status:** ⚠️ Partially Fixed - Database issue resolved, caching still broken

---

## Problem Statement

Mobile app (Flutter) shows loading spinner every time navigating between gallery and photo detail screens, even for previously viewed images. Images should be cached and load instantly on subsequent views.

---

## Root Cause Analysis

### Primary Issue
Backend generates **new presigned S3 URLs** on every API request. Since presigned URLs include query parameters that change (`X-Amz-Signature`, `X-Amz-Expires`), `CachedNetworkImage` sees different URLs each time, causing cache misses.

### Example
```
First request:  https://bucket.s3.amazonaws.com/photo.jpg?X-Amz-Signature=ABC123...
Second request: https://bucket.s3.amazonaws.com/photo.jpg?X-Amz-Signature=XYZ789...
```
Different URLs → Cache miss → Re-download image

---

## Solutions Implemented

### 1. Backend: URL Caching with Spring Cache ✅ (Code deployed but NOT working)

**Files Modified:**
- `backend/build.gradle.kts` - Added Spring Cache + Caffeine dependencies
- `backend/src/main/java/com/rapidphoto/config/CacheConfig.java` - NEW FILE
- `backend/src/main/java/com/rapidphoto/features/gallery/application/S3DownloadUrlService.java`

**Implementation:**
```java
@Service
public class S3DownloadUrlService {
    private S3DownloadUrlService self;  // Self-injection for AOP proxy

    @Autowired
    public void setSelf(@Lazy S3DownloadUrlService self) {
        this.self = self;
    }

    public Mono<DownloadUrlResult> generatePresignedGetUrl(String s3Key) {
        return Mono.fromCallable(() -> self.generatePresignedGetUrlCached(s3Key));
    }

    @Cacheable(value = "presignedUrls", key = "#s3Key")
    public DownloadUrlResult generatePresignedGetUrlCached(String s3Key) {
        log.info("🔄 CACHE MISS: Generating NEW presigned URL for s3Key: {}", s3Key);
        // Generate presigned URL (expensive operation)
        return new DownloadUrlResult(url, expirationMinutes);
    }
}
```

**Cache Configuration:**
- **Cache name:** `presignedUrls`
- **TTL:** 12 minutes (80% of 15min presigned URL expiration)
- **Max entries:** 10,000
- **Implementation:** Caffeine in-memory cache
- **Why 12 minutes?** URLs expire in 15 min, so cache for 12 min (80%) to ensure URLs are always valid

**Expected Behavior:**
- First request for a photo: CACHE MISS → Generate URL → Cache for 12 min
- Subsequent requests (within 12 min): CACHE HIT → Return same URL (no log)

**Actual Behavior (BROKEN ❌):**
```
19:09:49 - 🔄 CACHE MISS: ...6e60695c-a872-4d38-815d-7ddcb0b732df
19:09:54 - 🔄 CACHE MISS: ...6e60695c-a872-4d38-815d-7ddcb0b732df  ❌ SHOULD BE CACHE HIT!
```
Every request is a cache miss, even seconds apart for the same S3 key.

### 2. Mobile: Image Cache Manager with Stable Keys ✅ (Deployed)

**Files Modified:**
- `mobile/pubspec.yaml` - Added `flutter_cache_manager: ^3.4.1`
- `mobile/lib/shared/cache/image_cache_manager.dart` - NEW FILE
- `mobile/lib/features/gallery/widgets/gallery_screen.dart`
- `mobile/lib/features/gallery/widgets/photo_detail_screen.dart`
- `mobile/lib/features/gallery/providers/gallery_notifier.dart`

**Implementation:**
```dart
// Custom cache manager
class PhotoImageCacheManager {
  static CacheManager get instance {
    return CacheManager(Config(
      'rapidPhotoImageCache',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 200,
    ));
  }
}

// Usage in gallery_screen.dart
CachedNetworkImage(
  imageUrl: photo.thumbnailUrl ?? photo.originalUrl!,
  cacheKey: '${photo.id}_thumbnail',  // Stable key based on photo ID
  cacheManager: PhotoImageCacheManager.instance,
  fit: BoxFit.cover,
)

// Usage in photo_detail_screen.dart
CachedNetworkImage(
  imageUrl: photo.originalUrl!,
  cacheKey: '${photo.id}_original',  // Stable key based on photo ID
  cacheManager: PhotoImageCacheManager.instance,
  fit: BoxFit.contain,
)
```

**Cache Configuration:**
- **Cache directory:** `rapidPhotoImageCache`
- **TTL:** 30 days
- **Max entries:** 200 images
- **Keys:** Stable based on photo ID (e.g., `${photoId}_thumbnail`, `${photoId}_original`)

**Cache Invalidation:**
- On photo deletion: Clears cache for both `${photoId}_thumbnail` and `${photoId}_original`
- Handles both single and bulk deletion

**Status:** Code deployed, but **depends on backend URL caching working** to be effective.

---

## Issues Discovered & Fixed

### ✅ FIXED: Database Schema Type Mismatch

**Error:**
```
PostgresqlBadGrammarException: column "status" is of type photo_status but
expression is of type character varying
```

**Root Cause:**
The `Photo` entity stored `status` as a `String`, but PostgreSQL expected `photo_status` enum type. Spring Data R2DBC doesn't automatically cast String to PostgreSQL enums.

**Fix Applied:**
Changed `Photo.java` to use the `PhotoStatus` Java enum directly:

```java
// BEFORE
private String status = "PENDING_PROCESSING";

// AFTER
@Column(value = "status")
private PhotoStatus status = PhotoStatus.PENDING_PROCESSING;
```

**Files Modified:**
- `backend/src/main/java/com/rapidphoto/domain/Photo.java`
- `backend/src/main/java/com/rapidphoto/repository/PhotoRepository.java`
- `backend/src/main/java/com/rapidphoto/features/upload/application/ConfirmUploadHandler.java`
- `backend/src/main/java/com/rapidphoto/features/upload/application/BatchUploadStatusHandler.java`

**Deployment:**
- ✅ Built successfully
- ✅ Deployed to ECS (2 healthy tasks running)
- ✅ No more database errors in logs

---

## Current Status: CACHING STILL BROKEN ❌

### Problem: `@Cacheable` Not Working

Despite implementing Spring Cache with self-injection to fix the AOP proxy issue, caching is **NOT working**.

**Evidence from logs:**
```
19:09:49 - 🔄 CACHE MISS: originals/.../6e60695c (photo in gallery list)
19:09:49 - ✅ Generated and cached presigned URL

19:09:54 - 🔄 CACHE MISS: originals/.../6e60695c (same photo in detail view)
19:09:54 - ✅ Generated and cached presigned URL
```

The same S3 key generates **cache misses every time**, even 5 seconds apart.

### Possible Root Causes (NOT YET VERIFIED)

1. **Spring AOP Proxy Issue:**
   - Self-injection via `@Autowired void setSelf(@Lazy ...)` might not be getting the actual proxy
   - The `Mono.fromCallable()` wrapper might be creating a new invocation context
   - Spring might not be applying AOP to methods called within reactive pipelines

2. **Reactive Context Issue:**
   - Project Reactor's context propagation might interfere with Spring Cache
   - `@Cacheable` might not work properly with `Mono.fromCallable()`
   - Cache might be getting cleared by reactive stream completion

3. **Cache Configuration Issue:**
   - Cache might not be properly initialized (though logs show "Configuring cache with 12 minute TTL")
   - Caffeine cache manager might have configuration issues
   - Cache key generation might be failing silently

4. **AOP Not Applied:**
   - `@EnableCaching` might not be enabling AOP properly for this service
   - CGLIB proxy might not be created for the service
   - Method visibility (now public) should be correct, but proxy might still not be working

---

## Logging Configuration

**Current Backend Logging (in production):**
```yaml
logging:
  level:
    com.rapidphoto: INFO              # See cache logs
    org.springframework.cache: DEBUG  # See Spring Cache framework activity
```

**Available Log Messages:**
- `🔄 CACHE MISS: Generating NEW presigned URL for s3Key: {key}` - Cache miss (generating URL)
- `✅ Generated and cached presigned URL for s3Key: {key}` - URL cached
- `Configuring cache with 12 minute TTL` - Cache initialization
- `📞 Request for presigned URL: {key}` - DEBUG: Request received
- `📦 Returning URL for {key}` - DEBUG: Returning URL (hit or miss)

**Expected but NOT SEEING:**
- Spring Cache DEBUG logs (e.g., "Cache hit for key X", "Caching value for key Y")
- This suggests AOP might not be applied at all

---

## Deployment Details

### Backend Environment
- **Deployment:** AWS ECS Fargate
- **Cluster:** `rapid-photo-dev-cluster`
- **Service:** `rapid-photo-dev-backend`
- **ALB:** `rapid-photo-dev-alb-351686176.us-east-1.elb.amazonaws.com`
- **Region:** us-east-1
- **Tasks:** 2 healthy tasks running
- **Image:** `971422717446.dkr.ecr.us-east-1.amazonaws.com/rapid-photo-backend:latest`
- **Last Deployed:** Nov 9, 2025 ~18:53 UTC

### Mobile Environment
- **Framework:** Flutter
- **State Management:** Riverpod
- **Backend URL:** Configured in `lib/config/api_config.dart`
- **Default:** `http://rapid-photo-dev-alb-351686176.us-east-1.elb.amazonaws.com`

### Image URL Details
- **Source:** S3 bucket with presigned URLs
- **Default Expiration:** 15 minutes
- **Cached Expiration:** 12 minutes (80% of 15min)

---

## Next Steps to Debug Caching

### Option 1: Add More DEBUG Logging
Enable verbose Spring Cache logging to see if cache is being invoked at all:
```yaml
logging:
  level:
    org.springframework.cache: TRACE
    org.springframework.aop: DEBUG
```

### Option 2: Verify Spring AOP Proxy
Add logging to verify self-injection is getting the proxy:
```java
@PostConstruct
public void init() {
    log.info("S3DownloadUrlService initialized. Is proxy? {}",
        AopUtils.isAopProxy(self));
}
```

### Option 3: Try Manual Caching
Replace `@Cacheable` with manual cache operations to bypass AOP issues:
```java
@Autowired
private CacheManager cacheManager;

public Mono<DownloadUrlResult> generatePresignedGetUrl(String s3Key) {
    return Mono.fromSupplier(() -> {
        Cache cache = cacheManager.getCache("presignedUrls");
        DownloadUrlResult cached = cache.get(s3Key, DownloadUrlResult.class);

        if (cached != null) {
            log.info("✅ CACHE HIT for s3Key: {}", s3Key);
            return cached;
        }

        log.info("🔄 CACHE MISS for s3Key: {}", s3Key);
        DownloadUrlResult result = generatePresignedUrlInternal(s3Key);
        cache.put(s3Key, result);
        return result;
    });
}
```

### Option 4: Alternative Solutions

If Spring Cache continues to fail:

1. **Use Caffeine directly** without Spring Cache abstraction
2. **Implement CloudFront CDN** for stable URLs instead of presigned URLs
3. **Pre-generate long-lived URLs** (7 days) and store in database
4. **Client-side URL normalization** - strip query params before caching
5. **Custom image cache** in mobile app using direct HTTP client

---

## Files Reference

### Backend Files (Modified/Created)
```
backend/
├── build.gradle.kts                                    [MODIFIED - cache deps]
├── src/main/resources/
│   └── application.yml                                 [MODIFIED - logging]
├── src/main/java/com/rapidphoto/
│   ├── config/
│   │   └── CacheConfig.java                           [NEW - cache config]
│   ├── domain/
│   │   └── Photo.java                                 [MODIFIED - enum type]
│   ├── repository/
│   │   └── PhotoRepository.java                       [MODIFIED - enum conversion]
│   └── features/
│       ├── gallery/application/
│       │   └── S3DownloadUrlService.java              [MODIFIED - caching]
│       └── upload/application/
│           ├── ConfirmUploadHandler.java              [MODIFIED - enum conversion]
│           └── BatchUploadStatusHandler.java          [MODIFIED - enum conversion]
```

### Mobile Files (Modified/Created)
```
mobile/
├── pubspec.yaml                                        [MODIFIED - cache manager dep]
├── lib/
│   ├── shared/cache/
│   │   └── image_cache_manager.dart                   [NEW - cache manager]
│   ├── config/
│   │   └── api_config.dart                            [Points to deployed backend]
│   └── features/gallery/
│       ├── widgets/
│       │   ├── gallery_screen.dart                    [MODIFIED - cache keys]
│       │   └── photo_detail_screen.dart               [MODIFIED - cache keys]
│       └── providers/
│           └── gallery_notifier.dart                  [MODIFIED - cache cleanup]
```

---

## Key Commits (Reference)

**Latest commit:** `627f7ad` - "update mobile caching"

**Changes in this commit:**
- Backend cache configuration
- Mobile cache manager implementation
- Database schema enum fix
- Logging improvements

**Git status (uncommitted local changes):**
```
M  backend/src/main/resources/application.yml    (logging changes)
```

---

## Testing Instructions

### To Test Backend Caching:
```bash
# Monitor logs for cache activity
aws logs tail /ecs/rapid-photo-dev/backend --follow --region us-east-1 \
  | grep -E "CACHE MISS|Generated and cached|GET /api/v1/photos"

# Expected on first photo view:
# 🔄 CACHE MISS: Generating NEW presigned URL for s3Key: originals/.../xyz

# Expected on second photo view (within 12 min):
# (no logs - cache hit is silent)

# Actual behavior:
# 🔄 CACHE MISS on EVERY request (BROKEN)
```

### To Test Mobile Caching:
1. Open mobile app
2. Navigate to gallery (loads photos)
3. Tap a photo to view detail
4. Go back to gallery
5. Tap the **same photo** again
6. **Expected:** Image loads instantly (no spinner)
7. **Actual:** Depends on backend URL caching working

---

## Summary

### ✅ What's Working:
1. Backend builds and deploys successfully
2. Database schema issue with `photo_status` enum is **FIXED**
3. Logging is enabled (INFO level for cache activity)
4. Mobile cache manager is implemented with stable keys
5. No errors in logs (except caching not working)

### ❌ What's Broken:
1. **Backend URL caching via `@Cacheable` is NOT working**
   - Every request generates a new URL (cache miss)
   - Self-injection fix didn't resolve the Spring AOP issue
   - Root cause unknown - needs further investigation

### 🔍 What Needs Investigation:
1. **Why is `@Cacheable` not caching?**
   - Is Spring AOP proxy being created?
   - Is the reactive context interfering?
   - Is the cache manager configured correctly?

2. **Alternative approaches if Spring Cache can't be fixed**

---

## Quick Reference Commands

```bash
# Check deployment status
aws ecs describe-services --cluster rapid-photo-dev-cluster \
  --services rapid-photo-dev-backend --region us-east-1 \
  --query 'services[0].{status: status, runningCount: runningCount}'

# View recent logs
aws logs tail /ecs/rapid-photo-dev/backend --since 5m --region us-east-1 \
  --format short | grep -E "INFO|ERROR|CACHE"

# Build and deploy backend
cd backend
./gradlew clean build -x test
docker build -t rapid-photo-backend:latest .
docker tag rapid-photo-backend:latest 971422717446.dkr.ecr.us-east-1.amazonaws.com/rapid-photo-backend:latest
docker push 971422717446.dkr.ecr.us-east-1.amazonaws.com/rapid-photo-backend:latest
aws ecs update-service --cluster rapid-photo-dev-cluster \
  --service rapid-photo-dev-backend --force-new-deployment --region us-east-1
```

---

**Last Updated:** November 9, 2025
**Next Action Required:** Debug why Spring `@Cacheable` is not working despite self-injection fix
