import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

import { SEED_FOODS } from '../../../src/lunch_photos/seed_foods';

/**
 * `SEED_FOODS` is a copy of the app's `LunchSeedCatalogue`. A seed renamed,
 * added or moved there and not here would picture the wrong food for every
 * household sharing that box — or stop sharing it at all — and nothing would
 * fail. So the Dart file is the source, and this reads it.
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

describe('the seed foods the server pictures', () => {
  it('finds the catalogue it is checking', () => {
    expect(declared.length).toBeGreaterThanOrEqual(40);
  });

  it('are exactly the app’s seeds: every key, name and compartment', () => {
    const mirrored = Object.entries(SEED_FOODS).map(
      ([key, { name, slot }]) => `${key} → ${name} in ${slot}`,
    );
    expect(mirrored.sort()).toEqual(declared.sort());
  });
});
