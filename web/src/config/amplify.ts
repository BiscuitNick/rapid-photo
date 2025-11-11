/**
 * Amplify Gen2 configuration
 * This file configures AWS Amplify for authentication and storage.
 *
 * After running `npm run amplify:sandbox`, the amplify_outputs.json file
 * will be automatically generated with your backend configuration.
 */

import { Amplify } from 'aws-amplify';
import type { ResourcesConfig } from 'aws-amplify';

type AmplifyConfig = ResourcesConfig | Record<string, unknown>;
type AmplifyOutputsModule = { default: AmplifyConfig };

const FALLBACK_AMPLIFY_CONFIG: AmplifyConfig = {
  Auth: {
    Cognito: {
      userPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID || '',
      userPoolClientId: import.meta.env.VITE_COGNITO_CLIENT_ID || '',
      identityPoolId: import.meta.env.VITE_COGNITO_IDENTITY_POOL_ID || '',
      loginWith: {
        email: true,
      },
      signUpVerificationMethod: 'code',
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
        requireSpecialCharacters: false,
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

// Preload outputs without using top-level await; fallback handled in getter.
const amplifyOutputsPromise: Promise<AmplifyConfig | null> = import('../../amplify_outputs.json')
  .then((module: AmplifyOutputsModule) => module.default)
  .catch(() => null);

let cachedConfig: AmplifyConfig | null = null;
let configurePromise: Promise<AmplifyConfig> | null = null;

export async function getAmplifyConfig(): Promise<AmplifyConfig> {
  if (cachedConfig) {
    return cachedConfig;
  }

  const outputs = await amplifyOutputsPromise;
  cachedConfig = outputs ?? FALLBACK_AMPLIFY_CONFIG;
  return cachedConfig;
}

export const configureAmplify = async (): Promise<AmplifyConfig> => {
  if (!configurePromise) {
    configurePromise = getAmplifyConfig().then((config) => {
      Amplify.configure(config);
      return config;
    });
  }

  return configurePromise;
};

export default getAmplifyConfig;
