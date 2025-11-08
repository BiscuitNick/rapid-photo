import { defineBackend } from '@aws-amplify/backend';
import { auth } from './auth/resource';
import { storage } from './storage/resource';

/**
 * @see https://docs.amplify.aws/gen2/build-a-backend/ to add storage, functions, and more
 */
const backend = defineBackend({
  auth,
  storage,
});
