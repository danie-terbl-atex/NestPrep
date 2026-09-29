import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import { parseInput } from '../../src/household/parse_input';
import { NANNY_REFUSALS, refuseNanny } from '../../src/nanny_hub/errors';
import { setCarerShiftOnlyInput } from '../../src/nanny_hub/schemas';
import { shiftOnlyRefusal } from '../../src/nanny_hub/set_carer_shift_only';

/**
 * Who may mark a carer shift-only (nanny-hub ADR-0006), tested where the
 * decision lives and without an emulator (BE-14): an admin, about a carer,
 * and nobody else about anybody else.
 */

const household = {
  members: {
    'uid-sam': 'admin',
    'uid-pat': 'parent',
    'uid-lee': 'member',
    'uid-nomsa': 'carer',
  },
};
const carer = { role: 'carer', displayName: 'Nomsa' };

describe('who may mark a carer shift-only', () => {
  it('lets an admin mark a carer', () => {
    expect(shiftOnlyRefusal(household, 'uid-sam', carer)).toBeNull();
  });

  it('refuses a parent, an old-style family member and the carer themself', () => {
    expect(shiftOnlyRefusal(household, 'uid-pat', carer)).toBe('notAnAdmin');
    expect(shiftOnlyRefusal(household, 'uid-lee', carer)).toBe('notAnAdmin');
    expect(shiftOnlyRefusal(household, 'uid-nomsa', carer)).toBe('notAnAdmin');
  });

  it('refuses somebody who is not in the household, and a household that is not there', () => {
    expect(shiftOnlyRefusal(household, 'uid-stranger', carer)).toBe('notAMember');
    expect(shiftOnlyRefusal(undefined, 'uid-sam', carer)).toBe('notAMember');
    expect(shiftOnlyRefusal({ members: 'nonsense' }, 'uid-sam', carer)).toBe('notAMember');
  });

  it('refuses a profile that is not there', () => {
    expect(shiftOnlyRefusal(household, 'uid-sam', undefined)).toBe('memberNotFound');
    expect(shiftOnlyRefusal(household, 'uid-sam', { displayName: 'No role' })).toBe(
      'memberNotFound',
    );
  });

  it('refuses anybody who is not a carer — family, a helper, a kid', () => {
    for (const role of ['admin', 'parent', 'member', 'helper', 'kid']) {
      expect(shiftOnlyRefusal(household, 'uid-sam', { role }), role).toBe('notACarer');
    }
  });
});

describe('its refusals and its input', () => {
  it('carries each reason in the details, for the client to choose words', () => {
    for (const reason of ['notAnAdmin', 'memberNotFound', 'notACarer'] as const) {
      const error = refuseNanny(reason);
      expect(error).toBeInstanceOf(HttpsError);
      expect(error.details).toEqual({ reason });
      expect(error.code).toBe(NANNY_REFUSALS[reason][0]);
    }
  });

  it('needs a real yes or no, never a truthy string', () => {
    const body = { householdId: 'h1', memberId: 'm-nomsa', shiftOnly: true };
    expect(parseInput(setCarerShiftOnlyInput, body).shiftOnly).toBe(true);
    expect(() => parseInput(setCarerShiftOnlyInput, { ...body, shiftOnly: 'yes' })).toThrow(
      HttpsError,
    );
    expect(() => parseInput(setCarerShiftOnlyInput, { ...body, memberId: '  ' })).toThrow(
      HttpsError,
    );
  });
});
