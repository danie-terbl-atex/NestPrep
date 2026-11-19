import { describe, expect, it } from 'vitest';
import { HttpsError } from 'firebase-functions/v2/https';

import {
  assembleFrameMeals,
  mealWeekOf,
  plannedMealIds,
} from '../../../src/frames/frame_meal_week';
import { FRAME_MEALS_PER_CREDENTIAL } from '../../../src/frames/frame_policy';
import { getFrameMealsInput } from '../../../src/frames/frame_schemas';
import { parseInput } from '../../../src/household/parse_input';

/** A week of meals for the frame's Meals overview (NestPrep-Home ADR-0029). */

const SECRET = 'a'.repeat(43);

describe('the week a frame asks for', () => {
  it('is named by its Monday: this week or the next, across a month and a year', () => {
    expect(mealWeekOf('2026-11-19', 'this')).toBe('2026-11-16');
    expect(mealWeekOf('2026-11-19', 'next')).toBe('2026-11-23');
    expect(mealWeekOf('2026-11-16', 'this')).toBe('2026-11-16');
    expect(mealWeekOf('2026-11-22', 'next')).toBe('2026-11-23');
    expect(mealWeekOf('2026-12-31', 'next')).toBe('2027-01-04');
  });

  it('reads every meal the week plans, in day and slot order', () => {
    expect(
      plannedMealIds({
        '7_dinner': 'braai',
        '1_lunch': 'toasties',
        '1_breakfast': 'oats',
        '9_lunch': 'x',
      }),
    ).toEqual(['oats', 'toasties', 'braai']);
  });
});

describe('a frame’s week of meals', () => {
  it('seven days from Monday, each with its planned slots in order and a photo only when pictured', () => {
    const week = assembleFrameMeals({
      today: '2026-11-19',
      week: '2026-11-16',
      meals: {
        slots: {
          '1_dinner': 'recipe-bobotie',
          '1_breakfast': 'oats',
          '4_lunch': 'toasties',
          '6_dinner': 'gone',
          '7_dinner': 'braai',
        },
        mealNames: {
          'recipe-bobotie': 'Bobotie',
          oats: 'Oats',
          toasties: 'Toasties',
          braai: 'Braai',
        },
        photos: ['recipe-bobotie'],
      },
    });
    expect(week).toEqual({
      status: 'linked',
      today: '2026-11-19',
      week: '2026-11-16',
      days: [
        {
          date: '2026-11-16',
          slots: [
            { slot: 'breakfast', title: 'Oats' },
            { slot: 'dinner', title: 'Bobotie', photo: 'recipe-bobotie' },
          ],
        },
        { date: '2026-11-17', slots: [] },
        { date: '2026-11-18', slots: [] },
        { date: '2026-11-19', slots: [{ slot: 'lunch', title: 'Toasties' }] },
        { date: '2026-11-20', slots: [] },
        { date: '2026-11-21', slots: [] },
        { date: '2026-11-22', slots: [{ slot: 'dinner', title: 'Braai' }] },
      ],
    });
  });

  it('has no days when the frame does not show meals', () => {
    expect(assembleFrameMeals({ today: '2026-11-19', week: '2026-11-23' })).toEqual({
      status: 'linked',
      today: '2026-11-19',
      week: '2026-11-23',
      days: [],
    });
  });
});

describe('getFrameMeals’s input and limits', () => {
  it('takes a secret and this or next week, nothing further', () => {
    expect(parseInput(getFrameMealsInput, { secret: SECRET, week: 'next' })).toEqual({
      secret: SECRET,
      week: 'next',
    });
    for (const week of ['last', 'after', 1, '2026-11-16', '', null]) {
      expect(() => parseInput(getFrameMealsInput, { secret: SECRET, week })).toThrow(HttpsError);
    }
    expect(() => parseInput(getFrameMealsInput, { week: 'this' })).toThrow(HttpsError);
  });

  it('is limited per credential', () => {
    expect(FRAME_MEALS_PER_CREDENTIAL).toMatchObject({
      name: 'getFrameMeals:credential',
      limit: 120,
    });
  });
});
