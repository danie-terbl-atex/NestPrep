import { describe, expect, it } from 'vitest';

import {
  planCatalogue,
  storedCatalogueEntry,
  type StoredCatalogueEntry,
} from '../../../src/catalogue/catalogue_plan';

/**
 * Recipes ADR-0001, lunch-box ADR-0018: a catalogue entry keeps its id, its
 * version rises only when its content changes, an entry gone from the source
 * is retired and never deleted, and publishing twice writes nothing new.
 */

const muffin = { name: 'Muffin', allergens: ['milk', 'egg'], placement: { lunchBox: 'treat' } };

function stored(
  entries: Record<string, Partial<StoredCatalogueEntry>>,
): Map<string, StoredCatalogueEntry> {
  return new Map(
    Object.entries(entries).map(([id, entry]) => [
      id,
      { status: 'published', version: 1, content: muffin, ...entry },
    ]),
  );
}

describe('publishing a catalogue', () => {
  it('publishes a new entry at version 1', () => {
    expect(planCatalogue([{ id: 'muffin', fields: muffin }], new Map())).toEqual({
      writes: [{ kind: 'publish', id: 'muffin', version: 1, fields: muffin }],
      unchanged: 0,
    });
  });

  it('writes nothing for an entry that has not changed, whatever order its keys are in', () => {
    const reordered = {
      placement: { lunchBox: 'treat' },
      allergens: ['milk', 'egg'],
      name: 'Muffin',
    };
    const plan = planCatalogue([{ id: 'muffin', fields: reordered }], stored({ muffin: {} }));
    expect(plan).toEqual({ writes: [], unchanged: 1 });
  });

  it('republishes a changed entry one version up', () => {
    const changed = { ...muffin, allergens: ['milk', 'egg', 'wheat'] };
    const plan = planCatalogue(
      [{ id: 'muffin', fields: changed }],
      stored({ muffin: { version: 3 } }),
    );
    expect(plan.writes).toEqual([{ kind: 'publish', id: 'muffin', version: 4, fields: changed }]);
  });

  it('retires an entry gone from the source, one version up, and never deletes it', () => {
    const plan = planCatalogue([], stored({ muffin: { version: 2 } }));
    expect(plan.writes).toEqual([{ kind: 'retire', id: 'muffin', version: 3 }]);
  });

  it('leaves an already retired entry alone', () => {
    const plan = planCatalogue([], stored({ muffin: { status: 'retired', version: 3 } }));
    expect(plan).toEqual({ writes: [], unchanged: 1 });
  });

  it('brings a retired entry back one version up when the source has it again', () => {
    const plan = planCatalogue(
      [{ id: 'muffin', fields: muffin }],
      stored({ muffin: { status: 'retired', version: 3 } }),
    );
    expect(plan.writes).toEqual([{ kind: 'publish', id: 'muffin', version: 4, fields: muffin }]);
  });

  it('refuses a source that uses one id twice', () => {
    const entry = { id: 'muffin', fields: muffin };
    expect(() => planCatalogue([entry, entry], new Map())).toThrow(/used twice/);
  });
});

describe('reading a stored entry', () => {
  it('keeps its content and ignores when it was written', () => {
    const entry = storedCatalogueEntry('recipes/muffin', {
      ...muffin,
      status: 'published',
      version: 2,
      updatedAt: { seconds: 1 },
    });
    expect(entry).toEqual({ status: 'published', version: 2, content: muffin });
  });

  it('refuses a document that is not a catalogue entry', () => {
    expect(() => storedCatalogueEntry('recipes/x', { name: 'No status' })).toThrow(/recipes\/x/);
    expect(() => storedCatalogueEntry('recipes/x', { status: 'draft', version: 1 })).toThrow();
    expect(() => storedCatalogueEntry('recipes/x', { status: 'published', version: 0 })).toThrow();
  });
});
