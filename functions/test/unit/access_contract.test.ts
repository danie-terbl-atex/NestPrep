import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

import { AREAS, FAMILY_ROLES, LEVELS } from '../../src/household/access';

/**
 * The area keys are written in three languages — TypeScript here, the rules
 * language in two files, and Dart in the app (whose own test reads this
 * file). A key spelled differently in one of them is not an error anywhere:
 * the rule simply never matches, and a helper silently loses, or keeps, an
 * area (household ADR-0003). This reads both rules files and holds them to
 * `access.ts`.
 */
const repoRoot = resolve(import.meta.dirname, '../../..');
const firestoreRules = readFileSync(resolve(repoRoot, 'firestore.rules'), 'utf8');
const storageRules = readFileSync(resolve(repoRoot, 'storage.rules'), 'utf8');

function listAfter(source: string, marker: RegExp): string[] {
  const match = marker.exec(source);
  if (match?.[1] === undefined) return [];
  return [...match[1].matchAll(/'(\w+)'/g)].flatMap((item) =>
    item[1] === undefined ? [] : [item[1]],
  );
}

function areasGatedIn(source: string): string[] {
  return [
    ...new Set(
      [...source.matchAll(/(?:canView|canEdit|hasOwnOnly)\(householdId, '(\w+)'\)/g)].flatMap(
        (match) => (match[1] === undefined ? [] : [match[1]]),
      ),
    ),
  ];
}

describe('firestore.rules and access.ts name the same things', () => {
  it('a grant may hold exactly the areas access.ts names', () => {
    const keys = listAfter(firestoreRules, /value\.keys\(\)\.hasOnly\(\s*\[([^\]]+)\]/);
    expect(keys).toEqual([...AREAS]);
  });

  it('a grant may hold exactly the four levels', () => {
    const levels = listAfter(firestoreRules, /value\.values\(\)\.hasOnly\(\[([^\]]+)\]/);
    expect(levels).toEqual([...LEVELS]);
  });

  it('family is the same three roles', () => {
    const family = listAfter(firestoreRules, /members\[uid\(\)\] in \[([^\]]+)\]/);
    expect(family).toEqual([...FAMILY_ROLES]);
  });

  it('every area a rule gates on is one access.ts knows', () => {
    const gated = areasGatedIn(firestoreRules);
    expect(gated.length).toBeGreaterThanOrEqual(5);
    for (const area of gated) expect(AREAS).toContain(area);
  });
});

describe('storage.rules and access.ts name the same things', () => {
  it('family is the same three roles', () => {
    const family = listAfter(storageRules, /households\(\)\[householdId\] in \[([^\]]+)\]/);
    expect(family).toEqual([...FAMILY_ROLES]);
  });

  it('every area a rule gates on is one access.ts knows', () => {
    const gated = areasGatedIn(storageRules);
    expect(gated).toContain('documents');
    for (const area of gated) expect(AREAS).toContain(area);
  });
});
