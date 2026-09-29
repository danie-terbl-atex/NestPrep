import { Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import {
  mayAnswer,
  requireHandoverDate,
  statusAfter,
  storedSwapDays,
  swapDays,
  withSwap,
} from '../../src/coparent/change_rules';
import { sharedChildName } from '../../src/coparent/child_profiles';
import { requireRoleFrom } from '../../src/coparent/coparent_caller';
import { COPARENT_REFUSALS, refuseCoParent } from '../../src/coparent/errors';
import { usableInvite } from '../../src/coparent/link_invite';
import { otherSideOf } from '../../src/coparent/link_context';
import { ALTERNATING } from '../coparent_fixtures';

/**
 * The decisions the co-parenting callables make, without an emulator
 * (household ADR-0004): who may act, what a swap moves, who answers what,
 * and when a code still works. The emulator suite proves the wiring; this
 * proves the choices, including every refusal's reason.
 */

function reasonOf(action: () => unknown): string | undefined {
  try {
    action();
  } catch (error) {
    if (error instanceof HttpsError) {
      const details: unknown = error.details;
      if (typeof details === 'object' && details !== null && 'reason' in details) {
        return String(details.reason);
      }
    }
    throw error;
  }
  return undefined;
}

const NOW = new Date('2026-09-29T10:00:00Z');

describe('who may act', () => {
  const household = {
    members: {
      'uid-admin': 'admin',
      'uid-parent': 'parent',
      'uid-legacy': 'member',
      'uid-kid': 'kid',
      'uid-helper': 'helper',
      'uid-carer': 'carer',
    },
  };

  it('an admin manages the link; a parent does not', () => {
    expect(
      reasonOf(() => {
        requireRoleFrom(household, 'uid-admin', 'admin');
      }),
    ).toBeUndefined();
    expect(
      reasonOf(() => {
        requireRoleFrom(household, 'uid-parent', 'admin');
      }),
    ).toBe('notAnAdmin');
  });

  it('family — admin, parent and the old member — writes handovers and requests', () => {
    for (const uid of ['uid-admin', 'uid-parent', 'uid-legacy']) {
      expect(
        reasonOf(() => {
          requireRoleFrom(household, uid, 'family');
        }),
        uid,
      ).toBeUndefined();
    }
  });

  it('a kid, helper or carer does not, whatever their calendar grant says', () => {
    for (const uid of ['uid-kid', 'uid-helper', 'uid-carer']) {
      expect(
        reasonOf(() => {
          requireRoleFrom(household, uid, 'family');
        }),
        uid,
      ).toBe('notFamily');
    }
  });

  it('somebody from another household is not a member here', () => {
    expect(
      reasonOf(() => {
        requireRoleFrom(household, 'uid-stranger', 'family');
      }),
    ).toBe('notAMember');
  });

  it('a household document that does not parse admits nobody', () => {
    expect(
      reasonOf(() => {
        requireRoleFrom(undefined, 'uid-admin', 'admin');
      }),
    ).toBe('notAMember');
    expect(
      reasonOf(() => {
        requireRoleFrom({ members: 'x' }, 'uid-admin', 'admin');
      }),
    ).toBe('notAMember');
  });
});

describe('a swap', () => {
  it('names every day it moves', () => {
    expect(swapDays('2026-10-02', '2026-10-04', NOW)).toEqual([
      '2026-10-02',
      '2026-10-03',
      '2026-10-04',
    ]);
  });

  it('is at most fourteen days; longer is a new schedule', () => {
    expect(swapDays('2026-10-01', '2026-10-14', NOW)).toHaveLength(14);
    expect(reasonOf(() => swapDays('2026-10-01', '2026-10-15', NOW))).toBe('dateOutOfRange');
  });

  it('ends on or after the day it starts', () => {
    expect(reasonOf(() => swapDays('2026-10-04', '2026-10-02', NOW))).toBe('dateOutOfRange');
  });

  it('may record last week, but not last month', () => {
    expect(swapDays('2026-09-22', '2026-09-22', NOW)).toEqual(['2026-09-22']);
    expect(reasonOf(() => swapDays('2026-08-29', '2026-08-30', NOW))).toBe('dateOutOfRange');
  });

  it('may not be arranged more than a year ahead', () => {
    expect(reasonOf(() => swapDays('2027-11-01', '2027-11-02', NOW))).toBe('dateOutOfRange');
  });

  it('accepted late still records what happened, capped at fourteen days', () => {
    expect(storedSwapDays('2026-01-01', '2026-01-02')).toEqual(['2026-01-01', '2026-01-02']);
    expect(storedSwapDays('2026-01-01', '2026-02-01')).toEqual([]);
    expect(storedSwapDays('nonsense', '2026-02-01')).toEqual([]);
  });

  it('becomes overrides, dropping any older than a year', () => {
    const overrides = withSwap(
      { '2025-01-01': 'a', '2026-09-01': 'b' },
      ['2026-10-02', '2026-10-03'],
      'a',
      NOW,
    );
    expect(overrides).toEqual({ '2026-09-01': 'b', '2026-10-02': 'a', '2026-10-03': 'a' });
  });

  it('replaces an earlier override for the same day', () => {
    expect(withSwap({ '2026-10-02': 'b' }, ['2026-10-02'], 'a', NOW)).toEqual({
      '2026-10-02': 'a',
    });
  });
});

describe('answering a request', () => {
  it('the other home accepts or declines; the home that asked may only withdraw', () => {
    expect(mayAnswer('b', 'a', 'accept')).toBe(true);
    expect(mayAnswer('b', 'a', 'decline')).toBe(true);
    expect(mayAnswer('a', 'a', 'withdraw')).toBe(true);
    expect(mayAnswer('a', 'a', 'accept')).toBe(false);
    expect(mayAnswer('a', 'a', 'decline')).toBe(false);
    expect(mayAnswer('b', 'a', 'withdraw')).toBe(false);
  });

  it('leaves the request in the status its answer names', () => {
    expect(statusAfter('accept')).toBe('accepted');
    expect(statusAfter('decline')).toBe('declined');
    expect(statusAfter('withdraw')).toBe('withdrawn');
  });

  it('the other side of a is b, and of b is a', () => {
    expect(otherSideOf('a')).toBe('b');
    expect(otherSideOf('b')).toBe('a');
  });
});

describe('a handover', () => {
  it('may be written up to sixty days after it happened, and a year ahead', () => {
    expect(
      reasonOf(() => {
        requireHandoverDate('2026-08-01', NOW);
      }),
    ).toBeUndefined();
    expect(
      reasonOf(() => {
        requireHandoverDate('2026-07-01', NOW);
      }),
    ).toBe('dateOutOfRange');
    expect(
      reasonOf(() => {
        requireHandoverDate('2027-10-30', NOW);
      }),
    ).toBe('dateOutOfRange');
    expect(
      reasonOf(() => {
        requireHandoverDate('2026-02-30', NOW);
      }),
    ).toBe('dateOutOfRange');
  });
});

describe('a code', () => {
  const invite = {
    householdId: 'h-mum',
    childMemberId: 'm-sam',
    childName: 'Sam',
    home: { name: 'Mum’s home', color: 'coral' },
    schedule: ALTERNATING,
    expiresAt: Timestamp.fromMillis(NOW.getTime() + 60_000),
    redeemedBy: null,
  };

  it('works while it is unused and in date', () => {
    expect(usableInvite(invite, NOW.getTime()).childName).toBe('Sam');
  });

  it('is told apart: used, expired, or not one at all', () => {
    expect(reasonOf(() => usableInvite({ ...invite, redeemedBy: 'uid-x' }, NOW.getTime()))).toBe(
      'linkInviteUsed',
    );
    expect(reasonOf(() => usableInvite(invite, NOW.getTime() + 120_000))).toBe('linkInviteExpired');
    expect(reasonOf(() => usableInvite(undefined, NOW.getTime()))).toBe('linkInviteNotFound');
    expect(reasonOf(() => usableInvite({ ...invite, schedule: {} }, NOW.getTime()))).toBe(
      'linkInviteNotFound',
    );
  });
});

describe('what the other home is told', () => {
  it('is the child’s first name only', () => {
    expect(sharedChildName('Sam Parker-Mokoena')).toBe('Sam');
    expect(sharedChildName('  Lerato  ')).toBe('Lerato');
  });
});

describe('every refusal', () => {
  it('carries its own name as the reason the client reads', () => {
    for (const reason of Object.keys(COPARENT_REFUSALS) as (keyof typeof COPARENT_REFUSALS)[]) {
      const error = refuseCoParent(reason);
      expect(error.details).toEqual({ reason });
      expect(error.code).toBe(COPARENT_REFUSALS[reason][0]);
    }
  });
});
