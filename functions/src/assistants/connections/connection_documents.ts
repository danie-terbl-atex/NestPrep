import { type DocumentReference, type Firestore, Timestamp } from 'firebase-admin/firestore';
import { z } from 'zod';

import { householdRef } from '../../household/documents';
import { ASSISTANT_SCOPES } from '../assistant_scopes';
import { ASSISTANT_VIAS } from '../principal';

/**
 * `households/{h}/assistantConnections/{grantId}` is the grant itself
 * (assistants ADR-0003): one member, one household, one client, the scopes
 * they chose and the notice they agreed to. Deleting it is disconnecting —
 * every token names a grant, and a token whose grant is gone is refused.
 */
export const ASSISTANT_CONNECTIONS = 'assistantConnections';

/**
 * `households/{h}/assistantActivity/{id}`: one line for each document an
 * assistant wrote, so the household sees what a connection did (assistants
 * ADR-0005). Ids only — never a title or an item's name — and gone after 90
 * days by a TTL policy on `expiresAt`.
 */
export const ASSISTANT_ACTIVITY = 'assistantActivity';

export const ACTIVITY_RETENTION_DAYS = 90;

export const ACTIVITY_TARGET_KINDS = ['event', 'groceryItem'] as const;
export type ActivityTargetKind = (typeof ACTIVITY_TARGET_KINDS)[number];

/** The privacy notice a member agrees to on the consent page; raised when its words change. */
export const ASSISTANT_CONSENT_VERSION = 1;

const timestamp = z.instanceof(Timestamp);

export const storedConnection = z.object({
  uid: z.string(),
  memberId: z.string(),
  clientId: z.string(),
  clientName: z.string(),
  host: z.string(),
  via: z.enum(ASSISTANT_VIAS),
  scopes: z.array(z.enum(ASSISTANT_SCOPES)),
  consent: z.object({ version: z.number().int(), at: timestamp }),
  createdAt: timestamp,
  lastUsedAt: timestamp.nullable(),
  refreshGeneration: z.number().int(),
});
export type StoredConnection = z.infer<typeof storedConnection>;

export const storedActivity = z.object({
  grantId: z.string(),
  memberId: z.string(),
  via: z.enum(ASSISTANT_VIAS),
  tool: z.string(),
  target: z.object({ kind: z.enum(ACTIVITY_TARGET_KINDS), id: z.string() }),
  at: timestamp,
  expiresAt: timestamp,
});
export type StoredActivity = z.infer<typeof storedActivity>;

export function connectionRef(
  store: Firestore,
  householdId: string,
  grantId: string,
): DocumentReference {
  return householdRef(store, householdId).collection(ASSISTANT_CONNECTIONS).doc(grantId);
}
