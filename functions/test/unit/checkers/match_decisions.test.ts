import { describe, expect, it } from 'vitest';

import { matchRequest, rankedFrom } from '../../../src/checkers/match_decisions';
import { rankProductMatchesInput } from '../../../src/checkers/schemas';

const input = rankProductMatchesInput.parse({
  householdId: 'h1',
  item: 'Basil',
  products: [
    { productId: 'pesto', name: 'Basil Pesto 190g', brand: 'Sacla', priceCents: 6499 },
    { productId: 'basil', name: 'Fresh Basil 20g', brand: null, priceCents: 2299 },
    { productId: 'mix', name: 'Herb Mix 30g', brand: null, priceCents: 2599 },
  ],
});

describe('what Jev is asked about a grocery line', () => {
  it('is one fit question per product, carrying the line, the product and the buying rules', () => {
    const request = matchRequest(input);
    expect(Object.keys(request.questions)).toEqual(['p0', 'p1', 'p2']);
    const text = JSON.stringify(request.questions['p0']);
    expect(text).toContain('Basil Pesto 190g');
    expect(text).toContain('Sacla');
    expect(text).toContain('R64.99');
    expect(text).toContain('basil pesto is not basil');
    expect(JSON.stringify(request)).not.toContain('h1');
  });

  it('refuses more products than one panel shows, or none', () => {
    const many = Array.from({ length: 9 }, (_, n) => ({
      productId: String(n),
      name: 'x',
      brand: null,
      priceCents: 1,
    }));
    expect(rankProductMatchesInput.safeParse({ ...input, products: many }).success).toBe(false);
    expect(rankProductMatchesInput.safeParse({ ...input, products: [] }).success).toBe(false);
  });
});

describe('the ranking', () => {
  it('puts the best fit first, keeps the shop order on a tie, and reads a missing answer as no', () => {
    const ranked = rankedFrom(
      { p0: { type: 'noul', noul: 0.1 }, p1: { type: 'noul', noul: 0.92 } },
      input,
    );
    expect(ranked).toEqual([
      { productId: 'basil', fit: 0.92 },
      { productId: 'pesto', fit: 0.1 },
      { productId: 'mix', fit: 0 },
    ]);
    const tied = rankedFrom({ p0: { noul: 0.5 }, p1: { noul: 0.5 }, p2: { noul: 0.5 } }, input);
    expect(tied.map((r) => r.productId)).toEqual(['pesto', 'basil', 'mix']);
  });
});
