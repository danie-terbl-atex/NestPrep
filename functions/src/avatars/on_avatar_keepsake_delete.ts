import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { HOUSEHOLDS } from '../household/documents';
import { db } from '../shared/firestore';
import { objectStore } from '../shared/storage';
import { settleKeepsakeDelete } from './avatar_keepsakes';
import { AVATAR_KEEPSAKE_DELETES } from './avatar_refs';

export const onAvatarKeepsakeDelete = onDocumentCreated(
  `${HOUSEHOLDS}/{householdId}/${AVATAR_KEEPSAKE_DELETES}/{keepsakeId}`,
  async (event) => {
    const { householdId, keepsakeId } = event.params;
    const outcome = await settleKeepsakeDelete(db(), objectStore(), householdId, keepsakeId);
    logger.info('avatar keepsake delete settled', { householdId, outcome });
  },
);
