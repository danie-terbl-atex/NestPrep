import { execFileSync } from 'node:child_process';
import { readFileSync, readdirSync } from 'node:fs';
import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

/**
 * `firestore.rules` is built from `rules/firestore/` (foundation ADR-0012) and
 * `storage.rules` from `rules/storage/` (foundation ADR-0013), and the built
 * files are what Firebase deploys and every rules test loads. A partial edited
 * without a build would be tested and deployed as the old rules, with nothing
 * failing — so each committed file must be exactly what its partials build to.
 */

const functionsDir = resolve(import.meta.dirname, '../..');
const repoRoot = resolve(functionsDir, '..');
const builder = resolve(functionsDir, 'tools/build-rules.mjs');

const GENERATED = [
  {
    file: 'firestore.rules',
    tree: 'firestore',
    scopes: ['shared', 'root', 'household'],
    atLeast: 16,
  },
  { file: 'storage.rules', tree: 'storage', scopes: ['shared', 'paths'], atLeast: 6 },
] as const;

function partialsOf(tree: string, scopes: readonly string[]): string[] {
  return scopes.flatMap((scope) =>
    readdirSync(resolve(repoRoot, 'rules', tree, scope))
      .filter((name) => name.endsWith('.rules'))
      .map((name) => `rules/${tree}/${scope}/${name}`),
  );
}

describe('the rules files are generated from their partials', () => {
  it('and each committed file is what they build to', () => {
    expect(() =>
      execFileSync(process.execPath, [builder, '--check'], { stdio: 'pipe' }),
    ).not.toThrow();
  });

  for (const { file, tree, scopes, atLeast } of GENERATED) {
    it(`and every partial is in ${file}, under its own name`, () => {
      // Guards the check above against a builder that silently skipped a scope.
      const built = readFileSync(resolve(repoRoot, file), 'utf8');
      const partials = partialsOf(tree, scopes);
      expect(partials.length).toBeGreaterThanOrEqual(atLeast);
      for (const partial of partials) {
        expect(built, `${partial} is not in ${file}`).toContain(`// ==== ${partial} ====`);
      }
    });

    it(`and no ${tree} partial is past the line cap the split exists for (ENG-05)`, () => {
      for (const partial of partialsOf(tree, scopes)) {
        const lines = readFileSync(resolve(repoRoot, partial), 'utf8').split('\n').length;
        expect(lines, `${partial} is ${String(lines)} lines`).toBeLessThanOrEqual(300);
      }
    });
  }
});
