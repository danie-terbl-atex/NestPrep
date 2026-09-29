import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import { describe, expect, it } from 'vitest';

import { READER_CLAIM, WEEKLY_TOTALS } from '../../src/product_analytics/analytics_documents';
import { summariseWeek } from '../../src/product_analytics/weekly_summary';

/**
 * The beta numbers cross the client/server line three times, and each is a
 * string written down in two languages (the vault lesson on contracts between
 * two languages): the callable's name and body, the totals document's fields,
 * and the reader claim. Nothing fails at build time on either side when one
 * drifts — the screen just shows zeros, or the link never appears.
 */
const REPO = join(import.meta.dirname, '..', '..', '..');
const FEATURE = join(REPO, 'app', 'lib', 'features', 'product_analytics');

function dart(path: string): string {
  return readFileSync(join(FEATURE, path), 'utf8');
}

describe('the client and the server agree on', () => {
  it('the name of the callable and the one field it sends', () => {
    const recorder = dart('data/callable_activity_recorder.dart');
    expect(recorder).toContain("callableName = 'recordActivity'");
    expect(recorder).toContain("'householdId': householdId");
    const index = readFileSync(join(REPO, 'functions', 'src', 'index.ts'), 'utf8');
    expect(index).toContain('export { recordActivity }');
  });

  it('where the weekly totals live', () => {
    expect(dart('data/firestore_beta_numbers_repository.dart')).toContain(
      `weeksPath = '${WEEKLY_TOTALS}'`,
    );
  });

  it('every totals field the app reads, which the rollup writes', () => {
    const model = dart('model/weekly_numbers.dart');
    const declared = [
      ...model.matchAll(
        /^\s*(?:@\w+\(\)\s*)?(?:@Default\([^)]*\)\s*)?(?:required\s+)?[\w<>?]+\??\s+(\w+),$/gm,
      ),
    ].flatMap((match) => (match[1] === undefined ? [] : [match[1]]));
    const written = Object.keys(
      summariseWeek({
        week: '2026-W40',
        householdWeeks: [],
        cohort: [],
        conversions: [],
        isInviteCohortComplete: false,
      }),
    );

    // Guards the check below against a regex that matches nothing.
    expect(declared).toEqual(expect.arrayContaining(['week', 'activeFamilies']));
    for (const field of declared) {
      if (field === 'computedAt') continue; // the rollup adds the server's time as it writes
      expect(written, `the app reads ${field}, which the rollup never writes`).toContain(field);
    }
  });

  it('the name of the reader claim, in the app, the rules and the grant tool', () => {
    expect(dart('data/beta_numbers_repository.dart')).toContain(`readerClaim = '${READER_CLAIM}'`);
    expect(readFileSync(join(REPO, 'firestore.rules'), 'utf8')).toContain(
      `request.auth.token.get('${READER_CLAIM}', false) == true`,
    );
    expect(
      readFileSync(join(REPO, 'functions', 'tools', 'grant-analytics-reader.mjs'), 'utf8'),
    ).toContain('READER_CLAIM');
  });
});
