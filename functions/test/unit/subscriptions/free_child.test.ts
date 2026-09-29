import { describe, expect, it } from 'vitest';

import { freeChildAfter } from '../../../src/family_profiles/set_child_profile';

/** Which child the free tier plans for after one marking (lunch-box ADR-0009). */
describe('freeChildAfter', () => {
  const base = { currentIsAChild: false, otherChildren: [] as string[] };

  it('makes the first child marked the free one', () => {
    expect(freeChildAfter({ ...base, current: null, memberId: 'a', isChild: true })).toBe('a');
  });

  it('keeps a free child who is still a child, whoever else is marked', () => {
    expect(
      freeChildAfter({
        current: 'a',
        currentIsAChild: true,
        memberId: 'b',
        isChild: true,
        otherChildren: ['a'],
      }),
    ).toBe('a');
  });

  it('keeps the free child marked again', () => {
    expect(freeChildAfter({ ...base, current: 'a', memberId: 'a', isChild: true })).toBe('a');
  });

  it('hands the place on when the free child is unmarked', () => {
    expect(
      freeChildAfter({
        ...base,
        current: 'a',
        memberId: 'a',
        isChild: false,
        otherChildren: ['b'],
      }),
    ).toBe('b');
    expect(freeChildAfter({ ...base, current: 'a', memberId: 'a', isChild: false })).toBeNull();
  });

  it('gives a household with children but no record one of them (made before the record)', () => {
    expect(
      freeChildAfter({
        ...base,
        current: null,
        memberId: 'c',
        isChild: true,
        otherChildren: ['b'],
      }),
    ).toBe('b');
  });

  it('replaces a record naming somebody who is no longer a child', () => {
    expect(
      freeChildAfter({
        current: 'gone',
        currentIsAChild: false,
        memberId: 'b',
        isChild: true,
        otherChildren: [],
      }),
    ).toBe('b');
  });
});
