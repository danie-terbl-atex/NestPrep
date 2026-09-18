import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

import { describe, expect, it } from 'vitest';

import { RECURRENCE_FREQUENCIES, RECURRENCE_KEYS, everyDay, weeklyOn } from '../recurrence_shape';

/**
 * The recurrence map is written by Dart and read by nothing but Dart — but the
 * rules tests write it too, standing in for a client, and the rules only check
 * that `recurrence` is an allowed key. Nothing inside it is constrained by
 * anybody, so a TypeScript fixture with the wrong field names is accepted by the
 * emulator and passes for ever.
 *
 * One did. It wrote `kind` where the client writes `frequency` and left `until`
 * out entirely, so the only recurrence shape in the whole TypeScript suite was a
 * shape no client could produce.
 *
 * This reads the generated Dart converter — the thing that actually decides the
 * stored shape — and fails when the fixture drifts from it. Same technique as
 * the refusal-code contract, in the other direction.
 */

const CONVERTER = join(
  __dirname,
  '..',
  '..',
  '..',
  'app',
  'lib',
  'shared',
  'recurrence',
  'recurrence_rule.g.dart',
);

function dartSource(): string {
  return readFileSync(CONVERTER, 'utf8');
}

/** The keys `_$RecurrenceRuleToJson` writes, in the order it writes them. */
function dartStoredKeys(source: string): string[] {
  const body = /_\$RecurrenceRuleToJson\([^)]*\) =>([\s\S]*?)\n};/.exec(source);
  if (body === null) throw new Error('could not find _$RecurrenceRuleToJson');
  return [...body[1].matchAll(/'([^']+)':/g)].map((match) => match[1]);
}

/** Every value the frequency enum serialises to. */
function dartFrequencies(source: string): string[] {
  const map = /_\$RecurrenceFrequencyEnumMap = \{([\s\S]*?)\n\};/.exec(source);
  if (map === null) throw new Error('could not find _$RecurrenceFrequencyEnumMap');
  return [...map[1].matchAll(/:\s*'([^']+)'/g)].map((match) => match[1]);
}

describe('the recurrence map TypeScript writes is the one Dart stores', () => {
  it('can read the generated Dart converter', () => {
    // If this fails the path is wrong, and every assertion below would be
    // vacuously true against an empty string.
    expect(dartSource()).toContain('_$RecurrenceRuleToJson');
  });

  it('stores exactly the keys the fixture declares', () => {
    expect(dartStoredKeys(dartSource()).sort()).toEqual([...RECURRENCE_KEYS].sort());
  });

  it('allows exactly the frequencies the fixture declares', () => {
    expect(dartFrequencies(dartSource()).sort()).toEqual([...RECURRENCE_FREQUENCIES].sort());
  });

  it('every builder produces all four keys, because a Dart default is still written', () => {
    for (const built of [weeklyOn([6]), weeklyOn([2, 4], '2027-03-31'), everyDay(2)]) {
      expect(Object.keys(built).sort()).toEqual([...RECURRENCE_KEYS].sort());
    }
  });

  it('a weekday is an ISO weekday, Monday 1 to Sunday 7', () => {
    for (const weekday of weeklyOn([1, 7]).weekdays) {
      expect(weekday).toBeGreaterThanOrEqual(1);
      expect(weekday).toBeLessThanOrEqual(7);
    }
  });

  it('no rules test invents its own recurrence shape any more', () => {
    // The fixture exists so there is exactly one shape. A literal
    // `recurrence: {` in a test is how the wrong one got in — and the directory
    // is walked rather than listed, so a new rules test is covered the day it
    // is written.
    const rulesDir = join(__dirname, '..', 'rules');
    const offenders = readdirSync(rulesDir)
      .filter((name) => name.endsWith('.ts'))
      .filter((name) => /recurrence:\s*\{/.test(readFileSync(join(rulesDir, name), 'utf8')));

    expect(offenders, 'import weeklyOn/everyDay from test/recurrence_shape.ts instead').toEqual([]);
  });

  it('and the fixture is actually the one they use', () => {
    // Otherwise the check above passes by nobody writing a recurrence at all.
    const rulesDir = join(__dirname, '..', 'rules');
    const users = readdirSync(rulesDir)
      .filter((name) => name.endsWith('.ts'))
      .filter((name) => /recurrence_shape/.test(readFileSync(join(rulesDir, name), 'utf8')));

    expect(users.length).toBeGreaterThanOrEqual(3);
  });
});
