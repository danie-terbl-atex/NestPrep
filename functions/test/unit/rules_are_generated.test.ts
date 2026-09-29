import { execFileSync } from 'node:child_process';
import { readFileSync, readdirSync } from 'node:fs';
import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

/**
 * `firestore.rules` is built from `rules/firestore/` (foundation ADR-0012), and
 * the built file is what Firebase deploys and every rules test loads. A partial
 * edited without a build would be tested and deployed as the old rules, with
 * nothing failing — so the committed file must be exactly what the partials
 * build to.
 */

const functionsDir = resolve(import.meta.dirname, '../..');
const repoRoot = resolve(functionsDir, '..');
const builder = resolve(functionsDir, 'tools/build-firestore-rules.mjs');

describe('firestore.rules is generated from its partials', () => {
  it('and the committed file is what they build to', () => {
    expect(() =>
      execFileSync(process.execPath, [builder, '--check'], { stdio: 'pipe' }),
    ).not.toThrow();
  });

  it('and every partial is in the built file, under its own name', () => {
    // Guards the check above against a builder that silently skipped a scope.
    const built = readFileSync(resolve(repoRoot, 'firestore.rules'), 'utf8');
    const scopes = ['shared', 'root', 'household'];
    const partials = scopes.flatMap((scope) =>
      readdirSync(resolve(repoRoot, 'rules/firestore', scope))
        .filter((name) => name.endsWith('.rules'))
        .map((name) => `rules/firestore/${scope}/${name}`),
    );
    expect(partials.length).toBeGreaterThanOrEqual(16);
    for (const partial of partials) {
      expect(built, `${partial} is not in firestore.rules`).toContain(`// ==== ${partial} ====`);
    }
  });

  it('and no partial is past the line cap the split exists for (ENG-05)', () => {
    for (const scope of ['shared', 'root', 'household']) {
      const dir = resolve(repoRoot, 'rules/firestore', scope);
      for (const name of readdirSync(dir).filter((file) => file.endsWith('.rules'))) {
        const lines = readFileSync(resolve(dir, name), 'utf8').split('\n').length;
        expect(
          lines,
          `rules/firestore/${scope}/${name} is ${String(lines)} lines`,
        ).toBeLessThanOrEqual(300);
      }
    }
  });
});
