import { OAuth2Client } from 'google-auth-library';

export interface VerifiedIdentity {
  readonly email: string | null;
  readonly emailVerified: boolean;
}

export type IdTokenCheck = (idToken: string, audience: string) => Promise<VerifiedIdentity | null>;

const googleClient = new OAuth2Client();

export const googleIdTokenCheck: IdTokenCheck = async (idToken, audience) => {
  try {
    const ticket = await googleClient.verifyIdToken({ idToken, audience });
    const payload = ticket.getPayload();
    if (payload === undefined) return null;
    return { email: payload.email ?? null, emailVerified: payload.email_verified === true };
  } catch (error) {
    if (error instanceof Error) return null;
    throw error;
  }
};

export function bearerOf(authorization: string | string[] | undefined): string | null {
  if (typeof authorization !== 'string') return null;
  const match = /^Bearer ([A-Za-z0-9._~+/=-]{20,4096})$/.exec(authorization.trim());
  return match?.[1] ?? null;
}

export async function isStoreCaller(
  check: IdTokenCheck,
  authorization: string | string[] | undefined,
  audience: string,
  expectedEmail: string | null,
): Promise<boolean> {
  if (expectedEmail === null) return false;
  const idToken = bearerOf(authorization);
  if (idToken === null) return false;
  const identity = await check(idToken, audience);
  return (
    identity !== null &&
    identity.emailVerified &&
    identity.email !== null &&
    identity.email.toLowerCase() === expectedEmail
  );
}
