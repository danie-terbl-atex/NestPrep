import type { z } from 'zod';

import { SealBroken, open, seal } from './session_crypto';

/**
 * A typed value sealed for one member and opened back into its shape
 * (ENG-09). Both shop links seal through this (`ENG-02`): Checkers' pending
 * code and session, Pick n Pay's pending link and tokens.
 *
 * A value that does not open, or opens into the wrong shape, is null: it was
 * sealed under a key since rotated, or tampered with, and the caller treats it
 * as never having been there.
 */
export function sealJson(key: Buffer, owner: string, value: unknown): Promise<string> {
  return seal(key, owner, JSON.stringify(value));
}

export async function openJson<T extends z.ZodType>(
  schema: T,
  key: Buffer,
  owner: string,
  sealed: string,
): Promise<z.infer<T> | null> {
  let plaintext: string;
  try {
    plaintext = await open(key, owner, sealed);
  } catch (error) {
    if (error instanceof SealBroken) return null;
    throw error;
  }
  let value: unknown;
  try {
    value = JSON.parse(plaintext);
  } catch (error) {
    if (error instanceof SyntaxError) return null;
    throw error;
  }
  const parsed = schema.safeParse(value);
  return parsed.success ? parsed.data : null;
}
