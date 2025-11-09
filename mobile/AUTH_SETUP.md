# Mobile App Authentication Setup

## Overview
The mobile app authentication has been configured to use AWS Cognito, matching the web app's authentication setup.

## Configuration Files

### 1. amplify_outputs.json
- **Location**: `/mobile/amplify_outputs.json`
- **Purpose**: Contains Cognito pool IDs, S3 bucket configuration
- **Key Values**:
  - User Pool ID: `us-east-1_H2cxGDTU6`
  - App Client ID: `7dt8tb6tn7hi9lvbiuq85nffrj`
  - Identity Pool ID: `us-east-1:41cb34c7-86de-4eb2-9e65-931757c809e4`
  - S3 Bucket: `amplify-rapidphotoweb-nic-rapidphotouploadsbucketc-cvzqed1qst7p`

### 2. AmplifyAuthService
- **Location**: `/mobile/lib/shared/auth/amplify_auth_service.dart`
- **Updates**:
  - Updated to use real Cognito configuration instead of placeholders
  - Configured with actual User Pool and Identity Pool IDs
  - Maintains existing sign-in, sign-up, and token retrieval methods

## New Features

### 1. Authentication Screens
- **LoginScreen** (`/mobile/lib/features/auth/widgets/login_screen.dart`)
  - Email/password sign-in
  - Form validation
  - Error handling
  - Navigation to sign-up

- **SignUpScreen** (`/mobile/lib/features/auth/widgets/signup_screen.dart`)
  - Email/password registration
  - Password strength validation (8+ chars, uppercase, lowercase, number, special char)
  - Email verification flow
  - Auto sign-in after successful registration

### 2. Auth State Management
- **AuthStateProvider** (`/mobile/lib/features/auth/providers/auth_state_provider.dart`)
  - Tracks authentication state (authenticated/loading/user info)
  - Listens to Amplify Hub events (sign-in, sign-out, session expired)
  - Provides current user information (email, userId)
  - Sign-out functionality

### 3. Protected Routes
- **Main App** (`/mobile/lib/main.dart`)
  - Shows login screen when not authenticated
  - Shows loading indicator while checking auth status
  - Displays home page when authenticated
  - Added user menu with email display and sign-out option

### 4. API Authentication
Both services now automatically include JWT tokens in API requests:

- **UploadService** (`/mobile/lib/features/upload/services/upload_service.dart`)
  - Auth interceptor adds JWT to all backend API calls
  - Skips auth for S3 presigned URL uploads

- **GalleryService** (`/mobile/lib/features/gallery/services/gallery_service.dart`)
  - Auth interceptor adds JWT to all backend API calls
  - Automatic token refresh handling

## Usage

### Sign Up Flow
1. User opens app (sees login screen)
2. Taps "Sign Up"
3. Enters email and password
4. Receives verification code via email
5. Enters verification code
6. Auto signs in and navigates to home

### Sign In Flow
1. User opens app (sees login screen)
2. Enters email and password
3. Taps "Sign In"
4. Navigates to home on success

### Authenticated State
- JWT tokens automatically included in all API requests
- Token refresh handled by Amplify
- Session state persists across app restarts
- Sign-out available via user menu

## Testing

To test authentication:

```bash
cd mobile

# Run on iOS simulator
flutter run

# Run on Android emulator
flutter run

# Or specify device
flutter devices
flutter run -d <device-id>
```

## Password Requirements
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character

## Security Features
- JWT tokens stored securely by Amplify
- Automatic token refresh
- Session expiration handling
- Secure password validation
- HTTPS-only API communication

## Next Steps
- [ ] Add password reset functionality
- [ ] Add biometric authentication
- [ ] Add social sign-in (Google, Apple)
- [ ] Implement remember me functionality
- [ ] Add multi-factor authentication
