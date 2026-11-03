import type { DecodedIdToken } from 'firebase-admin/auth';

import { auth } from '../../shared/auth';

/** How recently the member must have signed in for their consent to count. */
export const FRESH_SIGN_IN_MS = 5 * 60 * 1000;

/** Checks a Firebase ID token with the Admin SDK, revocation included. */
export type IdTokenVerifier = (idToken: string) => Promise<DecodedIdToken>;

export const adminIdTokenVerifier: IdTokenVerifier = (idToken) =>
  auth().verifyIdToken(idToken, true);

export type SignInRefusal = 'signInRequired' | 'staleSignIn' | 'kidAccount';

export type SignInCheck =
  | { readonly kind: 'signedIn'; readonly uid: string }
  | { readonly kind: 'refused'; readonly reason: SignInRefusal };

/**
 * The person on the consent page, proved by the ID token the page's Firebase
 * sign-in produced (assistants ADR-0002). Consent hands an assistant a
 * standing credential, so the sign-in must be fresh — within five minutes,
 * like Pick n Pay's `prompt=login` — and a kid device's account can never
 * give it, whatever household it is in.
 */
export async function checkFreshSignIn(
  verify: IdTokenVerifier,
  idToken: string,
  now: Date,
): Promise<SignInCheck> {
  let decoded: DecodedIdToken;
  try {
    decoded = await verify(idToken);
  } catch (error) {
    if (error instanceof Error) return { kind: 'refused', reason: 'signInRequired' };
    throw error;
  }
  if (decoded['kidProfile'] !== undefined) return { kind: 'refused', reason: 'kidAccount' };
  if (now.getTime() - decoded.auth_time * 1000 > FRESH_SIGN_IN_MS) {
    return { kind: 'refused', reason: 'staleSignIn' };
  }
  return { kind: 'signedIn', uid: decoded.uid };
}
