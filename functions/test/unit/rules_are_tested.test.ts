import { readFileSync, readdirSync } from 'node:fs';
import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

/**
 * The standard says every rule has a denied-case test. Nothing checked it.
 *
 * A collection added to `firestore.rules` without tests does not fail
 * anything — the suite still passes, the count still goes up, and the gap is
 * invisible until somebody reads somebody else's household. This is the guard:
 * it fails when a collection appears in the rules that no rules test touches,
 * and when a rules test file has forgotten how to say no.
 *
 * It is a coarse check on purpose. It cannot tell whether *each operation* has
 * a denied case — only the emulator's own coverage report can, and reading that
 * reliably turned out to be harder than it is worth. What it can do is make the
 * cheapest mistake, adding a collection and no test, impossible to miss.
 */

const repoRoot = resolve(import.meta.dirname, '../../..');
const rulesSource = readFileSync(resolve(repoRoot, 'firestore.rules'), 'utf8');
const rulesTestDir = resolve(import.meta.dirname, '../rules');

/** Every `match /<collection>/{…}` block the rules declare. */
function collectionsInTheRules(): string[] {
  return [
    ...new Set(
      [...rulesSource.matchAll(/match \/(\w+)\/\{/g)]
        .flatMap((match) => (match[1] === undefined ? [] : [match[1]]))
        .filter((name) => name !== 'databases'),
    ),
  ];
}

const rulesTests = readdirSync(rulesTestDir)
  .filter((name) => name.endsWith('.test.ts'))
  .map((name) => ({ name, source: readFileSync(resolve(rulesTestDir, name), 'utf8') }));

describe('the rules and their tests have not drifted apart', () => {
  it('finds the collections and the tests it is checking', () => {
    // Without this, a change to either shape would leave the checks below
    // passing vacuously.
    expect(collectionsInTheRules()).toEqual(
      expect.arrayContaining(['users', 'households', 'members', 'groceryItems']),
    );
    expect(rulesTests.length).toBeGreaterThanOrEqual(6);
  });

  for (const collection of collectionsInTheRules()) {
    it(`${collection} is exercised by at least one rules test`, () => {
      const touched = rulesTests.filter(
        ({ source }) => source.includes(`${collection}/`) || source.includes(`'${collection}'`),
      );
      expect(
        touched.map(({ name }) => name),
        `no rules test mentions ${collection}; a collection with rules and no test is a door nobody has tried`,
      ).not.toHaveLength(0);
    });
  }
});

describe('every rules test file still knows how to say no', () => {
  for (const { name, source } of rulesTests) {
    // The liveness and offline suites are about propagation, not permission;
    // they prove a write arrives, and one of them proves a denial survives a
    // reconnect. The per-collection rules suites are the ones that must refuse.
    if (!name.endsWith('.rules.test.ts')) continue;

    it(name, () => {
      expect(source).toContain('assertSucceeds');
      expect(
        source.includes('assertFails'),
        `${name} only ever checks what is allowed — a rules test that never ` +
          `denies anything would pass against no rules at all`,
      ).toBe(true);
    });
  }
});
