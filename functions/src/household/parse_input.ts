import { HttpsError } from 'firebase-functions/v2/https';
import type { z } from 'zod';

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

/** The caller's uid, or the refusal that says they have none. */
export function requireUid(auth: { uid: string } | undefined): string {
  if (auth === undefined) {
    throw new HttpsError('unauthenticated', 'Sign in first.', { reason: 'notSignedIn' });
  }
  return auth.uid;
}
