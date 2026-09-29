import { Timestamp } from 'firebase-admin/firestore';
import { afterAll, beforeEach, describe, expect, it } from 'vitest';

import { adminDb, callAs, clearFirestore, closeAdmin, signUp } from './emulator_harness';
import {
  CHILD_NAME,
  PARTNER_NAME,
  addMember,
  createHousehold,
  eventually,
  expectRefusal,
  joinAs,
  ledger,
  thisWeek,
} from './product_analytics_fixture';

/**
 * The beta numbers' way in, end to end (product-analytics ADR-0001): the
 * callable over HTTP with a real token, and the triggers firing in the
 * Functions emulator on real writes.
 */

afterAll(closeAdmin);

describe('recordActivity', () => {
  beforeEach(clearFirestore);

  it('marks the caller"s own profile active this week, and only once however often it is called', async () => {
    const sam = await signUp();
    const { householdId, memberId } = await createHousehold(sam);

    const first = await callAs<{ week: string }>(sam, 'recordActivity', { householdId });
    await callAs(sam, 'recordActivity', { householdId });

    expect(first.week).toBe(thisWeek());
    const entry = await ledger(`analyticsHouseholdWeeks/${first.week}_${householdId}`);
    expect(entry?.['activeMemberIds']).toEqual([memberId]);
  });

  it('makes a family active once a second member opens the app', async () => {
    const sam = await signUp();
    const { householdId, memberId } = await createHousehold(sam);
    const alex = await joinAs(sam, householdId);

    await callAs(sam, 'recordActivity', { householdId });
    await callAs(alex.user, 'recordActivity', { householdId });

    const entry = await ledger(`analyticsHouseholdWeeks/${thisWeek()}_${householdId}`);
    expect([...((entry?.['activeMemberIds'] as string[] | undefined) ?? [])].sort()).toEqual(
      [memberId, alex.memberId].sort(),
    );
  });

  it('ignores a member id the client tries to name, and counts the caller', async () => {
    const sam = await signUp();
    const { householdId, memberId } = await createHousehold(sam);
    const somebodyElse = await addMember(householdId, CHILD_NAME, 'member');

    await callAs(sam, 'recordActivity', { householdId, memberId: somebodyElse });

    const entry = await ledger(`analyticsHouseholdWeeks/${thisWeek()}_${householdId}`);
    expect(entry?.['activeMemberIds']).toEqual([memberId]);
  });

  it('refuses a stranger to the household, and writes nothing', async () => {
    const sam = await signUp();
    const stranger = await signUp();
    const { householdId } = await createHousehold(sam);

    await expectRefusal(callAs(stranger, 'recordActivity', { householdId }), 'notAMember');
    expect(await ledger(`analyticsHouseholdWeeks/${thisWeek()}_${householdId}`)).toBeUndefined();
  });

  it('refuses a household that does not exist the same way, so ids cannot be probed', async () => {
    const sam = await signUp();
    await expectRefusal(
      callAs(sam, 'recordActivity', { householdId: 'no-such-household' }),
      'notAMember',
    );
  });

  it('refuses a caller who is not signed in', async () => {
    await expectRefusal(callAs(null, 'recordActivity', { householdId: 'h1' }), 'notSignedIn');
  });

  it('refuses a body it cannot parse', async () => {
    const sam = await signUp();
    await expectRefusal(callAs(sam, 'recordActivity', {}), 'badRequest');
  });
});

describe('the triggers', () => {
  beforeEach(clearFirestore);

  it('puts a new household into the cohort of the week it was made', async () => {
    const sam = await signUp();
    const { householdId } = await createHousehold(sam);

    const cohort = await eventually(
      () => ledger(`analyticsHouseholds/${householdId}`),
      (entry) => entry !== undefined,
    );
    expect(cohort?.['cohortWeek']).toBe(thisWeek());
    expect(cohort?.['firstAdultInviteAt']).toBeNull();
  });

  it('records the first invite for an adult', async () => {
    const sam = await signUp();
    const { householdId } = await createHousehold(sam);
    const partner = await addMember(householdId, PARTNER_NAME, 'member');

    await callAs(sam, 'createInvite', { householdId, memberId: partner });

    const cohort = await eventually(
      () => ledger(`analyticsHouseholds/${householdId}`),
      (entry) => entry?.['firstAdultInviteAt'] instanceof Timestamp,
    );
    expect(cohort?.['firstAdultInviteAt']).toBeInstanceOf(Timestamp);
    expect(cohort?.['firstAdultInviteRole']).toBe('member');
  });

  it('does not count an invite for a child"s profile as inviting an adult', async () => {
    const sam = await signUp();
    const { householdId } = await createHousehold(sam);
    const child = await addMember(householdId, CHILD_NAME, 'kid');

    await callAs(sam, 'createInvite', { householdId, memberId: child });
    // The household trigger seeds the entry; give the invite trigger time to
    // have run too, then check it left the invite unrecorded.
    await eventually(
      () => ledger(`analyticsHouseholds/${householdId}`),
      (entry) => entry !== undefined,
    );
    await new Promise((resolve) => setTimeout(resolve, 2_000));

    expect((await ledger(`analyticsHouseholds/${householdId}`))?.['firstAdultInviteAt']).toBeNull();
  });

  it('counts a lunch plan from its path alone, once per plan', async () => {
    const sam = await signUp();
    const { householdId } = await createHousehold(sam);
    const plans = adminDb().collection('households').doc(householdId).collection('lunchPlans');

    // The plan's contents are lunch-box's business and are never read here.
    await plans.doc('m-mia_2026-09-28').set({ child: CHILD_NAME, monday: 'peanut butter' });
    await plans.doc('m-leo_2026-09-28').set({ child: 'Leo', monday: 'cheese' });

    const entry = await eventually(
      () => ledger(`analyticsHouseholdWeeks/${thisWeek()}_${householdId}`),
      (value) => ((value?.['lunchPlanIds'] as unknown[] | undefined) ?? []).length === 2,
    );
    expect([...((entry?.['lunchPlanIds'] as string[] | undefined) ?? [])].sort()).toEqual([
      'm-leo_2026-09-28',
      'm-mia_2026-09-28',
    ]);
  });
});
