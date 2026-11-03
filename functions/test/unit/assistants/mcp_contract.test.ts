import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import { describe, expect, it } from 'vitest';

import {
  EVENT_EDITABLE_KEYS,
  EVENT_KEYS,
  EXCEPTION_KEYS,
  storedRuleOf,
} from '../../../src/assistants/mcp/event_documents';
import { GROCERY_ITEM_KEYS } from '../../../src/assistants/mcp/grocery_documents';
import { normalisedName } from '../../../src/home_care/restock_decision';
import { RECURRENCE_KEYS } from '../../recurrence_shape';

/**
 * What an assistant writes is read by Dart and judged by the rules
 * (assistants ADR-0005), so the field names are a contract between three
 * languages — and a contract between languages needs a test that reads each
 * of them. This reads the generated Dart converters and the rules partials,
 * and fails the day any of them disagrees with the keys the tools write, or
 * the Dart normalised-name rule stops being the one dedupe uses.
 */

const REPO = join(__dirname, '..', '..', '..', '..');

function read(path: string): string {
  return readFileSync(join(REPO, path), 'utf8');
}

/** The keys a generated `_$<Type>ToJson` writes. */
function dartStoredKeys(path: string, type: string): string[] {
  const source = read(path);
  const body = new RegExp(`_\\$${type}ToJson\\([^)]*\\)\\s*=>([\\s\\S]*?)\\n\\s*};`).exec(source);
  if (body?.[1] === undefined) throw new Error(`could not find _$${type}ToJson in ${path}`);
  return [...body[1].matchAll(/'([^']+)':/g)].flatMap((match) =>
    match[1] === undefined ? [] : [match[1]],
  );
}

/** The list a rules partial hands `hasOnly(…)` or `onlyChanged(…)` after [anchor]. */
function rulesList(path: string, anchor: string, call: 'hasOnly' | 'onlyChanged'): string[] {
  const source = read(path);
  const from = source.indexOf(anchor);
  if (from < 0) throw new Error(`no ${anchor} in ${path}`);
  const list = new RegExp(`${call}\\(\\s*\\[([^\\]]*)\\]`).exec(source.slice(from));
  if (list?.[1] === undefined) throw new Error(`no ${call} after ${anchor} in ${path}`);
  return [...list[1].matchAll(/'([^']+)'/g)].flatMap((match) =>
    match[1] === undefined ? [] : [match[1]],
  );
}

const PROVENANCE = ['createdVia', 'addedVia'];
const withoutProvenance = (keys: string[]): string[] =>
  keys.filter((key) => !PROVENANCE.includes(key)).sort();

const EVENT_DART = 'app/lib/features/calendar/model/household_event.g.dart';
const EXCEPTION_DART = 'app/lib/features/calendar/model/event_exception.g.dart';
const GROCERY_DART = 'app/lib/features/groceries/model/grocery_item.g.dart';
const CALENDAR_RULES = 'rules/firestore/household/calendar.rules';
const GROCERY_RULES = 'rules/firestore/household/groceries.rules';

describe('the event an assistant writes is the one Dart stores and the rules accept', () => {
  it('can read the generated Dart converter', () => {
    expect(dartStoredKeys(EVENT_DART, 'HouseholdEvent')).toContain('createdBy');
  });

  it('every key HouseholdEvent.toJson writes, and no other, beside createdVia', () => {
    expect(withoutProvenance(dartStoredKeys(EVENT_DART, 'HouseholdEvent'))).toEqual(
      [...EVENT_KEYS].sort(),
    );
  });

  it("the rules' create list is the same keys, so the app may write what the assistant did", () => {
    expect(rulesList(CALENDAR_RULES, 'match /events/', 'hasOnly').sort()).toEqual(
      [...EVENT_KEYS].sort(),
    );
  });

  it("the keys an update may move are the rules' onlyChanged list exactly", () => {
    expect(rulesList(CALENDAR_RULES, 'allow update', 'onlyChanged').sort()).toEqual(
      [...EVENT_EDITABLE_KEYS].sort(),
    );
  });

  it('createdVia is in neither rules list: a client can neither set nor change it', () => {
    expect(rulesList(CALENDAR_RULES, 'match /events/', 'hasOnly')).not.toContain('createdVia');
    expect(rulesList(CALENDAR_RULES, 'allow update', 'onlyChanged')).not.toContain('createdVia');
  });

  it('a skipped occurrence has the keys EventException.toJson writes and the rules allow', () => {
    expect(dartStoredKeys(EXCEPTION_DART, 'EventException').sort()).toEqual(
      [...EXCEPTION_KEYS].sort(),
    );
    expect(rulesList(CALENDAR_RULES, 'match /eventExceptions/', 'hasOnly').sort()).toEqual(
      [...EXCEPTION_KEYS].sort(),
    );
  });

  it('a repeat is stored in the four keys the Dart rule writes, weekdays sorted', () => {
    const stored = storedRuleOf({
      frequency: 'weekly',
      interval: 1,
      weekdays: [6, 2],
      until: null,
    });
    expect(Object.keys(stored ?? {}).sort()).toEqual([...RECURRENCE_KEYS].sort());
    expect(stored?.weekdays).toEqual([2, 6]);
  });
});

describe('the grocery item an assistant writes is the one Dart stores and the rules accept', () => {
  it('every key GroceryItem.toJson writes for a typed item, beside addedVia', () => {
    const dart = dartStoredKeys(GROCERY_DART, 'GroceryItem').filter(
      (key) => key !== 'productMatch',
    );
    expect(withoutProvenance(dart)).toEqual([...GROCERY_ITEM_KEYS].sort());
  });

  it('productMatch is the one key Dart leaves out when absent, which is how the tool writes it', () => {
    expect(read(GROCERY_DART)).toMatch(/'productMatch': \?/);
    expect(GROCERY_ITEM_KEYS).not.toContain('productMatch');
  });

  it("the rules' create list holds every key written, and not addedVia", () => {
    const allowed = rulesList(GROCERY_RULES, 'match /groceryItems/', 'hasOnly');
    for (const key of GROCERY_ITEM_KEYS) expect(allowed).toContain(key);
    expect(allowed).not.toContain('addedVia');
  });
});

describe("dedupe's name is the app's normalisedName", () => {
  const DART = 'app/lib/shared/text/normalised_name.dart';

  it('the Dart rule is still trim, lower case, and runs of whitespace as one space', () => {
    const source = read(DART);
    const body = /String normalisedName\(String name\) =>\s*([^;]+);/.exec(source)?.[1];
    expect(body?.replace(/\s+/g, '')).toBe(
      "name.trim().toLowerCase().replaceAll(RegExp(r'\\s+'),'')",
    );
  });

  it('and the TypeScript one gives the answers the Dart one gives', () => {
    const cases: [string, string][] = [
      ['Milk', 'milk'],
      ['  milk ', 'milk'],
      ['MILK', 'milk'],
      ['Taco   shells', 'taco shells'],
      ['Taco\tshells\n', 'taco shells'],
      ['Crème fraîche', 'crème fraîche'],
      ['ÉCLAIRS', 'éclairs'],
      [' Milk ', 'milk'],
    ];
    for (const [typed, key] of cases) expect(normalisedName(typed)).toBe(key);
  });
});
