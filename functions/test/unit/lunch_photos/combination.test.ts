import { describe, expect, it } from 'vitest';

import {
  MAX_FOOD_LENGTH,
  PROMPT_VERSION,
  boxOn,
  combinationOf,
  normalisedFood,
  promptFor,
  type LunchBox,
} from '../../../src/lunch_photos/combination';
import type { LunchPlanFacts, StoredPick } from '../../../src/plan_week/week_documents';

/**
 * What a box's picture is of and what it is cached under (lunch-box
 * ADR-0015): catalogue boxes are shared between households and named by the
 * catalogue; anything of a family's own makes the picture theirs.
 */

const pick = (itemId: string, name: string): StoredPick => ({ itemId, name, allergens: [] });

const SANDWICH = pick('seed-cheese-tomato', 'Cheese and tomato sandwich');
const APPLE = pick('seed-apple', 'Apple slices');
const CATALOGUE_BOX: LunchBox = {
  main: SANDWICH,
  fruit: APPLE,
  snack: pick('seed-biltong', 'Biltong'),
};

describe('a box of catalogue foods only', () => {
  it('is shared, and pictured in compartment order', () => {
    const combination = combinationOf(CATALOGUE_BOX);
    expect(combination?.scope).toBe('shared');
    expect(combination?.foods).toEqual([
      { slot: 'main', food: 'Cheese and tomato sandwich' },
      { slot: 'fruit', food: 'Apple slices' },
      { slot: 'snack', food: 'Biltong' },
    ]);
  });

  it('is named by the catalogue, never by what the household renamed it to', () => {
    const renamed = { ...CATALOGUE_BOX, fruit: pick('seed-apple', "Zola's apple, NO peel") };
    const combination = combinationOf(renamed);
    expect(combination?.foods[1]?.food).toBe('Apple slices');
    expect(combination?.key).toBe(combinationOf(CATALOGUE_BOX)?.key);
  });

  it('is the same key in every household, and a different one for a different box', () => {
    const key = combinationOf(CATALOGUE_BOX)?.key;
    expect(key).toMatch(/^[0-9a-f]{40}$/);
    expect(combinationOf({ ...CATALOGUE_BOX })?.key).toBe(key);
    expect(combinationOf({ ...CATALOGUE_BOX, treat: pick('seed-rusk', 'Rusk') })?.key).not.toBe(
      key,
    );
  });

  it('cares which compartment a food is in', () => {
    const moved: LunchBox = { main: SANDWICH, snack: APPLE };
    const kept: LunchBox = { main: SANDWICH, fruit: APPLE };
    expect(combinationOf(moved)?.key).not.toBe(combinationOf(kept)?.key);
  });
});

describe('a box with anything of the family’s own', () => {
  it('is the household’s, named as stored', () => {
    const box = { ...CATALOGUE_BOX, treat: pick('item-1', 'Ouma’s  rusks\n') };
    const combination = combinationOf(box);
    expect(combination?.scope).toBe('household');
    expect(combination?.foods.at(-1)).toEqual({ slot: 'treat', food: 'Ouma’s rusks' });
    expect(combination?.foods[0]?.food).toBe('Cheese and tomato sandwich');
  });

  it('a seed id the catalogue does not know is the family’s own', () => {
    const box: LunchBox = { main: pick('seed-unknown', 'Mystery sandwich') };
    expect(combinationOf(box)?.scope).toBe('household');
  });

  it('is keyed by the words, whatever their case or spacing', () => {
    const a = combinationOf({ main: pick('a', 'Chicken  Wrap') });
    const b = combinationOf({ main: pick('b', 'chicken wrap ') });
    expect(a?.key).toBe(b?.key);
  });

  it('never shares a key with the same foods from the catalogue', () => {
    const own = combinationOf({ snack: pick('item-1', 'Biltong') });
    const seeded = combinationOf({ snack: pick('seed-biltong', 'Biltong') });
    expect(own?.key).not.toBe(seeded?.key);
  });

  it('leaves out a pick with no name, and is nothing when that was all', () => {
    expect(combinationOf({ main: pick('a', '   '), fruit: pick('b', 'Pear') })?.foods).toEqual([
      { slot: 'fruit', food: 'Pear' },
    ]);
    expect(combinationOf({ main: pick('a', '  ') })).toBeNull();
  });
});

describe('a food’s name', () => {
  it('is one line, trimmed, at most sixty characters', () => {
    expect(normalisedFood('  Peanut\tbutter \n sandwich ')).toBe('Peanut butter sandwich');
    expect(normalisedFood('x'.repeat(100))).toHaveLength(MAX_FOOD_LENGTH);
  });
});

describe('an empty box', () => {
  it('has no combination', () => {
    expect(combinationOf({})).toBeNull();
  });
});

describe('the box on a day', () => {
  it('is that weekday’s picks from the plan', () => {
    const plan: LunchPlanFacts = {
      childId: 'm-zola',
      weekStart: '2026-09-28',
      slots: {
        '1_main': pick('seed-egg-mayo', 'Egg mayo sandwich'),
        '2_main': pick('seed-tuna-sandwich', 'Tuna sandwich'),
        '2_fruit': pick('seed-pear', 'Pear'),
      },
      feedback: {},
    };
    expect(boxOn(plan, 2)).toEqual({
      main: pick('seed-tuna-sandwich', 'Tuna sandwich'),
      fruit: pick('seed-pear', 'Pear'),
    });
    expect(boxOn(plan, 3)).toEqual({});
  });
});

describe('the prompt', () => {
  it('lists the foods and says no people, no text', () => {
    const prompt = promptFor([
      { slot: 'main', food: 'Tuna sandwich' },
      { slot: 'fruit', food: 'Pear' },
    ]);
    expect(prompt).toContain('Its compartments hold: Tuna sandwich; Pear. ');
    expect(prompt).toMatch(/^Ultra-realistic, appetising editorial food photograph/);
    expect(prompt).toMatch(/No people, no hands, no text, no labels, no logos\.$/);
  });

  it('is versioned, so a new prompt is a new set of pictures', () => {
    expect(PROMPT_VERSION).toBe('v1');
  });
});
