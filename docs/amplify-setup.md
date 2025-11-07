# AWS Amplify Setup Guide

This guide explains how to configure AWS Amplify Gen 2 for RapidPhotoUpload across all client applications.

## Overview

RapidPhotoUpload uses **AWS Amplify Gen 2** for:
- **Authentication**: AWS Cognito user pools
- **Storage**: S3 presigned URL generation
- **Environment management**: Multi-environment configuration

## Amplify Gen 2 Architecture

```
amplify/
├── auth/
│   └── resource.ts          # Cognito User Pool configuration
├── storage/
│   └── resource.ts          # S3 bucket configuration
├── backend.ts               # Backend definition
└── outputs.json             # Generated outputs (auto-created)
```

## Environment Setup

### 1. Install Amplify CLI

```bash
npm install -g @aws-amplify/cli@latest
```

### 2. Configure Amplify Project

```bash
# Initialize Amplify Gen 2 project
amplify configure project

# Set up authentication
amplify add auth

# Set up storage
amplify add storage
```

### 3. Environment Configuration

Amplify Gen 2 supports multiple environments (dev, staging, prod):

```bash
# Create development environment
amplify env add dev

# Create production environment
amplify env add prod

# Switch between environments
amplify env checkout dev
amplify env checkout prod
```

## Authentication (Cognito)

### User Pool Configuration

```typescript
// amplify/auth/resource.ts
import { defineAuth } from '@aws-amplify/backend';

export const auth = defineAuth({
  loginWith: {
    email: true,
  },
  userAttributes: {
    email: {
      required: true,
      mutable: false,
    },
    name: {
      required: true,
      mutable: true,
    },
  },
  passwordPolicy: {
    minLength: 8,
    requireLowercase: true,
    requireUppercase: true,
    requireNumbers: true,
    requireSymbols: true,
  },
});
```

### JWT Token Structure

Cognito provides JWT tokens with the following structure:

```json
{
  "sub": "user-uuid",
  "cognito:username": "user@example.com",
  "email": "user@example.com",
  "email_verified": true,
  "iss": "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_XXXXXXX",
  "aud": "client-id",
  "token_use": "id",
  "auth_time": 1234567890,
  "exp": 1234567890
}
```

## Storage (S3)

### Bucket Configuration

```typescript
// amplify/storage/resource.ts
import { defineStorage } from '@aws-amplify/backend';

export const storage = defineStorage({
  name: 'rapidPhotoUploads',
  access: (allow) => ({
    'originals/{entity_id}/*': [
      allow.entity('identity').to(['read', 'write', 'delete']),
    ],
    'thumbnails/{entity_id}/*': [
      allow.entity('identity').to(['read']),
    ],
    'processed/{entity_id}/*': [
      allow.entity('identity').to(['read']),
    ],
  }),
});
```

## Client Integration

### Mobile (Flutter)

```dart
// mobile/lib/shared/auth/amplify_config.dart
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'amplify_outputs.dart';

Future<void> configureAmplify() async {
  try {
    await Amplify.addPlugins([
      AmplifyAuthCognito(),
      AmplifyStorageS3(),
    ]);

    await Amplify.configure(amplifyConfig);
    print('Successfully configured Amplify');
  } catch (e) {
    print('Error configuring Amplify: $e');
  }
}
```

### Web (React)

```typescript
// web/src/lib/amplify-config.ts
import { Amplify } from 'aws-amplify';
import amplifyOutputs from '../amplify_outputs.json';

Amplify.configure(amplifyOutputs);

export default Amplify;
```

## Environment Variables

### Development

```bash
# .env.local
VITE_AWS_REGION=us-east-1
VITE_COGNITO_USER_POOL_ID=us-east-1_XXXXXXX
VITE_COGNITO_CLIENT_ID=xxxxxxxxxxxxxxxxxxxxxxxxxx
VITE_S3_BUCKET=rapid-photo-uploads-dev
VITE_API_ENDPOINT=http://localhost:8080
```

### Production

```bash
# .env.production
VITE_AWS_REGION=us-east-1
VITE_COGNITO_USER_POOL_ID=us-east-1_YYYYYYY
VITE_COGNITO_CLIENT_ID=yyyyyyyyyyyyyyyyyyyyyyyyyy
VITE_S3_BUCKET=rapid-photo-uploads-prod
VITE_API_ENDPOINT=https://api.rapidphoto.example.com
```

## Backend Integration

The Spring Boot backend validates Cognito JWT tokens:

```yaml
# backend/src/main/resources/application.yml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: https://cognito-idp.${AWS_REGION}.amazonaws.com/${COGNITO_USER_POOL_ID}
          jwk-set-uri: https://cognito-idp.${AWS_REGION}.amazonaws.com/${COGNITO_USER_POOL_ID}/.well-known/jwks.json
```

## Deployment

```bash
# Deploy Amplify backend
amplify push

# Build and deploy hosting (if using Amplify Hosting)
amplify publish
```

## Troubleshooting

### Common Issues

1. **Token Validation Fails**
   - Verify `issuer-uri` matches Cognito User Pool
   - Check JWT token expiration
   - Ensure JWKS endpoint is accessible

2. **S3 Access Denied**
   - Verify IAM roles and policies
   - Check bucket CORS configuration
   - Validate presigned URL expiration

3. **Environment Mismatch**
   - Confirm `amplify env checkout <env>` shows correct environment
   - Verify `.env` files match Amplify environment
   - Check `amplify_outputs.json` is up to date

## References

- [Amplify Gen 2 Documentation](https://docs.amplify.aws/gen2/)
- [Cognito Documentation](https://docs.aws.amazon.com/cognito/)
- [S3 Documentation](https://docs.aws.amazon.com/s3/)
