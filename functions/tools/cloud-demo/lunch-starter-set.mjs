/**
 * The lunch library a household starts with, read from its one source —
 * `app/lib/features/lunch_box/model/lunch_seed_catalogue.dart` — so the demo
 * writes the very documents the app would have seeded (`seed-{key}` ids, the
 * same names, allergens and prep notes) and never a second copy (ENG-01).
 * It fails loudly if the Dart file stops looking like it does today.
 */
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const CATALOGUE = resolve(
  import.meta.dirname,
  '../../../app/lib/features/lunch_box/model/lunch_seed_catalogue.dart',
);

/** The order the app writes allergen codes in (`LunchItem.named`). */
export const ALLERGEN_ORDER = [
  'peanut',
  'treeNut',
  'milk',
  'egg',
  'wheat',
  'soy',
  'fish',
  'shellfish',
  'sesame',
];

const EXPECTED_COUNT = 45;

function allergensIn(text, groups) {
  const found = new Set([...text.matchAll(/Allergen\.(\w+)/g)].map((match) => match[1]));
  for (const [name, members] of Object.entries(groups)) {
    if (new RegExp(`\\b${name}\\b`).test(text)) for (const code of members) found.add(code);
  }
  return ALLERGEN_ORDER.filter((code) => found.has(code));
}

/** Every starter item: `{ id, key, name, slot, allergens, prepNote }`. */
export function lunchStarterSet() {
  const source = readFileSync(CATALOGUE, 'utf8');
  const groups = Object.fromEntries(
    [...source.matchAll(/static const (_\w+) = \{([^}]*)\};/g)].map((match) => [
      match[1],
      [...match[2].matchAll(/Allergen\.(\w+)/g)].map((code) => code[1]),
    ]),
  );
  const list = source.slice(source.indexOf('seeds = ['), source.indexOf('];'));
  const calls = [...list.matchAll(/_(main|fruit|veg|snack|treat)\(/g)];
  const items = calls.map((call, index) => {
    const end = index + 1 < calls.length ? calls[index + 1].index : list.length;
    const text = list.slice(call.index, end).replace(/\/\/[^\n]*/g, '');
    const strings = [...text.matchAll(/'((?:[^'\\]|\\.)*)'/g)].map((match) =>
      match[1].replace(/\\(.)/g, '$1'),
    );
    const prep = /prep:\s*'/.test(text) ? strings[strings.length - 1] : null;
    const [key, name] = strings;
    const withoutStrings = text.replace(/'((?:[^'\\]|\\.)*)'/g, "''");
    return {
      id: `seed-${key}`,
      key,
      name,
      slot: call[1],
      allergens: allergensIn(withoutStrings, groups),
      prepNote: prep,
    };
  });
  if (items.length !== EXPECTED_COUNT || items.some((item) => !item.key || !item.name)) {
    throw new Error(
      `lunch_seed_catalogue.dart parsed to ${String(items.length)} items, expected ${String(EXPECTED_COUNT)}; update lunch-starter-set.mjs`,
    );
  }
  return items;
}
