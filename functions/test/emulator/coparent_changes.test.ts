import { beforeEach, describe, expect, it } from 'vitest';

import { TWO_TWO_THREE } from '../coparent_fixtures';
import { expectRefusal } from './calendar_sync_fixture';
import { aCode, accept, isoInDays, linkedHomes, mirrorOf, twoHomes } from './coparent_fixture';
import { adminDb, callAs, clearFirestore } from './emulator_harness';

/**
 * Swaps, new schedules and handovers between two homes, over HTTP with real
 * tokens (household ADR-0004, BE-14): family in either home asks, family in
 * the other answers, accepting applies it to both copies at once, and a
 * handover is the same record in both homes.
 */

beforeEach(async () => {
  await clearFirestore();
});

async function requestsIn(householdId: string, linkId: string): Promise<Record<string, unknown>[]> {
  const snapshot = await adminDb()
    .collection(`households/${householdId}/coParentLinks/${linkId}/requests`)
    .get();
  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

describe('asking for a swap', () => {
  it('lets a parent ask, and puts the same request in both homes', async () => {
    const homes = await linkedHomes();
    const { requestId } = await callAs<{ requestId: string }>(
      homes.mum.thandi,
      'proposeCoParentChange',
      {
        householdId: homes.mum.householdId,
        linkId: homes.linkId,
        change: { kind: 'swap', from: isoInDays(3), to: isoInDays(5), toSide: 'a' },
        note: 'Grandma’s birthday',
      },
    );
    for (const householdId of [homes.mum.householdId, homes.dad.householdId]) {
      const [request] = await requestsIn(householdId, homes.linkId);
      expect(request).toMatchObject({
        id: requestId,
        kind: 'swap',
        toSide: 'a',
        proposedBySide: 'a',
        status: 'pending',
        note: 'Grandma’s birthday',
      });
    }
  });

  it('refuses a carer — the other home is talking to the adults', async () => {
    const homes = await linkedHomes();
    await expectRefusal(
      callAs(homes.dad.thandi, 'proposeCoParentChange', {
        householdId: homes.dad.householdId,
        linkId: homes.linkId,
        change: { kind: 'swap', from: isoInDays(3), to: isoInDays(4), toSide: 'b' },
        note: null,
      }),
      'notFamily',
    );
  });

  it('refuses before the link is confirmed', async () => {
    const homes = await twoHomes();
    const linkId = await accept(homes, await aCode(homes));
    await expectRefusal(
      callAs(homes.dad.sam, 'proposeCoParentChange', {
        householdId: homes.dad.householdId,
        linkId,
        change: { kind: 'swap', from: isoInDays(3), to: isoInDays(4), toSide: 'b' },
        note: null,
      }),
      'linkNotActive',
    );
  });

  it('refuses a swap longer than a fortnight, or long in the past', async () => {
    const homes = await linkedHomes();
    const ask = (from: string, to: string): Promise<unknown> =>
      callAs(homes.mum.sam, 'proposeCoParentChange', {
        householdId: homes.mum.householdId,
        linkId: homes.linkId,
        change: { kind: 'swap', from, to, toSide: 'a' },
        note: null,
      });
    await expectRefusal(ask(isoInDays(1), isoInDays(20)), 'dateOutOfRange');
    await expectRefusal(ask(isoInDays(-40), isoInDays(-39)), 'dateOutOfRange');
  });
});

describe('answering', () => {
  async function aSwapFromDad(): Promise<
    Awaited<ReturnType<typeof linkedHomes>> & { requestId: string }
  > {
    const homes = await linkedHomes();
    const { requestId } = await callAs<{ requestId: string }>(
      homes.dad.sam,
      'proposeCoParentChange',
      {
        householdId: homes.dad.householdId,
        linkId: homes.linkId,
        change: { kind: 'swap', from: isoInDays(2), to: isoInDays(3), toSide: 'b' },
        note: null,
      },
    );
    return { ...homes, requestId };
  }

  it('the home that asked cannot accept its own request', async () => {
    const homes = await aSwapFromDad();
    await expectRefusal(
      callAs(homes.dad.sam, 'answerCoParentChange', {
        householdId: homes.dad.householdId,
        linkId: homes.linkId,
        requestId: homes.requestId,
        answer: 'accept',
        note: null,
      }),
      'notYourTurn',
    );
  });

  it('the other home accepts, and the days move in both copies', async () => {
    const homes = await aSwapFromDad();
    await callAs(homes.mum.thandi, 'answerCoParentChange', {
      householdId: homes.mum.householdId,
      linkId: homes.linkId,
      requestId: homes.requestId,
      answer: 'accept',
      note: 'Of course',
    });
    for (const householdId of [homes.mum.householdId, homes.dad.householdId]) {
      const mirror = await mirrorOf(householdId, homes.linkId);
      expect(mirror['overrides']).toEqual({ [isoInDays(2)]: 'b', [isoInDays(3)]: 'b' });
      const [request] = await requestsIn(householdId, homes.linkId);
      expect(request).toMatchObject({
        status: 'accepted',
        answeredBySide: 'a',
        answerNote: 'Of course',
      });
    }
  });

  it('a second answer is refused, not applied twice', async () => {
    const homes = await aSwapFromDad();
    const answer = {
      householdId: homes.mum.householdId,
      linkId: homes.linkId,
      requestId: homes.requestId,
      answer: 'decline',
      note: null,
    };
    await callAs(homes.mum.sam, 'answerCoParentChange', answer);
    await expectRefusal(
      callAs(homes.mum.sam, 'answerCoParentChange', { ...answer, answer: 'accept' }),
      'requestAlreadyAnswered',
    );
    expect((await mirrorOf(homes.dad.householdId, homes.linkId))['overrides']).toEqual({});
  });

  it('the home that asked may withdraw; the other may not', async () => {
    const homes = await aSwapFromDad();
    const withdraw = {
      linkId: homes.linkId,
      requestId: homes.requestId,
      answer: 'withdraw',
      note: null,
    };
    await expectRefusal(
      callAs(homes.mum.sam, 'answerCoParentChange', {
        ...withdraw,
        householdId: homes.mum.householdId,
      }),
      'notYourTurn',
    );
    await callAs(homes.dad.sam, 'answerCoParentChange', {
      ...withdraw,
      householdId: homes.dad.householdId,
    });
    const [request] = await requestsIn(homes.mum.householdId, homes.linkId);
    expect(request?.['status']).toBe('withdrawn');
  });

  it('an accepted new schedule replaces the old one in both copies', async () => {
    const homes = await linkedHomes();
    const { requestId } = await callAs<{ requestId: string }>(
      homes.mum.sam,
      'proposeCoParentChange',
      {
        householdId: homes.mum.householdId,
        linkId: homes.linkId,
        change: { kind: 'schedule', schedule: TWO_TWO_THREE },
        note: null,
      },
    );
    await callAs(homes.dad.sam, 'answerCoParentChange', {
      householdId: homes.dad.householdId,
      linkId: homes.linkId,
      requestId,
      answer: 'accept',
      note: null,
    });
    for (const householdId of [homes.mum.householdId, homes.dad.householdId]) {
      expect((await mirrorOf(householdId, homes.linkId))['schedule']).toEqual(TWO_TWO_THREE);
    }
  });

  it('ending the link closes what was still waiting, on both sides', async () => {
    const homes = await aSwapFromDad();
    await callAs(homes.mum.sam, 'endCoParentLink', {
      householdId: homes.mum.householdId,
      linkId: homes.linkId,
    });
    for (const householdId of [homes.mum.householdId, homes.dad.householdId]) {
      const [request] = await requestsIn(householdId, homes.linkId);
      expect(request?.['status']).toBe('closed');
    }
  });
});

describe('a handover', () => {
  const handover = {
    items: [
      { text: 'School bag', packed: true },
      { text: 'Inhaler', packed: false },
    ],
    medicine: 'Inhaler at 7',
    homework: 'Reading log',
    clothes: null,
    note: '  ',
  };

  it('is the same record in both homes, and says which home saved it last', async () => {
    const homes = await linkedHomes();
    const date = isoInDays(4);
    await callAs(homes.mum.thandi, 'saveCoParentHandover', {
      householdId: homes.mum.householdId,
      linkId: homes.linkId,
      date,
      ...handover,
    });
    await callAs(homes.dad.sam, 'saveCoParentHandover', {
      householdId: homes.dad.householdId,
      linkId: homes.linkId,
      date,
      ...handover,
      clothes: 'Raincoat',
    });
    for (const householdId of [homes.mum.householdId, homes.dad.householdId]) {
      const stored = (
        await adminDb()
          .doc(`households/${householdId}/coParentLinks/${homes.linkId}/handovers/${date}`)
          .get()
      ).data();
      expect(stored).toMatchObject({
        date,
        items: handover.items,
        medicine: 'Inhaler at 7',
        clothes: 'Raincoat',
        note: null,
        updatedBySide: 'b',
      });
    }
  });

  it('refuses a carer, a date long past, and an unconfirmed link', async () => {
    const homes = await linkedHomes();
    await expectRefusal(
      callAs(homes.dad.thandi, 'saveCoParentHandover', {
        householdId: homes.dad.householdId,
        linkId: homes.linkId,
        date: isoInDays(1),
        ...handover,
      }),
      'notFamily',
    );
    await expectRefusal(
      callAs(homes.mum.sam, 'saveCoParentHandover', {
        householdId: homes.mum.householdId,
        linkId: homes.linkId,
        date: isoInDays(-90),
        ...handover,
      }),
      'dateOutOfRange',
    );
    const pending = await twoHomes();
    const linkId = await accept(pending, await aCode(pending));
    await expectRefusal(
      callAs(pending.mum.sam, 'saveCoParentHandover', {
        householdId: pending.mum.householdId,
        linkId,
        date: isoInDays(1),
        ...handover,
      }),
      'linkNotActive',
    );
  });
});
