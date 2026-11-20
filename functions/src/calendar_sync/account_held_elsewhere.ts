import type { Firestore } from 'firebase-admin/firestore';

import { CALENDAR_CONNECTIONS, type Provider } from './sync_documents';

/**
 * Whether another connection, in any household, reads the same provider
 * account. Google's revoke takes back the account's whole grant, not one
 * token, so revoking for one connection would cut every other one off
 * (calendar ADR-0007). An account with no address cannot be told apart and
 * counts as held nowhere else.
 */
export async function accountHeldElsewhere(
  store: Firestore,
  account: { provider: Provider; accountLabel: string; exceptConnectionId?: string },
): Promise<boolean> {
  if (account.accountLabel === '') return false;
  const sameAddress = await store
    .collectionGroup(CALENDAR_CONNECTIONS)
    .where('accountLabel', '==', account.accountLabel)
    .get();
  return sameAddress.docs.some(
    (doc) => doc.id !== account.exceptConnectionId && doc.get('provider') === account.provider,
  );
}
