import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

import { MEMBER_COLOR_HEX, memberColorHex } from '../../../src/frames/member_colors';

/** A frame draws each person in the colour the app shows them in (photo-frames ADR-0003). */

const palette = readFileSync(
  resolve(import.meta.dirname, '../../../../app/lib/design/tokens/nest_member_palette.dart'),
  'utf8',
);

function lightFills(): Map<string, string> {
  const start = palette.indexOf('static const light = NestMemberPalette._({');
  const block = palette.slice(start, palette.indexOf('});', start));
  return new Map(
    [
      ...block.matchAll(
        /MemberColor\.(\w+): MemberSwatch\(\s*fill: Color\(0xFF([0-9A-Fa-f]{6})\)/g,
      ),
    ].map((match) => [String(match[1]), `#${String(match[2]).toUpperCase()}`] as const),
  );
}

describe('member colours', () => {
  it('are the app’s light fills, every palette entry and no other', () => {
    const fills = lightFills();
    expect(fills.size).toBe(10);
    expect(new Map(MEMBER_COLOR_HEX)).toEqual(fills);
  });

  it('a name outside the palette, or none, has no colour', () => {
    expect(memberColorHex('teal')).toBe('#8ED3DA');
    expect(memberColorHex('chartreuse')).toBeNull();
    expect(memberColorHex('constructor')).toBeNull();
    expect(memberColorHex(undefined)).toBeNull();
  });
});
