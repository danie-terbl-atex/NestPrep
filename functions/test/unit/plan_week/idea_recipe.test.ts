import { describe, expect, it } from 'vitest';

import { ideaBriefFrom, type IdeaBrief } from '../../../src/plan_week/idea_brief';
import { IDEAS_RESPONSE_SCHEMA, IDEAS_SYSTEM } from '../../../src/plan_week/idea_prompt';
import { ideaRecipeFrom, RECIPE_LIMITS } from '../../../src/plan_week/idea_recipe';
import { ideasFrom } from '../../../src/plan_week/idea_reply';
import { SCHOOL_WEEK, rulesOf } from './fixtures';

/**
 * A main idea is a dish with its recipe, drafted in the same model call
 * (lunch-box ADR-0021 §1–2): bounded in the parse, read against every child
 * on all its words, and carrying allergen codes NestPrep derived.
 */

const WRAP = {
  name: 'Mexican wholewheat wrap',
  summary: 'Chicken, corn and cheese rolled in a soft wrap.',
  ingredients: [
    { name: 'Wholewheat tortillas', quantity: 1, unit: null, searchTerm: 'wholewheat tortillas' },
    { name: 'Cooked chicken strips', quantity: 50, unit: 'g', searchTerm: 'chicken strips' },
    { name: 'Grated cheddar cheese', quantity: 2, unit: 'tbsp', searchTerm: 'grated cheddar' },
    { name: 'Sweetcorn', quantity: 2, unit: 'tbsp', searchTerm: 'sweetcorn tin' },
  ],
  steps: ['Warm the tortilla.', 'Fill with chicken, corn and cheese.', 'Roll up tightly.'],
  prepMinutes: 10,
  prepAhead: false,
};

function briefFor(mia = rulesOf({ allergyCodes: ['milk'] }), leo = rulesOf()): IdeaBrief {
  return ideaBriefFrom(
    [
      { memberId: 'mia', rules: mia },
      { memberId: 'leo', rules: leo },
    ],
    [],
    SCHOOL_WEEK,
    null,
  );
}

const mainIdea = (recipe: unknown): Record<string, unknown> => ({
  slot: 'main',
  idea: 'Mexican whole wheat wrap',
  searchTerm: 'wholewheat tortillas',
  children: ['child-1', 'child-2'],
  why: 'Easy to eat cold',
  recipe,
});

describe('a main idea keeps its dish when the dish is within every bound', () => {
  it('parses the recipe, one box’s worth, with the codes its words name', () => {
    const recipe = ideaRecipeFrom(WRAP);
    expect(recipe?.name).toBe('Mexican wholewheat wrap');
    expect(recipe?.ingredients).toHaveLength(4);
    expect(recipe?.ingredients[1]).toEqual({
      name: 'Cooked chicken strips',
      quantity: 50,
      unit: 'g',
      searchTerm: 'chicken strips',
    });
    expect(recipe?.allergens).toEqual(['milk', 'wheat']);
    expect(recipe?.prepNote).toBeNull();
  });

  it('drops a recipe that breaks a bound — never half a recipe', () => {
    const tooMany = Array.from({ length: RECIPE_LIMITS.maxIngredients + 1 }, (_, i) => ({
      name: `Thing ${String(i)}`,
      searchTerm: 'thing',
    }));
    for (const broken of [
      { ...WRAP, name: 'x'.repeat(RECIPE_LIMITS.name + 1) },
      { ...WRAP, ingredients: tooMany },
      { ...WRAP, ingredients: [WRAP.ingredients[0]] },
      { ...WRAP, steps: Array.from({ length: RECIPE_LIMITS.maxSteps + 1 }, () => 'Stir.') },
      { ...WRAP, steps: [] },
      { ...WRAP, prepMinutes: 0 },
      { ...WRAP, prepMinutes: RECIPE_LIMITS.maxPrepMinutes + 1 },
      { ...WRAP, ingredients: [{ ...WRAP.ingredients[0], unit: 'handful' }, WRAP.ingredients[1]] },
      { ...WRAP, ingredients: [{ ...WRAP.ingredients[0], searchTerm: '' }, WRAP.ingredients[1]] },
      'a wrap',
      null,
    ]) {
      expect(ideaRecipeFrom(broken)).toBeNull();
    }
  });

  it('keeps the idea as a product idea when its recipe is dropped', () => {
    const [idea] = ideasFrom({ ideas: [mainIdea({ ...WRAP, steps: [] })] }, briefFor());
    expect(idea?.idea).toBe('Mexican whole wheat wrap');
    expect(idea).not.toHaveProperty('recipe');
  });

  it('reads a recipe only on a main — a snack is still one product', () => {
    const [snack] = ideasFrom(
      { ideas: [{ ...mainIdea(WRAP), slot: 'snack', idea: 'Rice cakes' }] },
      briefFor(),
    );
    expect(snack).not.toHaveProperty('recipe');
  });
});

describe('a dish is struck out on every one of its words (ADR-0021 §2)', () => {
  it('strikes the wrap out for the child its cheese would hurt, and says why', () => {
    const [wrap] = ideasFrom(
      { ideas: [mainIdea({ ...WRAP, name: 'Chicken wrap' })] },
      briefFor(rulesOf({ allergyCodes: ['milk'] }), rulesOf()),
    );
    expect(wrap?.recipe?.name).toBe('Chicken wrap');
    expect(wrap?.childIds).toEqual(['leo']);
    expect(wrap?.excluded).toEqual([{ childId: 'mia', reason: 'allergy', allergen: 'milk' }]);
  });

  it('strikes out a dislike named only in an ingredient', () => {
    const [wrap] = ideasFrom(
      { ideas: [mainIdea(WRAP)] },
      briefFor(rulesOf(), rulesOf({ dislikes: ['sweetcorn'] })),
    );
    expect(wrap?.excluded).toEqual([{ childId: 'leo', reason: 'dislike', allergen: null }]);
  });

  it('reads "wholewheat" and "tortilla" as wheat', () => {
    const [wrap] = ideasFrom(
      {
        ideas: [
          mainIdea({
            ...WRAP,
            name: 'Chicken roll-up',
            ingredients: [WRAP.ingredients[0], WRAP.ingredients[1]],
          }),
        ],
      },
      briefFor(rulesOf({ allergyCodes: ['wheat'] }), rulesOf()),
    );
    expect(wrap?.excluded).toEqual([{ childId: 'mia', reason: 'allergy', allergen: 'wheat' }]);
  });
});

describe('a dish is read on what is bought, its search words too (ADR-0023 §1)', () => {
  const banana = {
    ...WRAP,
    name: 'Banana sandwich',
    summary: 'A sweet sandwich.',
    ingredients: [
      { name: 'Banana', quantity: 1, unit: null, searchTerm: 'bananas' },
      { name: 'Spread', quantity: 1, unit: 'tbsp', searchTerm: 'peanut butter' },
    ],
  };

  it('strikes a peanut-allergic child when only a search term names peanuts', () => {
    const [idea] = ideasFrom(
      { ideas: [{ ...mainIdea(banana), idea: 'Banana sandwich', searchTerm: 'bananas' }] },
      briefFor(rulesOf({ allergyCodes: ['peanut'] }), rulesOf()),
    );
    expect(idea?.excluded).toContainEqual({
      childId: 'mia',
      reason: 'allergy',
      allergen: 'peanut',
    });
    expect(idea?.childIds).toEqual(['leo']);
  });

  it('carries the code a search term names', () => {
    expect(ideaRecipeFrom(banana)?.allergens).toContain('peanut');
  });
});

describe('the model is asked for the dish in the same call (ADR-0021 §1)', () => {
  it('asks for a recipe on mains only, and the schema carries it as optional', () => {
    expect(IDEAS_SYSTEM).toContain('For main, each idea is a simple dish');
    const idea =
      IDEAS_RESPONSE_SCHEMA.type === 'OBJECT' ? IDEAS_RESPONSE_SCHEMA.properties.ideas : undefined;
    const item = idea?.type === 'ARRAY' ? idea.items : undefined;
    expect(item?.type === 'OBJECT' && 'recipe' in item.properties).toBe(true);
    expect(item?.type === 'OBJECT' ? item.required : []).not.toContain('recipe');
  });

  it('never puts a list bound in the schema — Vertex refuses maxItems', () => {
    expect(JSON.stringify(IDEAS_RESPONSE_SCHEMA)).not.toContain('maxItems');
  });
});
