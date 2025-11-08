import { defineStorage } from '@aws-amplify/backend';

/**
 * Define and configure your storage resource
 * @see https://docs.amplify.aws/gen2/build-a-backend/storage
 */
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
