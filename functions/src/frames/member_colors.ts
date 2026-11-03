/**
 * The light theme's fill for each member colour the app stores by name
 * (`nest_member_palette.dart`), as a frame draws it. A name outside the
 * palette has no colour; `member_colors.test.ts` holds this to the app's.
 */
export const MEMBER_COLOR_HEX: ReadonlyMap<string, string> = new Map(
  Object.entries({
    violet: '#C9BFFF',
    pink: '#F7BFDD',
    coral: '#FFC2B3',
    amber: '#F7C85C',
    lime: '#B9DB72',
    mint: '#86D9B8',
    teal: '#8ED3DA',
    sky: '#A6CCFF',
    indigo: '#B8C3FF',
    plum: '#E2BFF2',
  }),
);

export function memberColorHex(name: string | undefined): string | null {
  return name === undefined ? null : (MEMBER_COLOR_HEX.get(name) ?? null);
}
