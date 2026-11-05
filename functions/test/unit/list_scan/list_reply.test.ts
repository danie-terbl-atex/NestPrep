import { describe, expect, it } from 'vitest';

import {
  MAX_LINES,
  MAX_NAME_LENGTH,
  linesFrom,
  listReply,
} from '../../../src/list_scan/list_reply';

describe('the lines a shopping list photo proposes', () => {
  it('keeps each item in the list’s order, with its quantity or none', () => {
    expect(
      linesFrom({
        items: [
          { name: 'Milk', quantity: '2 l' },
          { name: 'Bread', quantity: null },
          { name: 'Eggs' },
        ],
      }),
    ).toEqual([
      { name: 'Milk', quantity: '2 l' },
      { name: 'Bread', quantity: null },
      { name: 'Eggs', quantity: null },
    ]);
  });

  it('tidies whitespace, and drops a name that is only whitespace', () => {
    expect(
      linesFrom({
        items: [
          { name: '  Peanut \n butter ', quantity: '  1  jar ' },
          { name: '   ', quantity: '3' },
          { name: 'Rice', quantity: '   ' },
        ],
      }),
    ).toEqual([
      { name: 'Peanut butter', quantity: '1 jar' },
      { name: 'Rice', quantity: null },
    ]);
  });

  it('keeps a name once, however the list wrote it again', () => {
    expect(linesFrom({ items: [{ name: 'Milk' }, { name: 'milk ', quantity: '1 l' }] })).toEqual([
      { name: 'Milk', quantity: null },
    ]);
  });

  it('bounds the length of a name and the number of lines', () => {
    const long = 'A'.repeat(MAX_NAME_LENGTH + 50);
    expect(linesFrom({ items: [{ name: long }] })[0]?.name).toHaveLength(MAX_NAME_LENGTH);
    const many = Array.from({ length: MAX_LINES + 20 }, (_, index) => ({
      name: `Item ${String(index)}`,
    }));
    expect(linesFrom({ items: many })).toHaveLength(MAX_LINES);
  });

  it('parses a reply missing a quantity, and refuses one missing its items', () => {
    expect(listReply.safeParse({ items: [{ name: 'Tea' }] }).success).toBe(true);
    expect(listReply.safeParse({ lines: [] }).success).toBe(false);
    expect(listReply.safeParse({ items: [{ quantity: '2' }] }).success).toBe(false);
  });
});
