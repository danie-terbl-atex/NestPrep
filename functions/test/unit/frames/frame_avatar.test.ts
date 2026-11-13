import { describe, expect, it } from 'vitest';

import { frameAvatarOf } from '../../../src/frames/frame_avatar';
import { type FrameDaySources, assembleFrameDay } from '../../../src/frames/frame_day';

/** A member's avatar on the wall, resolved by the server (C-0023 rev 18, rev 19). */

const ORDINARY = '2026-08-11';
const HASH = '0123456789abcdef0123456789abcdef';
const day = { today: ORDINARY, hemisphere: 'south' as const };
const look = (overrides: Record<string, unknown> = {}): Record<string, unknown> => ({
  v: 1,
  base: 'preset:pip',
  stage: 2,
  wear: {},
  ...overrides,
});

describe('a member’s avatar on the frame', () => {
  it('is a bundled Nestling at its stage, with what is worn as layers', () => {
    expect(
      frameAvatarOf(look({ wear: { top: 'acc-crown', face: 'acc-round-glasses' } }), day),
    ).toEqual({
      base: { preset: 'nestling-pip-2' },
      layers: [
        { slot: 'top', id: 'acc-crown' },
        { slot: 'face', id: 'acc-round-glasses' },
      ],
    });
    expect(frameAvatarOf(look({ stage: 0 }), day)).toEqual({
      base: { preset: 'nestling-pip-0' },
      layers: [],
    });
  });

  it('is a picture to fetch for an image base, with no face on it', () => {
    expect(
      frameAvatarOf(
        look({ base: `image:${HASH}`, wear: { face: 'acc-round-glasses', badge: 'acc-star' } }),
        day,
      ),
    ).toEqual({ base: { image: HASH }, layers: [{ slot: 'badge', id: 'acc-star' }] });
  });

  it('is the initial with its layers when the member chose the initial, and no face', () => {
    expect(
      frameAvatarOf(
        look({ base: null, wear: { top: 'acc-crown', face: 'acc-round-glasses' } }),
        day,
      ),
    ).toEqual({ base: { initial: true }, layers: [{ slot: 'top', id: 'acc-crown' }] });
    const birthday = { ...day, today: '2026-11-12', birthday: '2018-11-12' };
    expect(frameAvatarOf(look({ base: null }), birthday)).toEqual({
      base: { initial: true },
      layers: [{ slot: 'top', id: 'moment-birthday-hat' }],
    });
  });

  it('is nothing — the initial, as before — for a missing look or a malformed one', () => {
    expect(frameAvatarOf(undefined, day)).toBeUndefined();
    expect(frameAvatarOf({ base: 'preset:pip' }, day)).toBeUndefined();
    expect(frameAvatarOf(look({ v: 2 }), day)).toBeUndefined();
    expect(frameAvatarOf(look({ base: 'preset:godzilla' }), day)).toBeUndefined();
    expect(frameAvatarOf(look({ base: 'image:../../etc' }), day)).toBeUndefined();
  });

  it('leaves off a layer the catalogue does not know or that is in the wrong slot', () => {
    expect(frameAvatarOf(look({ wear: { top: 'acc-jetpack', badge: 'acc-crown' } }), day)).toEqual({
      base: { preset: 'nestling-pip-2' },
      layers: [],
    });
  });

  it('puts today’s moments on, a birthday hat over anything worn', () => {
    const birthday = { ...day, today: '2026-11-12', birthday: '2018-11-12' };
    expect(frameAvatarOf(look({ wear: { top: 'acc-crown' } }), birthday)).toEqual({
      base: { preset: 'nestling-pip-2' },
      layers: [{ slot: 'top', id: 'moment-birthday-hat' }],
    });
    expect(frameAvatarOf(look(), { ...day, today: '2026-12-24' })?.layers).toEqual([
      { slot: 'top', id: 'moment-festive-hat' },
    ]);
  });
});

describe('the day’s members', () => {
  function sources(overrides: Partial<FrameDaySources>): FrameDaySources {
    return {
      householdName: 'The Parkers',
      frameName: 'Kitchen',
      panels: {
        calendar: false,
        todos: false,
        meals: false,
        lunch: false,
        addEvents: false,
        share: false,
        people: false,
        helperMemberId: null,
      },
      screensaver: null,
      today: '2026-06-22',
      localMinute: 9 * 60,
      names: { 'm-sam': 'Sam Parker', 'm-mia': 'Mia' },
      colors: { 'm-sam': 'teal', 'm-mia': 'coral' },
      kids: ['m-mia'],
      ...overrides,
    };
  }

  it('carries an avatar only for a member with a look, and never a member id', () => {
    const day = assembleFrameDay(
      sources({
        looks: { 'm-mia': look({ stage: 1 }) },
        timeZone: 'Africa/Johannesburg',
      }),
    );
    expect(day.household.members).toEqual([
      {
        name: 'Mia',
        color: '#FFC2B3',
        kid: true,
        avatar: {
          base: { preset: 'nestling-pip-1' },
          layers: [{ slot: 'top', id: 'moment-winter-beanie' }],
        },
      },
      { name: 'Sam', color: '#8ED3DA' },
    ]);
    expect(JSON.stringify(day)).not.toContain('m-mia');
  });

  it('carries the initial and its layers for a member whose look is the initial', () => {
    const day = assembleFrameDay(
      sources({ looks: { 'm-sam': look({ base: null }) }, timeZone: 'Africa/Johannesburg' }),
    );
    expect(day.household.members[1]).toEqual({
      name: 'Sam',
      color: '#8ED3DA',
      avatar: { base: { initial: true }, layers: [{ slot: 'top', id: 'moment-winter-beanie' }] },
    });
  });

  it('follows the household’s hemisphere and each member’s own birthday', () => {
    const north = assembleFrameDay(
      sources({
        looks: { 'm-mia': look(), 'm-sam': look() },
        birthdays: { 'm-sam': '--06-22' },
        timeZone: 'Europe/London',
      }),
    );
    expect(north.household.members.map((member) => member.avatar?.layers)).toEqual([
      [],
      [{ slot: 'top', id: 'moment-birthday-hat' }],
    ]);
  });
});
