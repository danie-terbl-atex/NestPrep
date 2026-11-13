import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

import type { MOMENTS } from '../../../src/avatars/avatar_catalogue';
import type { AvatarWear } from '../../../src/avatars/avatar_look';
import { easterSunday, hemisphereOf, layersOn } from '../../../src/avatars/avatar_moments';
import { starStage } from '../../../src/avatars/avatar_stage';

/**
 * The fixture the app's `avatar_moments_test.dart` reads too, so the frame's
 * day and the phone put the same hat on the same member on the same date
 * (avatars ADR-0001, ADR-0004).
 */

interface Fixture {
  readonly moments: typeof MOMENTS;
  readonly easter: readonly { year: number; sunday: string }[];
  readonly hemispheres: readonly { zone: string; hemisphere: string }[];
  readonly cases: readonly {
    name: string;
    today: string;
    zone: string;
    birthday: string | null;
    wear: AvatarWear;
    expect: Record<string, string>;
  }[];
  readonly stages: readonly { earned: number; bestStreak: number; stage: number }[];
}

const fixture = JSON.parse(
  readFileSync(resolve(__dirname, '../../../../app/test/fixtures/avatar_moments.json'), 'utf8'),
) as Fixture;

describe('the fixture shared with the app', () => {
  it.each(fixture.cases)('$name', (shared) => {
    const layers = layersOn(
      shared.wear,
      { today: shared.today, hemisphere: hemisphereOf(shared.zone), birthday: shared.birthday },
      true,
      fixture.moments,
    );
    const worn = new Set(Object.values(shared.wear));
    const moments = Object.fromEntries(
      layers.filter((layer) => !worn.has(layer.id)).map((layer) => [layer.slot, layer.id]),
    );
    expect(moments).toEqual(shared.expect);
  });

  it.each(fixture.easter)('Western Easter Sunday in $year', ({ year, sunday }) => {
    expect(easterSunday(year)).toBe(sunday);
  });

  it.each(fixture.hemispheres)('$zone is in the $hemisphere', ({ zone, hemisphere }) => {
    expect(hemisphereOf(zone)).toBe(hemisphere);
  });

  it.each(fixture.stages)('the stage of $earned earned and a best streak of $bestStreak', (row) => {
    expect(starStage(row)).toBe(row.stage);
  });
});
