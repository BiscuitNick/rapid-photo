# Image Caching Analysis - RapidPhoto Mobile App

## Problem Statement
Mobile app shows loading spinner every time user navigates between gallery and photo detail screens, even for previously viewed images. Images should be cached and load instantly on subsequent views.

---

## Root Cause Investigation

### Initial Hypothesis
Backend generates NEW presigned S3 URLs on every API request, causing cache misses because `CachedNetworkImage` sees different URLs each time.

### Verification
- ✅ Confirmed: `S3DownloadUrlService.java` generates fresh presigned URLs on every call
- ✅ Confirmed: Mobile app points to deployed ECS backend (`rapid-photo-dev-alb-351686176.us-east-1.elb.amazonaws.com`)
- ✅ Confirmed: Presigned URLs include query parameters (`X-Amz-Signature`, `X-Amz-Expires`) that change

---

## Solutions Implemented

### 1. Backend: URL Caching (COMPLETED ✅)

**Files Modified:**
- `backend/build.gradle.kts` - Added Spring Cache + Caffeine dependencies
- `backend/src/main/java/com/rapidphoto/config/CacheConfig.java` - NEW FILE
- `backend/src/main/java/com/rapidphoto/features/gallery/application/S3DownloadUrlService.java`

**Implementation:**
```java
@Cacheable(value = "presignedUrls", key = "#s3Key")
protected DownloadUrlResult generatePresignedGetUrlCached(String s3Key) {
    // Generate presigned URL (expensive operation)
    // Cached for 12 minutes (80% of 15min URL expiration)
}
```

**Configuration:**
- Cache name: `presignedUrls`
- TTL: 12 minutes (80% of presigned URL expiration)
- Max entries: 10,000
- Implementation: Caffeine in-memory cache

**Deployment Status:**
- ✅ Built: `./gradlew build`
- ✅ Dockerized: Built image with new code
- ✅ Pushed to ECR: `971422717446.dkr.ecr.us-east-1.amazonaws.com/rapid-photo-backend:latest`
- ✅ Deployed to ECS: Cluster `rapid-photo-dev-cluster`, Service `rapid-photo-dev-backend`
- ✅ Health: 2 tasks RUNNING and HEALTHY

### 2. Mobile: Image Cache Manager (COMPLETED ✅)

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

// Gallery screen usage
CachedNetworkImage(
  imageUrl: photo.thumbnailUrl ?? photo.originalUrl!,
  cacheKey: '${photo.id}_thumbnail',  // Stable key based on photo ID
  cacheManager: PhotoImageCacheManager.instance,
  fit: BoxFit.cover,
  // ... placeholders
)

// Photo detail screen usage
CachedNetworkImage(
  imageUrl: photo.originalUrl!,
  cacheKey: '${photo.id}_original',  // Stable key based on photo ID
  cacheManager: PhotoImageCacheManager.instance,
  fit: BoxFit.contain,
  // ... placeholders
)
```

**Cache Invalidation:**
- On photo deletion: Clears cache for `${photoId}_thumbnail` and `${photoId}_original`
- Handles both single and bulk deletion

---

## Current Status: STILL NOT WORKING ❌

### Symptom
Despite all implementations, loading spinners still appear on every navigation between screens.

### Possible Root Causes (NOT YET VERIFIED)

#### 1. Backend Caching Not Active
**Hypothesis:** `@Cacheable` annotation might not be working
- Spring Cache might not be enabled despite `@EnableCaching`
- Caffeine might not be configured correctly
- Cache might be getting cleared/evicted immediately

**How to Verify:**
```bash
# Check if same URL returned on multiple requests
curl -H "Authorization: Bearer $TOKEN" \
  http://rapid-photo-dev-alb-351686176.us-east-1.elb.amazonaws.com/api/v1/photos/{photoId} | jq '.originalUrl'

# Run again immediately - URLs should be identical if caching works
```

**Debug Needed:**
- Enable DEBUG logging for `org.springframework.cache`
- Add explicit logging in `S3DownloadUrlService` to log cache hits vs misses
- Check cache statistics via actuator endpoint

#### 2. CachedNetworkImage Not Respecting Custom Cache
**Hypothesis:** Flutter's CachedNetworkImage might prioritize URL-based caching over custom `cacheKey`

**Evidence:**
- `CachedNetworkImage` package uses both URL and cacheKey internally
- If URL changes, it might still trigger download despite stable cacheKey
- Widget rebuilds might clear in-memory cache

**How to Verify:**
```dart
// Add logging
CachedNetworkImage(
  imageUrl: url,
  cacheKey: key,
  cacheManager: PhotoImageCacheManager.instance,
  progressIndicatorBuilder: (context, url, progress) {
    print('Loading image: $url with key: $key');
    return CircularProgressIndicator();
  },
  errorWidget: (context, url, error) {
    print('Error loading: $url, error: $error');
    return Icon(Icons.error);
  },
)
```

#### 3. Cache Manager Initialization Issue
**Hypothesis:** PhotoImageCacheManager might not be properly initializing cache directory

**Potential Issues:**
- Missing permissions for cache directory
- Cache being cleared on app restart
- Multiple cache manager instances being created

**How to Verify:**
- Check cache file location on device
- Verify cache persists across app restarts
- Add singleton enforcement

#### 4. Widget Rebuilds Clearing Cache
**Hypothesis:** Gallery/Detail screens rebuilding too frequently, clearing cached images

**Evidence:**
- Riverpod state updates trigger rebuilds
- `ref.watch(galleryProvider)` causes full widget tree rebuild
- Each rebuild might create new CachedNetworkImage instances

**How to Verify:**
- Add build logging in widgets
- Check if widgets rebuild on navigation
- Consider using `const` constructors where possible

#### 5. Network Layer Bypassing Cache
**Hypothesis:** Backend URLs are still changing despite caching layer

**Potential Issues:**
- Cache hit on S3DownloadUrlService but PhotoReadModelMapper calling it multiple times
- Reactive streams causing multiple URL generation calls
- `.block()` calls in PhotoReadModelMapper might bypass cache

**Code to Review:**
```java
// PhotoReadModelMapper.java line 38-40
String thumbnailUrl = s3DownloadUrlService.generatePresignedGetUrl(version.getS3Key())
    .map(S3DownloadUrlService.DownloadUrlResult::downloadUrl)
    .block();  // ⚠️ This might bypass reactive cache
```

---

## Files Reference

### Backend Files
```
backend/
├── build.gradle.kts [MODIFIED]
├── src/main/java/com/rapidphoto/
│   ├── config/
│   │   └── CacheConfig.java [NEW]
│   └── features/gallery/application/
│       ├── S3DownloadUrlService.java [MODIFIED]
│       └── PhotoReadModelMapper.java [CHECK THIS]
└── src/main/resources/
    └── application.yml [NEEDS LOGGING CHANGES]
```

### Mobile Files
```
mobile/
├── pubspec.yaml [MODIFIED]
├── lib/
│   ├── shared/cache/
│   │   └── image_cache_manager.dart [NEW]
│   ├── config/
│   │   └── api_config.dart [Points to deployed backend]
│   └── features/gallery/
│       ├── widgets/
│       │   ├── gallery_screen.dart [MODIFIED]
│       │   └── photo_detail_screen.dart [MODIFIED]
│       └── providers/
│           └── gallery_notifier.dart [MODIFIED]
```

---

## Diagnostic Steps (TODO)

### 1. Verify Backend URL Caching
```bash
# Enable debug logging in application.yml
logging:
  level:
    com.rapidphoto: DEBUG
    org.springframework.cache: DEBUG

# Rebuild and redeploy
./gradlew build
docker build -t rapid-photo-backend:latest .
# ... push to ECR and redeploy to ECS

# Test with curl
TOKEN="your-jwt-token"
PHOTO_ID="some-photo-id"

# First request
curl -s -H "Authorization: Bearer $TOKEN" \
  "http://rapid-photo-dev-alb-351686176.us-east-1.elb.amazonaws.com/api/v1/photos/$PHOTO_ID" \
  | jq '.originalUrl' > url1.txt

# Second request (immediate)
curl -s -H "Authorization: Bearer $TOKEN" \
  "http://rapid-photo-dev-alb-351686176.us-east-1.elb.amazonaws.com/api/v1/photos/$PHOTO_ID" \
  | jq '.originalUrl' > url2.txt

# Compare - should be identical if caching works
diff url1.txt url2.txt
```

### 2. Verify Mobile Cache Persistence
```dart
// Add to main.dart before runApp
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Test cache manager
  final cacheManager = PhotoImageCacheManager.instance;
  final info = await cacheManager.getFileFromCache('test_key');
  print('Cache info: $info');

  runApp(MyApp());
}
```

### 3. Add Comprehensive Logging
```dart
// In gallery_screen.dart
CachedNetworkImage(
  imageUrl: photo.thumbnailUrl ?? photo.originalUrl!,
  cacheKey: '${photo.id}_thumbnail',
  cacheManager: PhotoImageCacheManager.instance,
  fit: BoxFit.cover,
  progressIndicatorBuilder: (context, url, downloadProgress) {
    print('📥 Loading: ${photo.id}, progress: ${downloadProgress.progress}');
    return CircularProgressIndicator(value: downloadProgress.progress);
  },
  errorWidget: (context, url, error) {
    print('❌ Error loading ${photo.id}: $error');
    return Icon(Icons.error);
  },
  imageBuilder: (context, imageProvider) {
    print('✅ Loaded from cache: ${photo.id}');
    return Image(image: imageProvider, fit: BoxFit.cover);
  },
)
```

### 4. Check Network Traffic
Use Charles Proxy or Flutter DevTools Network tab to verify:
- Are URLs actually the same between requests?
- Is mobile making duplicate network requests?
- Are images being downloaded multiple times?

---

## Alternative Solutions (If Current Approach Fails)

### Option 1: Pre-generate Long-Lived URLs
- Generate presigned URLs with 7-day expiration
- Store in database alongside photo records
- Regenerate only on expiration

### Option 2: Use CloudFront CDN
- Configure CloudFront distribution for S3 bucket
- Use stable CloudFront URLs instead of presigned S3 URLs
- Cache at CDN level

### Option 3: Client-Side URL Normalization
- Strip query parameters from URL before using as cache key
- Extract S3 object key from presigned URL
- Use object key as stable cache identifier

### Option 4: Use Image.network with Custom HTTP Client
- Implement custom HTTP client with caching
- More control over cache behavior
- Bypass CachedNetworkImage package limitations

### Option 5: Implement Custom Image Cache
```dart
class CustomImageCache {
  static final Map<String, Uint8List> _cache = {};

  static Future<Uint8List> getImage(String photoId, String url) async {
    if (_cache.containsKey(photoId)) {
      return _cache[photoId]!;
    }

    final response = await http.get(Uri.parse(url));
    final bytes = response.bodyBytes;
    _cache[photoId] = bytes;

    return bytes;
  }
}
```

---

## Key Questions to Answer

1. **Backend:** Are presigned URLs actually being cached and reused?
2. **Backend:** Is the @Cacheable annotation working correctly?
3. **Mobile:** Is CachedNetworkImage actually using the cached files?
4. **Mobile:** Are the cache keys stable across widget rebuilds?
5. **Mobile:** Is the cache directory persisting between app sessions?
6. **Network:** Are the same URLs being returned from the API?
7. **Integration:** Is there a mismatch between backend cache TTL and mobile cache expectations?

---

## Next Steps

1. Add DEBUG logging to backend and verify URL caching works
2. Add logging to mobile app to see if images are loading from cache
3. Use network debugging tools to verify URL stability
4. Consider simpler caching approach if current implementation is too complex
5. May need to revisit architecture - stable URLs vs. dynamic presigned URLs

---

## Environment Details

**Backend:**
- Deployment: AWS ECS Fargate
- Cluster: `rapid-photo-dev-cluster`
- Service: `rapid-photo-dev-backend`
- ALB: `rapid-photo-dev-alb-351686176.us-east-1.elb.amazonaws.com`
- Region: `us-east-1`
- Health: HEALTHY (2 tasks running)

**Mobile:**
- Framework: Flutter
- State Management: Riverpod
- Backend URL: Configured in `lib/config/api_config.dart`
- Default: `http://rapid-photo-dev-alb-351686176.us-east-1.elb.amazonaws.com`

**Image URLs:**
- Source: S3 bucket with presigned URLs
- Default Expiration: 15 minutes
- Cached Expiration: 12 minutes (80% of 15min)

---

## Commits/Changes Made (Reference)

### Backend Changes
- Added Spring Cache starter dependency
- Added Caffeine cache implementation
- Created `CacheConfig.java` with cache configuration
- Modified `S3DownloadUrlService.java` to use `@Cacheable`
- Built and deployed to ECS

### Mobile Changes
- Added `flutter_cache_manager` dependency
- Created `PhotoImageCacheManager` class
- Modified `gallery_screen.dart` to use cache manager + cache keys
- Modified `photo_detail_screen.dart` to use cache manager + cache keys
- Added cache cleanup in `gallery_notifier.dart` on deletion

### Deployment
- Docker image pushed to ECR
- ECS service updated with `--force-new-deployment`
- Deployment completed successfully
- All health checks passing

---

**Status:** Issue persists - images still loading on every navigation
**Priority:** HIGH - Core UX issue
**Impact:** Poor user experience, unnecessary network usage, slow performance
