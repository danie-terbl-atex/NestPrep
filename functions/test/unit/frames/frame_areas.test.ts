import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

import { FRAME_AREAS, FRAME_AREA_CODES } from '../../../src/frames/frame_areas';
import { FRAME_GROCERY_SHOPS, WOOLWORTHS_PRICE_ZONES } from '../../../src/frames/frame_policy';

/** A frame searches near the same city centres the app offers (photo-frames ADR-0012). */

const root = resolve(import.meta.dirname, '../../../..');
const dart = readFileSync(
  resolve(root, 'app/lib/features/add_to_checkers/model/checkers_area.dart'),
  'utf8',
);
const rules = readFileSync(resolve(root, 'rules/firestore/household/photo_frames.rules'), 'utf8');
const woolworthsParser = readFileSync(
  resolve(root, 'app/lib/features/add_to_woolworths/data/woolworths_catalogue_parser.dart'),
  'utf8',
);

function appAreas(): Record<string, unknown> {
  const pattern =
    /\w+\(\s*'(\w+)',\s*'([^']+)',\s*Coordinates\(latitude: (-?[\d.]+), longitude: (-?[\d.]+)\),\s*'(\d+)',?\s*\)/g;
  return Object.fromEntries(
    [...dart.matchAll(pattern)].map((match) => [
      String(match[1]),
      {
        label: match[2],
        latitude: Number(match[3]),
        longitude: Number(match[4]),
        postalCode: match[5],
      },
    ]),
  );
}

function rulesList(name: string, of = 'photoFrameIsGroceries'): string[] {
  const block = new RegExp(`function ${of}[\\s\\S]*?\\n}`).exec(rules)?.[0] ?? '';
  const list = new RegExp(`groceries\\.${name} in \\[([^\\]]*)\\]`).exec(block)?.[1] ?? '';
  return [...list.matchAll(/'(\w+)'/g)].map((match) => String(match[1]));
}

describe('frame areas', () => {
  it('are the app’s CheckersArea, every one and no other', () => {
    const app = appAreas();
    expect(Object.keys(app)).toHaveLength(7);
    expect(FRAME_AREAS).toEqual(app);
  });

  it('and the rules accept exactly these areas and shops', () => {
    expect(rulesList('area')).toEqual(FRAME_AREA_CODES);
    expect(rulesList('shop')).toEqual([...FRAME_GROCERY_SHOPS]);
  });

  it('and Woolworths’ price lists are the ones the app’s store lookup gives', () => {
    const app = [...woolworthsParser.matchAll(/'plist[0-9]+': '(p[0-9]+)'/g)].map((match) =>
      String(match[1]),
    );
    expect(app).toEqual([...WOOLWORTHS_PRICE_ZONES]);
    expect(rulesList('priceZone', 'photoFrameIsWoolworthsStore')).toEqual([
      ...WOOLWORTHS_PRICE_ZONES,
    ]);
  });
});
