import { describe, expect, it } from 'vitest';

import { ROLES, adminCount, roleOf, type HouseholdDocument } from '../../src/household/documents';

function household(members: Record<string, string>): HouseholdDocument {
  return { name: 'The Parkers', timeZone: 'Africa/Johannesburg', members } as HouseholdDocument;
}

describe('the membership map', () => {
  it('answers what role an account holds, and nothing for one that holds none', () => {
    const parkers = household({ 'uid-sam': 'admin', 'uid-thandi': 'helper' });
    expect(roleOf(parkers, 'uid-sam')).toBe('admin');
    expect(roleOf(parkers, 'uid-thandi')).toBe('helper');
    expect(roleOf(parkers, 'uid-stranger')).toBeUndefined();
  });

  it('counts the admins, which is what the last-admin refusal turns on', () => {
    expect(adminCount(household({ 'uid-sam': 'admin' }))).toBe(1);
    expect(adminCount(household({ 'uid-sam': 'admin', 'uid-alex': 'admin' }))).toBe(2);
    expect(adminCount(household({ 'uid-thandi': 'helper' }))).toBe(0);
    expect(adminCount(household({}))).toBe(0);
  });
});

describe('the roles', () => {
  it('are the three the household ADR names, in the order it names them', () => {
    expect(ROLES).toEqual(['admin', 'member', 'helper']);
  });
});
