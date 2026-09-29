import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';

import { FUNCTIONS_REGION } from '../../src/shared/region';

/**
 * The region is a contract between two languages, so it needs a test that reads
 * both — the vault's lesson, and this is exactly the shape it warns about.
 *
 * A callable is addressed by region. `FirebaseFunctions.instance` in Dart
 * defaults to `us-central1`, which after this project's move to `africa-south1`
 * resolves to a URL where nothing is deployed. Nothing fails at build time on
 * either side; every household action fails at runtime with NOT_FOUND and reads
 * as a broken backend rather than a wrong string.
 *
 * The emulator hides this completely — it serves whatever region is asked for —
 * so no emulator test can stand in for this one.
 */
const REPO = join(import.meta.dirname, '..', '..', '..');
const BOOTSTRAP = join(REPO, 'app', 'lib', 'app', 'firebase_bootstrap.dart');

function dartSource(): string {
  return readFileSync(BOOTSTRAP, 'utf8');
}

/**
 * The same file with its comments removed. The doc comment on `functionsRegion`
 * names `FirebaseFunctions.instance` as the trap to avoid, so a check over the
 * raw text would fail on the prose that explains the rule rather than on a
 * breach of it.
 */
function dartCode(): string {
  return dartSource()
    .split('\n')
    .filter((line) => !line.trimStart().startsWith('//'))
    .join('\n');
}

describe('the region the client calls and the region we deploy to', () => {
  it('is the same string on both sides', () => {
    const declared = /const functionsRegion = '([^']+)'/.exec(dartSource());
    expect(declared, 'app/lib/app/firebase_bootstrap.dart declares functionsRegion').not.toBeNull();
    expect(declared?.[1]).toBe(FUNCTIONS_REGION);
  });

  it('is actually used by the client, not merely declared', () => {
    // A constant nothing reads is the same bug with a comment on it.
    expect(dartCode()).toContain('FirebaseFunctions.instanceFor(region: functionsRegion)');
    expect(
      dartCode(),
      'FirebaseFunctions.instance defaults to us-central1 and would silently bypass the constant',
    ).not.toMatch(/FirebaseFunctions\.instance\b(?!For)/);
  });

  it('matches the Firestore database, which is the reason it was chosen', () => {
    // If the database ever moves, this test is the thing that asks whether the
    // functions should follow it.
    expect(FUNCTIONS_REGION).toBe('africa-south1');
  });
});
