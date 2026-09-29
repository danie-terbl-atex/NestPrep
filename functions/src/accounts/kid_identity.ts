import { z } from 'zod';

/**
 * The custom claim a kid device's Auth user carries (accounts ADR-0003): which
 * household it belongs to and which member profile it is.
 *
 * It is how a Function — and the app — knows a caller is a kid device and who
 * they are. It is **not** what authorises a kid in Security Rules: those read
 * the household's `kids` map, which a parent can empty in one write, where a
 * claim lives until the token refreshes.
 *
 * Todos phase 2 builds on this: a chore completed by a kid device is completed
 * *for* `memberId`, and nothing a kid sends can say otherwise.
 */
export const KID_CLAIM = 'kidProfile';

const kidIdentity = z.object({
  householdId: z.string().min(1).max(64),
  memberId: z.string().min(1).max(64),
});

export type KidIdentity = z.infer<typeof kidIdentity>;

/**
 * The kid a token belongs to, or null for everybody else. Parsed, never cast
 * (`ENG-09`): a claim of the wrong shape is not a kid, and is not trusted as one.
 */
export function kidIdentityOf(
  token: Readonly<Record<string, unknown>> | undefined,
): KidIdentity | null {
  if (token === undefined) return null;
  const parsed = kidIdentity.safeParse(token[KID_CLAIM]);
  return parsed.success ? parsed.data : null;
}

/** Whether a token carries the kid claim at all, whatever its shape. */
export function carriesKidClaim(token: Readonly<Record<string, unknown>> | undefined): boolean {
  return token !== undefined && token[KID_CLAIM] !== undefined;
}
