import type { Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { z } from 'zod';

import { deleteGrants } from '../connections/delete_grants';
import { storedToken, tokenRef } from './auth_documents';
import { type AuthReply, json } from './auth_reply';

const revokeInput = z.object({
  token: z.string().min(1).max(512),
  client_id: z.string().max(2048).optional(),
});

/**
 * `POST /oauth/revoke` (RFC 7009, assistants ADR-0002). Always 200, so it
 * says nothing about whether a token existed. An access token ends alone; a
 * refresh token is the connection itself, so revoking one disconnects —
 * the grant and every token it issued go, as an in-app disconnect does. A
 * client may only revoke what was issued to it.
 */
export async function revokeToken(store: Firestore, body: unknown): Promise<AuthReply> {
  const input = revokeInput.safeParse(body);
  if (!input.success) return json(200, {});
  const ref = tokenRef(store, input.data.token);
  const token = storedToken.safeParse((await ref.get()).data());
  if (!token.success) return json(200, {});
  const { kind, clientId, householdId, grantId } = token.data;
  if (input.data.client_id !== undefined && input.data.client_id !== clientId) return json(200, {});

  if (kind === 'refresh') {
    await deleteGrants(store, householdId, [grantId]);
    logger.info('assistant disconnected by its client', { grantId });
  } else {
    const batch = store.batch();
    batch.delete(ref);
    await batch.commit();
  }
  return json(200, {});
}
