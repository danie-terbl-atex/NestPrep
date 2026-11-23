import { FieldValue, type Firestore } from 'firebase-admin/firestore';

import { householdRef } from '../household/documents';
import { ROUTINES, TASKS } from './point_refs';

const PAGE = 400;

export const ASSIGNEE_FIELDS = [
  [TASKS, 'assigneeIds'],
  [ROUTINES, 'defaultAssigneeIds'],
] as const;

/** A removed profile comes off every task and routine it was assigned (todos ADR-0008). */
export async function forgetAssignee(
  store: Firestore,
  householdId: string,
  memberId: string,
): Promise<void> {
  const home = householdRef(store, householdId);
  for (const [collection, field] of ASSIGNEE_FIELDS) {
    const assigned = home
      .collection(collection)
      .where(field, 'array-contains', memberId)
      .limit(PAGE);
    for (;;) {
      const page = await assigned.get();
      if (page.empty) break;
      const batch = store.batch();
      for (const doc of page.docs)
        batch.update(doc.ref, { [field]: FieldValue.arrayRemove(memberId) });
      await batch.commit();
      if (page.size < PAGE) break;
    }
  }
}
