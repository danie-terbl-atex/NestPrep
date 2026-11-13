import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { HOUSEHOLDS } from '../household/documents';
import { db } from '../shared/firestore';
import { AVATAR_PURCHASES } from './avatar_refs';
import { settleAvatarPurchase } from './avatar_purchase';

/** An accessory asked for in the Wardrobe: bought with the child's stars, or refused (avatars ADR-0004). */
export const onAvatarPurchase = onDocumentCreated(
  `${HOUSEHOLDS}/{householdId}/${AVATAR_PURCHASES}/{purchaseId}`,
  async (event) => {
    const { householdId, purchaseId } = event.params;
    const outcome = await settleAvatarPurchase(db(), householdId, purchaseId);
    logger.info('avatar purchase settled', { householdId, purchaseId, outcome });
  },
);
