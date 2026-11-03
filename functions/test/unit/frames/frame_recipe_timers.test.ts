import { describe, expect, it } from 'vitest';

import {
  STEP_TIMER_MAX_SECONDS,
  STEP_TIMER_MIN_SECONDS,
  stepTimers,
} from '../../../src/frames/frame_recipe_timers';
import { readCatalogueRecipes } from '../../../src/recipes/catalogue_recipe_files';

const phrases = (text: string): [string, number, number | null][] =>
  stepTimers(text).map(({ start, end, seconds, upToSeconds }) => [
    text.slice(start, end),
    seconds,
    upToSeconds,
  ]);

describe('the timers in a step', () => {
  it.each<[string, [string, number, number | null][]]>([
    ['Stir for 30 seconds.', [['30 seconds', 30, null]]],
    ['Simmer for 12–15 minutes.', [['12–15 minutes', 720, 900]]],
    ['Simmer for 12-15 minutes.', [['12-15 minutes', 720, 900]]],
    ['Simmer for 12 - 15 minutes.', [['12 - 15 minutes', 720, 900]]],
    ['Cook for 2 to 3 minutes a side.', [['2 to 3 minutes', 120, 180]]],
    ['Fry until golden, about 8 minutes.', [['8 minutes', 480, null]]],
    ['Rise for 45 minutes to 1 hour.', [['45 minutes to 1 hour', 2700, 3600]]],
    ['Cook for 1 hour to 1 hour 15 minutes.', [['1 hour to 1 hour 15 minutes', 3600, 4500]]],
    ['Bake for 1 hour 30 minutes.', [['1 hour 30 minutes', 5400, null]]],
    ['Bake for 1 hour and 30 minutes.', [['1 hour and 30 minutes', 5400, null]]],
    ['Boil for 2 minutes 30 seconds.', [['2 minutes 30 seconds', 150, null]]],
    ['Leave for 1½ hours.', [['1½ hours', 5400, null]]],
    ['Leave for 1 1/2 hours.', [['1 1/2 hours', 5400, null]]],
    ['Leave for 1/2 hour.', [['1/2 hour', 1800, null]]],
    ['Leave for ½ hour.', [['½ hour', 1800, null]]],
    ['Leave for 1–1.5 hours.', [['1–1.5 hours', 3600, 5400]]],
    ['Simmer for 2½–3 hours.', [['2½–3 hours', 9000, 10800]]],
    ['Simmer for 3 to 3½ hours.', [['3 to 3½ hours', 10800, 12600]]],
    ['Sear for 1–1½ minutes a side.', [['1–1½ minutes', 60, 90]]],
    ['Simmer for 5 more minutes.', [['5 more minutes', 300, null]]],
    [
      'Bake 10 MINS, then 2 hrs.',
      [
        ['10 MINS', 600, null],
        ['2 hrs', 7200, null],
      ],
    ],
    [
      'Rest 1 hr, toast 45 secs, chill 20 min.',
      [
        ['1 hr', 3600, null],
        ['45 secs', 45, null],
        ['20 min', 1200, null],
      ],
    ],
    [
      'Cook on low for 6 hours or on high for 3½ hours.',
      [
        ['6 hours', 21600, null],
        ['3½ hours', 12600, null],
      ],
    ],
    [
      'Marinate for at least 30 minutes, or up to 8 hours.',
      [
        ['30 minutes', 1800, null],
        ['8 hours', 28800, null],
      ],
    ],
    [
      'Simmer for 2 hours, stirring every 20 minutes.',
      [
        ['2 hours', 7200, null],
        ['20 minutes', 1200, null],
      ],
    ],
    ['Cook for 10 seconds.', [['10 seconds', 10, null]]],
    ['Cook for 12 hours.', [['12 hours', 43200, null]]],
  ])('%s', (text, expected) => {
    expect(phrases(text)).toEqual(expected);
  });

  it.each([
    ['too short to set', 'Hold your hand above the grid for 5–6 seconds.'],
    ['too short to set', 'Let them drip for 2 seconds.'],
    ['too short to set', 'Hold your hand over it for 8 to 10 seconds.'],
    ['too long to set', 'Refrigerate for 24 hours.'],
    ['too long to set, as a whole', 'Leave in a warm spot for 24–48 hours.'],
    ['too long to set', 'Cook for 13 hours.'],
    ['a range that runs backwards', 'Cook for 10–5 minutes.'],
    ['an adjective, not a duration', 'Stir at the 15-minute mark.'],
    ['a temperature', 'Heat the oven to 180 °C.'],
    ['a size', 'Grease a 20 cm tin.'],
    ['not a unit', 'Add 5 mint leaves and 2 minced cloves.'],
    ['no number', 'Cook for a few minutes, then another minute.'],
    ['days', 'It keeps for 5 days.'],
    ['part of a word', 'Bake in batch A5 minutes apart.'],
  ])('finds none: %s — %s', (_why, text) => {
    expect(stepTimers(text)).toEqual([]);
  });

  it('gives UTF-16 offsets, the same ones Kotlin reads', () => {
    const text = 'Fry the 🌶️ chilli for 2 minutes.';
    const [timer] = stepTimers(text);
    expect(timer?.start).toBe(text.indexOf('2 minutes'));
    expect(timer?.end).toBe(text.indexOf('.', timer?.start));
  });
});

const LOOSE_MENTION = /\d[\d½¼¾⅓⅔./ ]*\s*(?:more\s+)?(?:sec|min|hour|hr)/gi;
const SET_ASIDE =
  /\b(?:\d(?:\s*(?:–|-|to)\s*\d+)?\s+seconds?|(?:2[4-9]|[3-9]\d)(?:\s*(?:–|-|to)\s*\d+)?\s+hours?)\b/gi;
const PHRASE = /^[\d½¼¾⅓⅔][\s\S]*\b(?:seconds?|secs?|minutes?|mins?|hours?|hrs?)$/i;

describe('the timers in every catalogue step', () => {
  const steps = readCatalogueRecipes().flatMap((recipe) => recipe.steps);

  it('are well formed, in order and apart', () => {
    for (const text of steps) {
      let previousEnd = 0;
      for (const { start, end, seconds, upToSeconds } of stepTimers(text)) {
        expect(start).toBeGreaterThanOrEqual(previousEnd);
        expect(end).toBeLessThanOrEqual(text.length);
        expect(text.slice(start, end)).toMatch(PHRASE);
        expect(seconds).toBeGreaterThanOrEqual(STEP_TIMER_MIN_SECONDS);
        expect(upToSeconds ?? seconds).toBeLessThanOrEqual(STEP_TIMER_MAX_SECONDS);
        if (upToSeconds !== null) expect(upToSeconds).toBeGreaterThan(seconds);
        previousEnd = end;
      }
    }
  });

  it('name a timer in most steps', () => {
    const timed = steps.filter((text) => stepTimers(text).length > 0).length;
    console.info(`${String(timed)} of ${String(steps.length)} catalogue steps name a timer`);
    expect(timed).toBeGreaterThanOrEqual(600);
  });

  it('miss only the durations too short or too long to set', () => {
    const missed = steps.flatMap((text) => {
      const covered = [
        ...stepTimers(text),
        ...[...text.matchAll(SET_ASIDE)].map((match) => ({
          start: match.index,
          end: match.index + match[0].length,
        })),
      ];
      return [...text.matchAll(LOOSE_MENTION)]
        .filter(
          (mention) =>
            !covered.some(({ start, end }) => mention.index >= start && mention.index < end),
        )
        .map((mention) => text.slice(Math.max(0, mention.index - 30), mention.index + 30));
    });
    expect(missed).toEqual([]);
  });
});
