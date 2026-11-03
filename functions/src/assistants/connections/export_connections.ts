import type { Firestore } from 'firebase-admin/firestore';

import { type PlainValue, plainValue } from '../../account_data/plain_value';
import { householdRef } from '../../household/documents';
import {
  ASSISTANT_ACTIVITY,
  ASSISTANT_CONNECTIONS,
  storedActivity,
  storedConnection,
} from './connection_documents';

/** Connections and activity lines listed per household, at most (`BE-08`). */
const LIMIT = 50;
const ACTIVITY_LIMIT = 200;

/**
 * The assistants this account connected in one household, for Download my
 * data (assistants ADR-0005, accounts ADR-0006): which assistant, what it may
 * do, when it was connected and last used, and what it did recently, newest
 * first. Never a token or a hash of one.
 */
export async function exportConnections(
  store: Firestore,
  householdId: string,
  uid: string,
): Promise<PlainValue[]> {
  const household = householdRef(store, householdId);
  const held = await household
    .collection(ASSISTANT_CONNECTIONS)
    .where('uid', '==', uid)
    .limit(LIMIT)
    .get();
  const sections: PlainValue[] = [];
  for (const doc of held.docs) {
    const grant = storedConnection.safeParse(doc.data());
    if (!grant.success) continue;
    const activity = await household
      .collection(ASSISTANT_ACTIVITY)
      .where('grantId', '==', doc.id)
      .limit(ACTIVITY_LIMIT)
      .get();
    const lines = activity.docs
      .flatMap((line) => {
        const parsed = storedActivity.safeParse(line.data());
        return parsed.success
          ? [{ tool: parsed.data.tool, target: parsed.data.target, at: parsed.data.at }]
          : [];
      })
      .sort((a, b) => b.at.toMillis() - a.at.toMillis());
    sections.push(
      plainValue({
        assistant: grant.data.clientName,
        host: grant.data.host,
        via: grant.data.via,
        scopes: grant.data.scopes,
        consentVersion: grant.data.consent.version,
        connectedAt: grant.data.createdAt,
        lastUsedAt: grant.data.lastUsedAt,
        recentActivity: lines,
      }),
    );
  }
  return sections;
}
