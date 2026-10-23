import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

import { ALLERGENS } from '../../../src/plan_week/food_safety';
import { SEED_FOODS } from '../../../src/lunch_photos/seed_foods';

/**
 * `SEED_FOODS` is a copy of the app's `LunchSeedCatalogue`. A seed renamed,
 * added or moved there and not here would picture the wrong food for every
 * household sharing that box — or stop sharing it at all — and nothing would
 * fail. A starter box's quick pick copies its allergen codes from here
 * (lunch-box ADR-0018), so a code the app adds and this misses would offer a
 * child a box the rules then refuse. So the Dart file is the source, and this
 * reads it.
 */

const catalogue = readFileSync(
  resolve(
    import.meta.dirname,
    '../../../../app/lib/features/lunch_box/model/lunch_seed_catalogue.dart',
  ),
  'utf8',
);

const declared = [
  ...catalogue.matchAll(/_(main|fruit|veg|snack|treat)\(\s*'([^']+)',\s*'([^']+)'/g),
].map(([, slot, key, name]) => `${String(key)} → ${String(name)} in ${String(slot)}`);

/** `static const _bread = {Allergen.wheat, Allergen.soy};` and its kind, by name. */
const groups = new Map(
  [...catalogue.matchAll(/static const (_\w+) = \{([^}]*)\};/g)].map(([, name, body]) => [
    String(name),
    [...String(body).matchAll(/Allergen\.(\w+)/g)].map(([, code]) => String(code)),
  ]),
);

/** Each seed's codes: its own `Allergen.x` and the groups it spreads, in `ALLERGENS` order. */
function declaredAllergens(): Map<string, string[]> {
  const list = catalogue.slice(catalogue.indexOf('seeds = ['), catalogue.indexOf('];'));
  const calls = [...list.matchAll(/_(?:main|fruit|veg|snack|treat)\(\s*'([^']+)'/g)];
  return new Map(
    calls.map((call, index) => {
      const end = calls[index + 1]?.index ?? list.length;
      const text = list.slice(call.index, end).replace(/'(?:[^'\\]|\\.)*'/g, "''");
      const found = new Set([...text.matchAll(/Allergen\.(\w+)/g)].map(([, code]) => code));
      for (const [name, codes] of groups) {
        if (new RegExp(`\\b${name}\\b`).test(text)) for (const code of codes) found.add(code);
      }
      return [String(call[1]), ALLERGENS.filter((code) => found.has(code))];
    }),
  );
}

describe('the seed foods the server pictures', () => {
  it('finds the catalogue it is checking', () => {
    expect(declared.length).toBeGreaterThanOrEqual(40);
    expect(groups.get('_bread')).toEqual(['wheat', 'soy']);
  });

  it('are exactly the app’s seeds: every key, name and compartment', () => {
    const mirrored = Object.entries(SEED_FOODS).map(
      ([key, { name, slot }]) => `${key} → ${name} in ${slot}`,
    );
    expect(mirrored.sort()).toEqual(declared.sort());
  });

  it('carry exactly the allergen codes the app seeds each item with', () => {
    const mirrored = new Map(
      Object.entries(SEED_FOODS).map(([key, { allergens }]) => [key, [...allergens]]),
    );
    expect(mirrored).toEqual(declaredAllergens());
    expect(mirrored.get('trail-mix')).toEqual(['peanut', 'treeNut']);
  });
});
