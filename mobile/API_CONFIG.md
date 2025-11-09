# Mobile App - API Configuration

## Default Configuration

By default, the mobile app is configured to use the deployed AWS backend:

```
http://rapid-photo-dev-alb-351686176.us-east-1.elb.amazonaws.com
```

This is set in `lib/config/api_config.dart`.

## Running Against Local Backend

If you want to develop against a local backend running on `localhost:8080`, you can override the API URL using the `--dart-define` flag:

### iOS Simulator / macOS

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```

### Android Emulator

Android emulator uses a special IP to access the host machine:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

### Physical Device (iOS/Android)

Find your local machine's IP address and use it:

```bash
# macOS: Get your IP
ipconfig getifaddr en0

# Then run with your IP
flutter run --dart-define=API_BASE_URL=http://192.168.1.XXX:8080
```

## Environment-Specific Builds

### Development Build (AWS Dev Backend)

```bash
flutter run  # Uses default AWS backend
```

### Local Development Build

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```

### Production Build

Update `lib/config/api_config.dart` with production backend URL before building:

```bash
flutter build ios --release
flutter build apk --release
```

## Configuration File

All API configuration is centralized in:

```
lib/config/api_config.dart
```

This file contains:
- Base URL (overridable via `API_BASE_URL` environment variable)
- API version prefix (`/api/v1`)
- Timeout settings
- Helper methods for full API paths

## Testing the Connection

After configuring the backend URL, test the connection by:

1. Launch the app
2. Sign in with your Cognito credentials
3. Try uploading a photo
4. Check the app logs for successful API calls

The app uses Dio HTTP client with logging interceptors - all API requests and responses will be logged to the console during development.
