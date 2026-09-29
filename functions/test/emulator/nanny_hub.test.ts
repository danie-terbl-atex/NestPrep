import { Timestamp } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it } from 'vitest';

import { ROLE_DEFAULTS } from '../../src/household/access';
import { expectRefusal, householdOfTwo } from './calendar_sync_fixture';
import { adminDb, callAs, clearFirestore, signUp, type TestUser } from './emulator_harness';

/**
 * `endNannyShift` end to end, over HTTP with a real token (nanny-hub ADR-0002,
 * BE-14): the carer ends their own shift and the parents' summary is written
 * from what was logged in the same transaction; every refusal is told apart
 * by its reason.
 */

interface Hub {
  readonly sam: TestUser;
  readonly nomsa: TestUser;
  readonly householdId: string;
  readonly nomsaMemberId: string;
  readonly samMemberId: string;
}

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

/** Sam the admin, and Nomsa a carer on the carer defaults — the hub at `edit`. */
async function aHubWithACarer(): Promise<Hub> {
  const { sam, thandi: nomsa, householdId } = await householdOfTwo('carer');
  return {
    sam,
    nomsa,
    householdId,
    nomsaMemberId: await memberOf(householdId, nomsa.uid),
    samMemberId: await memberOf(householdId, sam.uid),
  };
}

const at = (minutesAgo: number): Timestamp =>
  Timestamp.fromMillis(Date.now() - minutesAgo * 60_000);

async function givenAShift(hub: Hub, carerMemberId = hub.nomsaMemberId): Promise<string> {
  const home = adminDb().collection('households').doc(hub.householdId);
  const shift = home.collection('nannyShifts').doc();
  await shift.set({
    carerMemberId,
    startedBy: carerMemberId,
    startedAt: at(180),
    endedAt: null,
    endedBy: null,
    status: 'open',
    ticks: { 'bedtime:teeth': true },
  });
  await home
    .collection('nannyChecklists')
    .doc('bedtime')
    .set({
      items: [
        { id: 'teeth', text: 'Brush teeth' },
        { id: 'story', text: 'One story' },
      ],
      updatedBy: hub.samMemberId,
      updatedAt: new Date(),
    });
  const log = shift.collection('entries');
  const entry = (
    kind: string,
    minutesAgo: number,
    extra: Record<string, unknown> = {},
  ): Record<string, unknown> => ({
    kind,
    note: `${kind} note`,
    mood: null,
    childIds: ['m-zoe'],
    photoId: null,
    at: at(minutesAgo),
    byMemberId: carerMemberId,
    createdAt: new Date(),
    ...extra,
  });
  await log.doc('bath').set(entry('note', 30));
  await log.doc('tea').set(entry('meal', 120, { photoId: 'photo-tea-01' }));
  await log.doc('bump').set(entry('incident', 60, { note: 'Bumped her knee, fine now' }));
  return shift.id;
}

beforeEach(async () => {
  await clearFirestore();
});

describe('ending a shift', () => {
  it('ends the carer’s own shift and writes the summary the parents read', async () => {
    const hub = await aHubWithACarer();
    const shiftId = await givenAShift(hub);

    const result = await callAs<{ shiftId: string; entryCount: number }>(
      hub.nomsa,
      'endNannyShift',
      { householdId: hub.householdId, shiftId, closingNote: ' Asleep by 8. ' },
    );
    expect(result).toEqual({ shiftId, entryCount: 3 });

    const home = adminDb().collection('households').doc(hub.householdId);
    const shift = (await home.collection('nannyShifts').doc(shiftId).get()).data();
    expect(shift?.['status']).toBe('ended');
    expect(shift?.['endedAt']).toBeInstanceOf(Timestamp);
    expect(shift?.['endedBy']).toBe(hub.nomsaMemberId);

    const summary = (await home.collection('nannyShiftSummaries').doc(shiftId).get()).data();
    expect(summary?.['carerMemberId']).toBe(hub.nomsaMemberId);
    expect(summary?.['counts']).toMatchObject({ meal: 1, incident: 1, note: 1, nap: 0 });
    expect(summary?.['photoCount']).toBe(1);
    expect(summary?.['closingNote']).toBe('Asleep by 8.');
    expect(summary?.['checklist']).toEqual({ ticked: 1, total: 2 });
    // Born `pending`; notifications' trigger may already have delivered it
    // by the time this reads (notifications ADR-0001) — `notifications.test.ts`
    // follows it to `sent`.
    expect(['pending', 'sent']).toContain(
      (summary?.['delivery'] as { state?: string } | undefined)?.state,
    );
    const moments = summary?.['moments'] as { kind: string }[];
    expect(moments.map((moment) => moment.kind)).toEqual(['meal', 'incident', 'note']);
  });

  it('lets a parent end the carer’s shift for them', async () => {
    const hub = await aHubWithACarer();
    const shiftId = await givenAShift(hub);
    await callAs(hub.sam, 'endNannyShift', {
      householdId: hub.householdId,
      shiftId,
      closingNote: null,
    });
    const summary = await adminDb()
      .doc(`households/${hub.householdId}/nannyShiftSummaries/${shiftId}`)
      .get();
    expect(summary.data()?.['endedBy']).toBe(hub.samMemberId);
  });

  it('refuses to end a shift twice, and writes nothing the second time', async () => {
    const hub = await aHubWithACarer();
    const shiftId = await givenAShift(hub);
    const body = { householdId: hub.householdId, shiftId, closingNote: null };
    await callAs(hub.nomsa, 'endNannyShift', body);
    await expectRefusal(callAs(hub.nomsa, 'endNannyShift', body), 'shiftAlreadyEnded');
  });

  it('refuses a shift that does not exist', async () => {
    const hub = await aHubWithACarer();
    await expectRefusal(
      callAs(hub.nomsa, 'endNannyShift', {
        householdId: hub.householdId,
        shiftId: 'nope',
        closingNote: null,
      }),
      'shiftNotFound',
    );
  });

  it('refuses a carer ending somebody else’s shift, and leaves it open', async () => {
    const hub = await aHubWithACarer();
    const shiftId = await givenAShift(hub, hub.samMemberId);
    await expectRefusal(
      callAs(hub.nomsa, 'endNannyShift', {
        householdId: hub.householdId,
        shiftId,
        closingNote: null,
      }),
      'notYourShift',
    );
    const shift = await adminDb().doc(`households/${hub.householdId}/nannyShifts/${shiftId}`).get();
    expect(shift.data()?.['status']).toBe('open');
  });

  it('refuses a carer a parent narrowed to view, and one the hub is closed to', async () => {
    const hub = await aHubWithACarer();
    const shiftId = await givenAShift(hub);
    for (const level of ['view', 'none'] as const) {
      await callAs(hub.sam, 'setMemberAccess', {
        householdId: hub.householdId,
        memberId: hub.nomsaMemberId,
        access: { ...ROLE_DEFAULTS.carer, nannyHub: level },
      });
      await expectRefusal(
        callAs(hub.nomsa, 'endNannyShift', {
          householdId: hub.householdId,
          shiftId,
          closingNote: null,
        }),
        'hubNotShared',
      );
    }
  });

  it('refuses somebody outside the household, and somebody signed out', async () => {
    const hub = await aHubWithACarer();
    const shiftId = await givenAShift(hub);
    const body = { householdId: hub.householdId, shiftId, closingNote: null };
    await expectRefusal(callAs(await signUp(), 'endNannyShift', body), 'notAMember');
    await expectRefusal(callAs(null, 'endNannyShift', body), 'notSignedIn');
  });

  it('refuses a body it cannot read', async () => {
    const hub = await aHubWithACarer();
    await expectRefusal(
      callAs(hub.nomsa, 'endNannyShift', { householdId: hub.householdId }),
      'badRequest',
    );
  });
});
