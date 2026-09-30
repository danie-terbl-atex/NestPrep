import { beforeEach, describe, expect, it } from 'vitest';

import { ALTERNATING, DADS_HOME, MUMS_HOME } from '../coparent_fixtures';
import { expectRefusal } from './calendar_sync_fixture';
import { aCode, accept, aKid, linkedHomes, mirrorOf, twoHomes } from './coparent_fixture';
import { adminDb, callAs, clearFirestore } from './emulator_harness';

/**
 * Making, accepting, confirming and ending a link between two homes, over
 * HTTP with real tokens (household ADR-0004, BE-14): both admins accept, the
 * link is pending until the home that made the code confirms, and each home
 * gets its own copy with nothing of the other household in it.
 */

beforeEach(async () => {
  await clearFirestore();
});

describe('making a code', () => {
  it('lets an admin offer one of their kids, and keeps the code server-side', async () => {
    const homes = await twoHomes();
    const code = await aCode(homes);
    expect(code).toMatch(/^[2-9A-HJ-NP-Z]{8}$/);
    const stored = (await adminDb().doc(`coParentInvites/${code}`).get()).data();
    expect(stored?.['householdId']).toBe(homes.mum.householdId);
    expect(stored?.['childName']).toBe('Sam');
    expect(stored?.['redeemedBy']).toBeNull();
  });

  it('refuses a parent who is not an admin', async () => {
    const homes = await twoHomes();
    await expectRefusal(
      callAs(homes.mum.thandi, 'createCoParentInvite', {
        householdId: homes.mum.householdId,
        childMemberId: homes.mumChild,
        home: MUMS_HOME,
        schedule: ALTERNATING,
      }),
      'notAnAdmin',
    );
  });

  it('refuses a profile that is not a kid', async () => {
    const homes = await twoHomes();
    const members = await adminDb()
      .collection(`households/${homes.mum.householdId}/members`)
      .where('claimedBy', '==', homes.mum.thandi.uid)
      .get();
    const parentProfile = members.docs[0]?.id ?? 'missing';
    await expectRefusal(aCode(homes, parentProfile), 'childNotFound');
  });

  it('refuses an admin of another household', async () => {
    const homes = await twoHomes();
    await expectRefusal(
      callAs(homes.dad.sam, 'createCoParentInvite', {
        householdId: homes.mum.householdId,
        childMemberId: homes.mumChild,
        home: MUMS_HOME,
        schedule: ALTERNATING,
      }),
      'notAMember',
    );
  });
});

describe('previewing a code', () => {
  it('shows exactly what the other admin is agreeing to, and nothing else', async () => {
    const homes = await twoHomes();
    const preview = await callAs<Record<string, unknown>>(homes.dad.sam, 'previewCoParentInvite', {
      code: (await aCode(homes)).toLowerCase(),
    });
    expect(Object.keys(preview).sort()).toEqual(['childName', 'expiresAt', 'home', 'schedule']);
    expect(preview['childName']).toBe('Sam');
    expect(preview['home']).toEqual(MUMS_HOME);
    expect(JSON.stringify(preview)).not.toContain(homes.mum.householdId);
  });

  it('refuses a code that is not one', async () => {
    const homes = await twoHomes();
    await expectRefusal(
      callAs(homes.dad.sam, 'previewCoParentInvite', { code: 'ZZZZ2345' }),
      'linkInviteNotFound',
    );
  });
});

describe('accepting a code', () => {
  it('makes a pending link with a copy in each home and none of the other household in it', async () => {
    const homes = await twoHomes();
    const linkId = await accept(homes, await aCode(homes));

    const authority = (await adminDb().doc(`coParentLinks/${linkId}`).get()).data();
    expect(authority?.['householdIds']).toEqual({
      a: homes.mum.householdId,
      b: homes.dad.householdId,
    });
    expect(authority?.['status']).toBe('pending');

    const mum = await mirrorOf(homes.mum.householdId, linkId);
    const dad = await mirrorOf(homes.dad.householdId, linkId);
    expect(mum['ownSide']).toBe('a');
    expect(dad['ownSide']).toBe('b');
    expect(mum['childMemberId']).toBe(homes.mumChild);
    expect(dad['childMemberId']).toBe(homes.dadChild);
    expect(mum['homes']).toEqual({ a: MUMS_HOME, b: DADS_HOME });
    expect(mum['awaitingSide']).toBe('a');
    // The boundary: neither copy names the other household or its profile.
    expect(JSON.stringify(dad)).not.toContain(homes.mum.householdId);
    expect(JSON.stringify(dad)).not.toContain(homes.mumChild);
    expect(JSON.stringify(mum)).not.toContain(homes.dad.householdId);
    expect(JSON.stringify(mum)).not.toContain(homes.dadChild);
  });

  it('can make the child’s profile in the accepting home', async () => {
    const homes = await twoHomes();
    const { linkId } = await callAs<{ linkId: string }>(homes.dad.sam, 'acceptCoParentInvite', {
      householdId: homes.dad.householdId,
      code: await aCode(homes),
      childMemberId: null,
      newChildName: 'Sammy',
      home: DADS_HOME,
    });
    const childId = String((await mirrorOf(homes.dad.householdId, linkId))['childMemberId']);
    const profile = (
      await adminDb().doc(`households/${homes.dad.householdId}/members/${childId}`).get()
    ).data();
    expect(profile).toMatchObject({ displayName: 'Sammy', role: 'kid', claimedBy: null });
  });

  it('is single use', async () => {
    const homes = await twoHomes();
    const code = await aCode(homes);
    await accept(homes, code);
    const third = await aKid(homes.dad.householdId, 'Also Sam');
    await expectRefusal(
      callAs(homes.dad.sam, 'acceptCoParentInvite', {
        householdId: homes.dad.householdId,
        code,
        childMemberId: third,
        newChildName: null,
        home: DADS_HOME,
      }),
      'linkInviteUsed',
    );
  });

  it('refuses the home that made the code', async () => {
    const homes = await twoHomes();
    await expectRefusal(
      callAs(homes.mum.sam, 'acceptCoParentInvite', {
        householdId: homes.mum.householdId,
        code: await aCode(homes),
        childMemberId: homes.mumChild,
        newChildName: null,
        home: DADS_HOME,
      }),
      'sameHousehold',
    );
  });

  it('refuses a carer in the accepting home — only an admin agrees for a home', async () => {
    const homes = await twoHomes();
    await expectRefusal(
      callAs(homes.dad.thandi, 'acceptCoParentInvite', {
        householdId: homes.dad.householdId,
        code: await aCode(homes),
        childMemberId: homes.dadChild,
        newChildName: null,
        home: DADS_HOME,
      }),
      'notAnAdmin',
    );
  });

  it('refuses a child already linked, on either side', async () => {
    const homes = await linkedHomes();
    await expectRefusal(aCode(homes), 'childAlreadyLinked');
    const another = await aKid(homes.mum.householdId, 'Lerato');
    await expectRefusal(accept(homes, await aCode(homes, another)), 'childAlreadyLinked');
  });
});

describe('confirming and ending', () => {
  it('only the home that made the code confirms, and only its admin', async () => {
    const homes = await twoHomes();
    const linkId = await accept(homes, await aCode(homes));
    await expectRefusal(
      callAs(homes.dad.sam, 'confirmCoParentLink', {
        householdId: homes.dad.householdId,
        linkId,
        accept: true,
      }),
      'notYourTurn',
    );
    await expectRefusal(
      callAs(homes.mum.thandi, 'confirmCoParentLink', {
        householdId: homes.mum.householdId,
        linkId,
        accept: true,
      }),
      'notAnAdmin',
    );
    await callAs(homes.mum.sam, 'confirmCoParentLink', {
      householdId: homes.mum.householdId,
      linkId,
      accept: true,
    });
    expect((await mirrorOf(homes.mum.householdId, linkId))['status']).toBe('active');
    expect((await mirrorOf(homes.dad.householdId, linkId))['status']).toBe('active');
    expect((await adminDb().doc(`coParentLinks/${linkId}`).get()).get('status')).toBe('active');
  });

  it('declining leaves both copies declined, and it cannot be confirmed afterwards', async () => {
    const homes = await twoHomes();
    const linkId = await accept(homes, await aCode(homes));
    const answer = { householdId: homes.mum.householdId, linkId, accept: false };
    await callAs(homes.mum.sam, 'confirmCoParentLink', answer);
    expect((await mirrorOf(homes.dad.householdId, linkId))['status']).toBe('declined');
    await expectRefusal(
      callAs(homes.mum.sam, 'confirmCoParentLink', { ...answer, accept: true }),
      'linkNotActive',
    );
  });

  it('a link id from somewhere else reads as no link at all', async () => {
    const homes = await linkedHomes();
    const stranger = await twoHomes();
    await expectRefusal(
      callAs(stranger.mum.sam, 'endCoParentLink', {
        householdId: stranger.mum.householdId,
        linkId: homes.linkId,
      }),
      'linkNotFound',
    );
  });

  it('either admin ends it; both copies say so, and the child can be linked again', async () => {
    const homes = await linkedHomes();
    await expectRefusal(
      callAs(homes.dad.thandi, 'endCoParentLink', {
        householdId: homes.dad.householdId,
        linkId: homes.linkId,
      }),
      'notAnAdmin',
    );
    await callAs(homes.dad.sam, 'endCoParentLink', {
      householdId: homes.dad.householdId,
      linkId: homes.linkId,
    });
    const mum = await mirrorOf(homes.mum.householdId, homes.linkId);
    expect(mum['status']).toBe('ended');
    expect(mum['endedBySide']).toBe('b');
    await expectRefusal(
      callAs(homes.mum.sam, 'endCoParentLink', {
        householdId: homes.mum.householdId,
        linkId: homes.linkId,
      }),
      'linkNotActive',
    );
    await expect(aCode(homes)).resolves.toMatch(/^[2-9A-HJ-NP-Z]{8}$/);
  });
});
