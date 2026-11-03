import { logger } from 'firebase-functions/v2';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { z } from 'zod';

import { isFamilyRole } from '../../household/access';
import { HOUSEHOLDS } from '../../household/documents';
import { db } from '../../shared/firestore';
import { deleteGrantsOf } from './delete_grants';

const roles = z.record(z.string(), z.string()).catch({});

/**
 * Who in a household has stopped being somebody who may hold a connection
 * (assistants ADR-0003): a uid gone from `members`, or a family member whose
 * role is no longer family. Pure, so the comparison is tested on its own.
 */
export function uidsThatLostAssistants(before: unknown, after: unknown): string[] {
  const was = roles.parse(before);
  const is = roles.parse(after);
  return Object.entries(was).flatMap(([uid, role]) => {
    const now = is[uid];
    const lost = now === undefined || (isFamilyRole(role) && !isFamilyRole(now));
    return lost ? [uid] : [];
  });
}

/**
 * Disconnects the assistants of a member who leaves, is removed, or stops
 * being family (assistants ADR-0003). Every tool call checks membership live
 * anyway, so this is cleanup the app's list depends on, not the guard — and
 * it reads only the roles map, never a name. Runs in the database's region,
 * as every Firestore trigger must.
 */
export const pruneAssistantConnections = onDocumentUpdated(
  `${HOUSEHOLDS}/{householdId}`,
  async (event) => {
    const lost = uidsThatLostAssistants(
      event.data?.before.get('members'),
      event.data?.after.get('members'),
    );
    if (lost.length === 0) return;
    const { householdId } = event.params;
    const store = db();
    let grants = 0;
    for (const uid of lost) grants += await deleteGrantsOf(store, householdId, uid);
    logger.info('assistant connections pruned', { householdId, members: lost.length, grants });
  },
);
