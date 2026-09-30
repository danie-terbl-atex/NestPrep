import { HttpsError } from 'firebase-functions/v2/https';
import type { z } from 'zod';

import { carriesKidClaim } from '../accounts/kid_identity';
import { refuse } from './errors';

/**
 * One place where a callable's body becomes a typed value (BE-03). A body that
 * does not parse is the client's bug, so the message is for us and the client
 * maps the code to copy (BE-04) — the field names never reach a person.
 */
export function parseInput<T extends z.ZodType>(schema: T, data: unknown): z.infer<T> {
  const result = schema.safeParse(data);
  if (!result.success) {
    throw new HttpsError('invalid-argument', 'That request was not something NestPrep can do.', {
      reason: 'badRequest',
    });
  }
  return result.data;
}

/** Who a callable is being called by: the uid, and the token's claims when there are any. */
export interface Caller {
  uid: string;
  token?: Readonly<Record<string, unknown>>;
}

/**
 * The caller's uid, or the refusal that says they have none.
 *
 * A kid device is refused here, before any callable looks at what it asked
 * for: a kid creates no household, redeems no invite and changes no membership
 * (accounts ADR-0003). Every household and documents callable goes through
 * this, so none of them has to remember kids exist.
 */
export function requireUid(auth: Caller | undefined): string {
  if (auth === undefined) {
    throw new HttpsError('unauthenticated', 'Sign in first.', { reason: 'notSignedIn' });
  }
  if (carriesKidClaim(auth.token)) throw refuse('kidAccount');
  return auth.uid;
}
