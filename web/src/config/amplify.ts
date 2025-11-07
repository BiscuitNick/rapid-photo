/**
 * Amplify Gen2 configuration
 * This file configures AWS Amplify for authentication and storage.
 */

import { Amplify } from 'aws-amplify';

const amplifyConfig = {
  Auth: {
    Cognito: {
      userPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID || '',
      userPoolClientId: import.meta.env.VITE_COGNITO_CLIENT_ID || '',
      identityPoolId: import.meta.env.VITE_COGNITO_IDENTITY_POOL_ID || '',
      loginWith: {
        email: true,
      },
      signUpVerificationMethod: 'code' as const,
      userAttributes: {
        email: {
          required: true,
        },
      },
      allowGuestAccess: false,
      passwordFormat: {
        minLength: 8,
        requireLowercase: true,
        requireUppercase: true,
        requireNumbers: true,
        requireSpecialCharacters: true,
      },
    },
  },
  Storage: {
    S3: {
      bucket: import.meta.env.VITE_S3_BUCKET_NAME || '',
      region: import.meta.env.VITE_AWS_REGION || 'us-east-1',
    },
  },
};

export const configureAmplify = () => {
  Amplify.configure(amplifyConfig);
};

export default amplifyConfig;
