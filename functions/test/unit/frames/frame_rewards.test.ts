import { describe, expect, it } from 'vitest';

import { assembleFrameDay } from '../../../src/frames/frame_day';
import {
  FRAME_REWARD_LIMIT,
  type RewardSources,
  frameRewardsOf,
  rewardsPanel,
  starsOf,
} from '../../../src/frames/frame_rewards';

/** The reward shelf and each child's stars on a frame (C-0023 rev 22). */

const reward = (id: string, data: Record<string, unknown>): { id: string; data: unknown } => ({
  id,
  data: { title: 'Movie night', cost: 30, icon: 'movie', ...data },
});

describe('a frame’s reward shelf', () => {
  it('cheapest first, then by title, at most the limit', () => {
    const items = frameRewardsOf([
      reward('r-movie', {}),
      reward('r-sweet', { title: 'Sweet', cost: 5, icon: 'treat' }),
      reward('r-book', { title: 'Book', cost: 30, icon: 'book' }),
    ]);
    expect(rewardsPanel({ items, stars: {} }, []).items).toEqual([
      { id: 'r-sweet', title: 'Sweet', cost: 5, icon: 'treat' },
      { id: 'r-book', title: 'Book', cost: 30, icon: 'book' },
      { id: 'r-movie', title: 'Movie night', cost: 30, icon: 'movie' },
    ]);
    const many = frameRewardsOf(
      Array.from({ length: FRAME_REWARD_LIMIT + 5 }, (_, index) =>
        reward(`r-${String(index)}`, { cost: FRAME_REWARD_LIMIT + 5 - index }),
      ),
    );
    const shelf = rewardsPanel({ items: many, stars: {} }, []).items;
    expect(shelf).toHaveLength(FRAME_REWARD_LIMIT);
    expect(shelf[0]?.cost).toBe(1);
  });

  it('leaves off a reward it cannot read', () => {
    expect(
      frameRewardsOf([
        reward('r-blank', { title: '  ' }),
        reward('r-long', { title: 'x'.repeat(61) }),
        reward('r-free', { cost: 0 }),
        reward('r-half', { cost: 2.5 }),
        reward('r-dear', { cost: 10001 }),
        { id: 'r-none', data: undefined },
        reward('r-ok', {}),
      ]).map((each) => each.id),
    ).toEqual(['r-ok']);
  });

  it('passes an icon it does not know through, and a missing or odd one is a gift', () => {
    const icons = frameRewardsOf([
      reward('r-new', { icon: 'pony' }),
      reward('r-none', { icon: undefined }),
      reward('r-odd', { icon: 7 }),
    ]).map((each) => each.icon);
    expect(icons).toEqual(['pony', 'gift', 'gift']);
  });

  it('reads stars as a whole number, never below nothing', () => {
    expect(starsOf({ balance: 24 })).toBe(24);
    expect(starsOf({ balance: -3 })).toBe(0);
    expect(starsOf({ balance: 7.9 })).toBe(7);
    expect(starsOf({ balance: 'lots' })).toBe(0);
    expect(starsOf(undefined)).toBe(0);
  });

  it('gives every child a balance, nothing when the doc is missing', () => {
    const kids = [
      { id: 'm-mia', name: 'Mia' },
      { id: 'm-leo', name: 'Leo' },
    ];
    expect(rewardsPanel({ items: [], stars: { 'm-mia': 24 } }, kids)).toEqual({
      items: [],
      balances: [
        { who: 'Mia', stars: 24 },
        { who: 'Leo', stars: 0 },
      ],
    });
  });
});

describe('the day carries rewards', () => {
  const rewards: RewardSources = {
    items: frameRewardsOf([reward('r-movie', {})]),
    stars: { 'm-mia': 24 },
  };
  const base = {
    householdName: 'Home',
    frameName: 'Kitchen',
    screensaver: null,
    today: '2026-11-04',
    localMinute: 400,
    names: { 'm-mia': 'Mia Parker', 'm-leo': 'Leo', 'm-sam': 'Sam' },
    colors: {},
    kids: ['m-mia', 'm-leo'],
  };
  const panels = { calendar: false, todos: true, meals: false, helperMemberId: null };

  it('with each kid’s stars by first name, in the day’s order of kids', () => {
    expect(assembleFrameDay({ ...base, rewards, panels: panels as never }).rewards).toEqual({
      items: [{ id: 'r-movie', title: 'Movie night', cost: 30, icon: 'movie' }],
      balances: [
        { who: 'Mia', stars: 24 },
        { who: 'Leo', stars: 0 },
      ],
    });
  });

  it('an empty shelf still shows the stars', () => {
    const day = assembleFrameDay({
      ...base,
      rewards: { ...rewards, items: [] },
      panels: panels as never,
    });
    expect(day.rewards?.items).toEqual([]);
    expect(day.rewards?.balances).toHaveLength(2);
  });

  it('not at all with chores off, without kids, or when nothing was read', () => {
    expect(
      assembleFrameDay({ ...base, rewards, panels: { ...panels, todos: false } as never }),
    ).not.toHaveProperty('rewards');
    expect(
      assembleFrameDay({ ...base, rewards, kids: [], panels: panels as never }),
    ).not.toHaveProperty('rewards');
    expect(assembleFrameDay({ ...base, panels: panels as never })).not.toHaveProperty('rewards');
  });
});
