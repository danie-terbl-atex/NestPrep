import { beforeEach, describe, expect, it } from 'vitest';

import { expectRefusal, householdOfTwo } from './calendar_sync_fixture';
import { adminDb, callAs, clearFirestore, signUp } from './emulator_harness';

/**
 * `setCarerShiftOnly` end to end, over HTTP with a real token (nanny-hub
 * ADR-0006, BE-14): an admin marks a carer shift-only and lifts it again, and
 * every refusal is told apart by its reason and writes nothing.
 */

async function memberOf(householdId: string, uid: string): Promise<string> {
  const claimed = await adminDb()
    .collection(`households/${householdId}/members`)
    .where('claimedBy', '==', uid)
    .limit(1)
    .get();
  const member = claimed.docs[0];
  if (member === undefined) throw new Error('no claimed profile');
  return member.id;
}

async function shiftOnlyOf(householdId: string): Promise<unknown> {
  const household = await adminDb().collection('households').doc(householdId).get();
  return household.data()?.['shiftOnly'];
}

beforeEach(async () => {
  await clearFirestore();
});

describe('marking a carer shift-only', () => {
  it('lets the admin mark a carer, and lift it again', async () => {
    const { sam, thandi: nomsa, householdId } = await householdOfTwo('carer');
    const memberId = await memberOf(householdId, nomsa.uid);

    const marked = await callAs(sam, 'setCarerShiftOnly', {
      householdId,
      memberId,
      shiftOnly: true,
    });
    expect(marked).toEqual({ householdId, memberId, shiftOnly: true });
    expect(await shiftOnlyOf(householdId)).toEqual({ [memberId]: true });

    await callAs(sam, 'setCarerShiftOnly', { householdId, memberId, shiftOnly: false });
    expect(await shiftOnlyOf(householdId)).toEqual({});
  });

  it('refuses the carer marking or unmarking themself', async () => {
    const { thandi: nomsa, householdId } = await householdOfTwo('carer');
    const memberId = await memberOf(householdId, nomsa.uid);
    await expectRefusal(
      callAs(nomsa, 'setCarerShiftOnly', { householdId, memberId, shiftOnly: false }),
      'notAnAdmin',
    );
    expect(await shiftOnlyOf(householdId)).toBeUndefined();
  });

  it('refuses a parent who is not the admin', async () => {
    const { sam, thandi: pat, householdId } = await householdOfTwo('parent');
    const memberId = await memberOf(householdId, sam.uid);
    await expectRefusal(
      callAs(pat, 'setCarerShiftOnly', { householdId, memberId, shiftOnly: true }),
      'notAnAdmin',
    );
  });

  it('refuses marking somebody who is not a carer', async () => {
    const { sam, thandi: pat, householdId } = await householdOfTwo('parent');
    const memberId = await memberOf(householdId, pat.uid);
    await expectRefusal(
      callAs(sam, 'setCarerShiftOnly', { householdId, memberId, shiftOnly: true }),
      'notACarer',
    );
    expect(await shiftOnlyOf(householdId)).toBeUndefined();
  });

  it('refuses a profile that is not there', async () => {
    const { sam, householdId } = await householdOfTwo('carer');
    await expectRefusal(
      callAs(sam, 'setCarerShiftOnly', { householdId, memberId: 'nobody', shiftOnly: true }),
      'memberNotFound',
    );
  });

  it('refuses somebody outside the household, and a household that is not there', async () => {
    const { sam, thandi: nomsa, householdId } = await householdOfTwo('carer');
    const memberId = await memberOf(householdId, nomsa.uid);
    await expectRefusal(
      callAs(await signUp(), 'setCarerShiftOnly', { householdId, memberId, shiftOnly: true }),
      'notAMember',
    );
    await expectRefusal(
      callAs(sam, 'setCarerShiftOnly', { householdId: 'nowhere', memberId, shiftOnly: true }),
      'notAMember',
    );
  });
});
