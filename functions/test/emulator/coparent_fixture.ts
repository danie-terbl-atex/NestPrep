import { ALTERNATING, DADS_HOME, MUMS_HOME } from '../coparent_fixtures';
import { householdOfTwo, type HouseholdOfTwo } from './calendar_sync_fixture';
import { adminDb, callAs } from './emulator_harness';

/**
 * Two real households for the co-parenting callables (household ADR-0004),
 * made through `createHousehold` and `redeemInvite` so the membership maps
 * are the ones production writes. Mum's home has an admin (`sam`) and a
 * parent (`thandi`); Dad's home an admin and a carer. Each has its own kid
 * profile for the child.
 */
export interface TwoHomes {
  readonly mum: HouseholdOfTwo;
  readonly dad: HouseholdOfTwo;
  readonly mumChild: string;
  readonly dadChild: string;
}

export async function aKid(householdId: string, displayName: string): Promise<string> {
  const ref = adminDb().collection(`households/${householdId}/members`).doc();
  await ref.set({
    displayName,
    color: 'amber',
    role: 'kid',
    claimedBy: null,
    createdAt: new Date(),
  });
  return ref.id;
}

export async function twoHomes(): Promise<TwoHomes> {
  const mum = await householdOfTwo('parent');
  const dad = await householdOfTwo('carer');
  return {
    mum,
    dad,
    mumChild: await aKid(mum.householdId, 'Sam Parker'),
    dadChild: await aKid(dad.householdId, 'Sam'),
  };
}

export async function aCode(homes: TwoHomes, childMemberId = homes.mumChild): Promise<string> {
  const { code } = await callAs<{ code: string }>(homes.mum.sam, 'createCoParentInvite', {
    householdId: homes.mum.householdId,
    childMemberId,
    home: MUMS_HOME,
    schedule: ALTERNATING,
  });
  return code;
}

export async function accept(homes: TwoHomes, code: string): Promise<string> {
  const { linkId } = await callAs<{ linkId: string }>(homes.dad.sam, 'acceptCoParentInvite', {
    householdId: homes.dad.householdId,
    code,
    childMemberId: homes.dadChild,
    newChildName: null,
    home: DADS_HOME,
  });
  return linkId;
}

/** Two homes with an active link: made, accepted and confirmed. */
export async function linkedHomes(): Promise<TwoHomes & { linkId: string }> {
  const homes = await twoHomes();
  const linkId = await accept(homes, await aCode(homes));
  await callAs(homes.mum.sam, 'confirmCoParentLink', {
    householdId: homes.mum.householdId,
    linkId,
    accept: true,
  });
  return { ...homes, linkId };
}

export async function mirrorOf(
  householdId: string,
  linkId: string,
): Promise<Record<string, unknown>> {
  const snapshot = await adminDb().doc(`households/${householdId}/coParentLinks/${linkId}`).get();
  return snapshot.data() ?? {};
}

/** An ISO date `days` from today in UTC — the server's own idea of today. */
export function isoInDays(days: number): string {
  const now = new Date();
  const today = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
  return new Date(today + days * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
}
