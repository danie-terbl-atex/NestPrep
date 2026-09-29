import { describe, expect, it } from 'vitest';

import {
  type ClaimedAdult,
  decideOutcome,
  endingsAgree,
} from '../../src/account_data/household_outcome';
import { previewBody } from '../../src/account_data/preview_account_deletion';

/**
 * What deleting an account does to each household (accounts ADR-0006) — the
 * rule itself, tested where it lives (`BE-14`). The emulator suite proves the
 * callables carry it out.
 */

const adult = (uid: string, role: ClaimedAdult['role'], createdAtMillis: number): ClaimedAdult => ({
  uid,
  memberId: `m-${uid}`,
  role,
  createdAtMillis,
});

describe('decideOutcome', () => {
  it('a parent who is not the admin simply leaves', () => {
    expect(decideOutcome('sam', { sam: 'parent', alex: 'admin' }, [])).toEqual({ kind: 'leave' });
  });

  it('a helper or carer simply leaves', () => {
    expect(decideOutcome('thandi', { thandi: 'helper', sam: 'admin' }, [])).toEqual({
      kind: 'leave',
    });
  });

  it('an admin beside another admin leaves, and nobody is promoted', () => {
    expect(
      decideOutcome('sam', { sam: 'admin', alex: 'admin' }, [adult('alex', 'admin', 1)]),
    ).toEqual({ kind: 'leave' });
  });

  it('the last admin hands over to the adult who has been in the family longest', () => {
    const outcome = decideOutcome('sam', { sam: 'admin', alex: 'parent', jo: 'parent' }, [
      adult('jo', 'parent', 20),
      adult('alex', 'parent', 10),
    ]);
    expect(outcome).toEqual({ kind: 'handOver', toUid: 'alex', toMemberId: 'm-alex' });
  });

  it('reads the old `member` role as a family adult too (household ADR-0003)', () => {
    expect(
      decideOutcome('sam', { sam: 'admin', gran: 'member' }, [adult('gran', 'member', 5)]),
    ).toEqual({ kind: 'handOver', toUid: 'gran', toMemberId: 'm-gran' });
  });

  it('never hands a household to a helper, a carer or a kid — it ends instead', () => {
    const roles = { sam: 'admin', thandi: 'helper', nomsa: 'carer', teen: 'kid' } as const;
    const outcome = decideOutcome('sam', roles, [
      adult('thandi', 'helper', 1),
      adult('nomsa', 'carer', 2),
      adult('teen', 'kid', 3),
    ]);
    expect(outcome).toEqual({ kind: 'end' });
  });

  it('ends a household where the admin is the only account', () => {
    expect(decideOutcome('sam', { sam: 'admin' }, [])).toEqual({ kind: 'end' });
  });

  it('ignores a profile whose claimant is no longer in the role map — a stale claim is nobody', () => {
    expect(decideOutcome('sam', { sam: 'admin' }, [adult('alex', 'parent', 1)])).toEqual({
      kind: 'end',
    });
  });

  it('breaks a tie on the uid, so the same household always makes the same choice', () => {
    const roles = { sam: 'admin', b: 'parent', a: 'parent' } as const;
    const outcome = decideOutcome('sam', roles, [adult('b', 'parent', 1), adult('a', 'parent', 1)]);
    expect(outcome).toEqual({ kind: 'handOver', toUid: 'a', toMemberId: 'm-a' });
  });
});

describe('endingsAgree', () => {
  it('agrees when the same households would end, in any order', () => {
    expect(endingsAgree(['h2', 'h1'], ['h1', 'h2'])).toBe(true);
    expect(endingsAgree([], [])).toBe(true);
  });

  it('refuses one ending more than the person agreed to', () => {
    expect(endingsAgree(['h1'], ['h1', 'h2'])).toBe(false);
  });

  it('refuses one fewer — the preview they read is out of date either way', () => {
    expect(endingsAgree(['h1', 'h2'], ['h1'])).toBe(false);
  });
});

describe('previewBody — the wire shape', () => {
  it('names the outcome and the successor but never another person’s uid or member id', () => {
    const body = previewBody({
      renewingSubscriptions: 1,
      households: [
        {
          householdId: 'h1',
          name: 'The Parkers',
          role: 'admin',
          memberId: 'm-sam',
          outcome: { kind: 'handOver', toUid: 'uid-alex', toMemberId: 'm-alex' },
          successorName: 'Alex',
          othersLosingAccess: 3,
          hasPremium: true,
        },
      ],
    });
    expect(body).toEqual({
      renewingSubscriptions: 1,
      households: [
        {
          householdId: 'h1',
          name: 'The Parkers',
          outcome: 'handOver',
          successorName: 'Alex',
          othersLosingAccess: 3,
          hasPremium: true,
        },
      ],
    });
    expect(JSON.stringify(body)).not.toContain('uid-alex');
  });
});
