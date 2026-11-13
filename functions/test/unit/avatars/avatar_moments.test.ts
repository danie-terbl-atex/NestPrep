import { describe, expect, it } from 'vitest';

import { MOMENTS } from '../../../src/avatars/avatar_catalogue';
import {
  type MomentDay,
  easterSunday,
  hemisphereOf,
  isBirthdayOn,
  layersOn,
  momentIsOn,
} from '../../../src/avatars/avatar_moments';

/** Moments are computed from the date, the zone and the birthday, never stored (avatars ADR-0001). */

const south = (today: string, birthday?: string): MomentDay => ({
  today,
  hemisphere: 'south',
  ...(birthday === undefined ? {} : { birthday }),
});
const north = (today: string): MomentDay => ({ today, hemisphere: 'north' });

function momentsOn(day: MomentDay): string[] {
  return MOMENTS.filter((moment) => momentIsOn(moment.rule, day)).map((moment) => moment.id);
}

describe('Western Easter Sunday', () => {
  it.each([
    [2008, '2008-03-23'],
    [2011, '2011-04-24'],
    [2019, '2019-04-21'],
    [2024, '2024-03-31'],
    [2025, '2025-04-20'],
    [2026, '2026-04-05'],
    [2027, '2027-03-28'],
    [2038, '2038-04-25'],
    [2285, '2285-03-22'],
  ])('falls in %i on %s', (year, sunday) => {
    expect(easterSunday(year)).toBe(sunday);
  });

  it('puts the Easter ears on from Good Friday to Easter Monday, and not a day either side', () => {
    expect(momentsOn(south('2026-04-02'))).not.toContain('moment-easter-ears');
    for (const date of ['2026-04-03', '2026-04-04', '2026-04-05', '2026-04-06']) {
      expect(momentsOn(south(date)), date).toContain('moment-easter-ears');
    }
    expect(momentsOn(south('2026-04-07'))).not.toContain('moment-easter-ears');
  });

  it('moves with the year, and the window can cross into April', () => {
    expect(momentsOn(south('2024-04-01'))).toContain('moment-easter-ears');
    expect(momentsOn(south('2024-04-02'))).not.toContain('moment-easter-ears');
    expect(momentsOn(south('2027-03-26'))).toContain('moment-easter-ears');
  });
});

describe('a run of dates', () => {
  it('is inclusive at both ends', () => {
    expect(momentsOn(south('2026-12-19'))).not.toContain('moment-festive-hat');
    expect(momentsOn(south('2026-12-20'))).toContain('moment-festive-hat');
    expect(momentsOn(south('2026-12-26'))).toContain('moment-festive-hat');
    expect(momentsOn(south('2026-12-27'))).not.toContain('moment-festive-hat');
  });

  it('wraps the year', () => {
    expect(momentsOn(south('2026-12-30'))).not.toContain('moment-new-year-crown');
    expect(momentsOn(south('2026-12-31'))).toContain('moment-new-year-crown');
    expect(momentsOn(south('2027-01-01'))).toContain('moment-new-year-crown');
    expect(momentsOn(south('2027-01-02'))).not.toContain('moment-new-year-crown');
    expect(momentIsOn({ kind: 'dates', from: '11-30', to: '02-01' }, south('2026-07-15'))).toBe(
      false,
    );
  });

  it('can be one day', () => {
    expect(momentsOn(south('2026-02-14'))).toContain('moment-valentine-heart');
    expect(momentsOn(south('2026-02-15'))).not.toContain('moment-valentine-heart');
  });

  it('follows the household’s hemisphere when it names one', () => {
    expect(momentsOn(south('2026-06-21'))).toContain('moment-winter-beanie');
    expect(momentsOn(north('2026-06-21'))).not.toContain('moment-winter-beanie');
    expect(momentsOn(north('2026-12-21'))).toContain('moment-winter-beanie-north');
    expect(momentsOn(south('2026-12-21'))).not.toContain('moment-winter-beanie-north');
    expect(momentsOn(north('2026-10-31'))).toContain('moment-spooky-hat');
    expect(momentsOn(south('2026-10-31'))).toContain('moment-spooky-hat');
  });
});

describe('the hemisphere of a household’s zone', () => {
  it.each([
    ['Africa/Johannesburg', 'south'],
    ['Australia/Sydney', 'south'],
    ['Australia/Perth', 'south'],
    ['Pacific/Auckland', 'south'],
    ['America/Sao_Paulo', 'south'],
    ['America/Argentina/Buenos_Aires', 'south'],
    ['Europe/London', 'north'],
    ['America/New_York', 'north'],
    ['Africa/Lagos', 'north'],
    ['UTC', 'north'],
    ['Not/AZone', 'north'],
  ])('%s is %s', (zone, hemisphere) => {
    expect(hemisphereOf(zone)).toBe(hemisphere);
  });

  it('is north with no zone at all', () => {
    expect(hemisphereOf(null)).toBe('north');
    expect(hemisphereOf(undefined)).toBe('north');
  });
});

describe('a birthday', () => {
  it('is the day whatever the year, with or without a known year', () => {
    expect(isBirthdayOn('2018-11-12', '2026-11-12')).toBe(true);
    expect(isBirthdayOn('--11-12', '2026-11-12')).toBe(true);
    expect(isBirthdayOn('2018-11-12', '2026-11-13')).toBe(false);
    expect(isBirthdayOn('2018-12-11', '2026-11-12')).toBe(false);
  });

  it('on 29 February is kept on the 28th in a year without one', () => {
    expect(isBirthdayOn('2016-02-29', '2027-02-28')).toBe(true);
    expect(isBirthdayOn('2016-02-29', '2027-03-01')).toBe(false);
    expect(isBirthdayOn('2016-02-29', '2028-02-28')).toBe(false);
    expect(isBirthdayOn('2016-02-29', '2028-02-29')).toBe(true);
    expect(isBirthdayOn('--02-29', '2100-02-28')).toBe(true);
  });

  it('is never one when it is missing or malformed', () => {
    expect(isBirthdayOn(null, '2026-11-12')).toBe(false);
    expect(isBirthdayOn(undefined, '2026-11-12')).toBe(false);
    expect(isBirthdayOn('11-12', '2026-11-12')).toBe(false);
    expect(isBirthdayOn('12 November', '2026-11-12')).toBe(false);
  });
});

describe('which moment shows', () => {
  it('a birthday hat takes its slot even over what is worn', () => {
    expect(
      layersOn({ top: 'acc-crown', badge: 'acc-star' }, south('2026-11-12', '--11-12'), true),
    ).toEqual([
      { slot: 'top', id: 'moment-birthday-hat' },
      { slot: 'badge', id: 'acc-star' },
    ]);
  });

  it('a birthday hat beats a season’s hat on the same day', () => {
    expect(layersOn({}, south('2026-12-24', '2019-12-24'), true)).toEqual([
      { slot: 'top', id: 'moment-birthday-hat' },
    ]);
  });

  it('any other moment fills a slot only when nothing is worn there', () => {
    expect(layersOn({}, south('2026-12-24'), true)).toEqual([
      { slot: 'top', id: 'moment-festive-hat' },
    ]);
    expect(layersOn({ top: 'acc-cap' }, south('2026-12-24'), true)).toEqual([
      { slot: 'top', id: 'acc-cap' },
    ]);
  });

  it('puts at most one moment in a slot, the first in catalogue order', () => {
    const both = [
      {
        id: 'moment-a',
        label: 'A',
        slot: 'badge' as const,
        rule: { kind: 'dates' as const, from: '05-01', to: '05-01' },
      },
      {
        id: 'moment-b',
        label: 'B',
        slot: 'badge' as const,
        rule: { kind: 'dates' as const, from: '05-01', to: '05-01' },
      },
    ];
    expect(layersOn({}, south('2026-05-01'), true, both)).toEqual([
      { slot: 'badge', id: 'moment-a' },
    ]);
  });

  it('keeps a moment for the face off anything but a Nestling', () => {
    const face = [
      {
        id: 'moment-mask',
        label: 'Mask',
        slot: 'face' as const,
        rule: { kind: 'dates' as const, from: '05-01', to: '05-01' },
      },
    ];
    expect(layersOn({}, south('2026-05-01'), false, face)).toEqual([]);
    expect(layersOn({}, south('2026-05-01'), true, face)).toEqual([
      { slot: 'face', id: 'moment-mask' },
    ]);
  });

  it('is nothing on an ordinary day, and what is worn in slot order', () => {
    expect(layersOn({}, south('2026-08-11'), true)).toEqual([]);
    expect(
      layersOn(
        { face: 'acc-round-glasses', ring: 'acc-gold-ring', top: 'acc-crown' },
        south('2026-08-11'),
        true,
      ),
    ).toEqual([
      { slot: 'top', id: 'acc-crown' },
      { slot: 'ring', id: 'acc-gold-ring' },
      { slot: 'face', id: 'acc-round-glasses' },
    ]);
  });
});
