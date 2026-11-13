import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { HOUSEHOLDS } from '../household/documents';
import { db } from '../shared/firestore';
import { objectStore } from '../shared/storage';
import { MEMBER_AVATARS } from './avatar_refs';
import { settleMemberAvatar } from './member_avatar';

/** A member's choice changed: check it, take a waiting photo, and mirror the look (avatars ADR-0001). */
export const onMemberAvatarWritten = onDocumentWritten(
  `${HOUSEHOLDS}/{householdId}/${MEMBER_AVATARS}/{memberId}`,
  async (event) => {
    const { householdId, memberId } = event.params;
    const outcome = await settleMemberAvatar(db(), objectStore(), householdId, memberId);
    if (outcome !== 'unchanged') logger.info('member avatar settled', { householdId, outcome });
  },
);
