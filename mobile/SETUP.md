# Flutter Upload Feature Setup

This document provides instructions to complete the Flutter upload feature setup.

## Prerequisites

- Flutter 3.27 or later
- Dart SDK 3.6.0 or later
- Android Studio / Xcode (for mobile development)

## Setup Steps

### 1. Install Dependencies

From the `mobile/` directory, run:

```bash
cd mobile
flutter pub get
```

### 2. Generate Code

The project uses `freezed` and `json_serializable` for code generation. Run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate:
- `upload_item.freezed.dart`
- `upload_item.g.dart`

### 3. Verify Build

Check that the project compiles:

```bash
flutter analyze
```

Fix any issues reported by the analyzer.

### 4. Run Tests

Execute the test suite:

```bash
flutter test
```

### 5. Run the App

#### On iOS Simulator:
```bash
flutter run -d iPhone
```

#### On Android Emulator:
```bash
flutter run -d emulator
```

#### On Physical Device:
```bash
flutter devices  # List available devices
flutter run -d <device-id>
```

## Configuration Required

### 1. Amplify Configuration

Update the Amplify configuration in `lib/shared/auth/amplify_auth_service.dart`:

Replace the placeholder values in `_amplifyConfig` with your actual:
- Cognito User Pool ID
- Cognito App Client ID
- Cognito Identity Pool ID
- S3 Bucket name
- AWS Region

Example:
```dart
"PoolId": "us-east-1_AbCdEfGhI",
"AppClientId": "1234567890abcdefghijklmnop",
"IdentityPoolId": "us-east-1:12345678-1234-1234-1234-123456789012",
"bucket": "rapid-photo-uploads-prod",
"region": "us-east-1"
```

Alternatively, create `amplifyconfig.json` and update the service to load it.

### 2. Backend API URL

Update the backend URL in `lib/features/upload/services/upload_service.dart`:

```dart
static const String _baseUrl = 'https://your-backend-url.com/api/v1';
```

For local development:
```dart
// iOS Simulator
static const String _baseUrl = 'http://localhost:8080/api/v1';

// Android Emulator
static const String _baseUrl = 'http://10.0.2.2:8080/api/v1';
```

## Development Workflow

### Watch for Changes

For continuous code generation during development:

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Hot Reload

While the app is running, press `r` in the terminal for hot reload or `R` for hot restart.

### Clean Build

If you encounter issues:

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

## Testing

### Unit Tests

```bash
flutter test test/features/upload/upload_queue_notifier_test.dart
```

### Widget Tests

```bash
flutter test test/widget_test.dart
```

### Integration Tests (Patrol)

First, install Patrol CLI:

```bash
dart pub global activate patrol_cli
```

Then run integration tests:

```bash
patrol test
```

## Troubleshooting

### Issue: "Missing freezed files"

**Solution**: Run code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: "Amplify not configured"

**Solution**: Update the Amplify configuration with valid credentials or configure Amplify Gen 2 properly.

### Issue: "Backend connection failed"

**Solution**:
1. Verify backend is running
2. Check the API base URL
3. Ensure proper CORS configuration on backend
4. Check network permissions in AndroidManifest.xml / Info.plist

### Issue: "Image picker not working"

**Solution**: Add required permissions:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to upload images</string>
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take photos</string>
```

## Next Steps

After setup is complete:

1. Test the upload flow end-to-end
2. Implement gallery feature (Task 7)
3. Add authentication screens
4. Configure push notifications for upload status
5. Add analytics tracking
6. Performance testing with 100 concurrent uploads

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Amplify Flutter Documentation](https://docs.amplify.aws/flutter/)
- [Freezed Package](https://pub.dev/packages/freezed)
- [Image Picker](https://pub.dev/packages/image_picker)
