import type { ModelRequest, ResponseSchema } from '../ai/generative_model';
import { ideaBriefForModel, type IdeaBrief } from './idea_brief';
import { INGREDIENT_UNITS } from './idea_recipe';

/**
 * What the model is asked when it drafts the week's lunch ideas (lunch-box
 * ADR-0012): a short shopping list a South African grocer stocks, each idea
 * with the words to search the store for — around the store's own lunchbox
 * shelves when the phone read them (ADR-0013) — and each main a dish with its
 * recipe, in the same call (ADR-0021). The instruction says nothing about
 * the family; the one message carries the brief as JSON.
 */
export const IDEAS_SYSTEM = [
  "You draft a South African family's school lunch-box shopping list for one week.",
  'Each child has "open" compartments to fill, counted per kind: main, fruit, veg, snack, treat.',
  'For fruit, veg, snack and treat, propose ideas that a supermarket such as Checkers sells:',
  'one product kind per idea ("yoghurt tubs", "baby carrots"), not recipes or brands.',
  'For main, each idea is a simple dish a parent makes on a school morning or the night before',
  '("Chicken and cheese wrap"), and it carries a "recipe": the dish "name" (under 60',
  'characters); a one-sentence "summary"; 2 to 8 "ingredients", each with a short "name", an',
  'optional "quantity" and "unit" for ONE lunch box, and the words to search the store with',
  '("searchTerm", 1 to 4 words, a product kind, never a brand); 1 to 6 short "steps"; the',
  '"prepMinutes"; and "prepAhead" (true when it is best made the night before) with an optional',
  '"prepNote". The main idea\'s own "searchTerm" is its main ingredient\'s.',
  'For each idea give: its compartment ("slot"); a short name ("idea", under 60 characters);',
  'the words to search the store with ("searchTerm", 1 to 4 words); which children it suits',
  '("children", by ref); and one short reason ("why", under 120 characters).',
  'Cover every compartment kind a child has open, with two or three ideas per kind so the',
  'week can vary. One idea may serve several children. At most 25 ideas.',
  'When "aisle" is given, it lists shelves of the supermarket\'s own kids lunchbox range near',
  'the family, already checked; those products are offered as they are. Draft ideas only where',
  'the shelves are thin: always vegetables, any compartment kind with no shelf, and one or two',
  'alternatives elsewhere. Never repeat a shelf product as an idea.',
  'Lean on "likes" and "ateWell"; avoid "dislikes" and "oftenLeft".',
  'When "budgetCents" is given it is for every child together for the week, in South African',
  'cents: prefer affordable staples and multi-packs that stretch across the week.',
  'When "packing" is given, each line is how the parent wants to pack this week. Follow every',
  'line; it overrides your usual suggestions, and an idea that breaks one does not belong.',
  'Answer with JSON only, in the shape asked for.',
].join('\n');

/** A main idea's dish (lunch-box ADR-0021); bounded by `idea_recipe.ts`, never here. */
const RECIPE_SCHEMA: ResponseSchema = {
  type: 'OBJECT',
  properties: {
    name: { type: 'STRING' },
    summary: { type: 'STRING' },
    ingredients: {
      type: 'ARRAY',
      items: {
        type: 'OBJECT',
        properties: {
          name: { type: 'STRING' },
          quantity: { type: 'NUMBER' },
          unit: { type: 'STRING', enum: [...INGREDIENT_UNITS] },
          searchTerm: { type: 'STRING' },
        },
        required: ['name', 'searchTerm'],
      },
    },
    steps: { type: 'ARRAY', items: { type: 'STRING' } },
    prepMinutes: { type: 'INTEGER' },
    prepAhead: { type: 'BOOLEAN' },
    prepNote: { type: 'STRING' },
  },
  required: ['name', 'ingredients', 'steps', 'prepMinutes'],
};

/** No `maxItems`: Vertex refuses it (functions `CLAUDE.md`); `idea_reply.ts` bounds the list. */
export const IDEAS_RESPONSE_SCHEMA: ResponseSchema = {
  type: 'OBJECT',
  properties: {
    ideas: {
      type: 'ARRAY',
      items: {
        type: 'OBJECT',
        properties: {
          slot: { type: 'STRING', enum: ['main', 'fruit', 'veg', 'snack', 'treat'] },
          idea: { type: 'STRING' },
          searchTerm: { type: 'STRING' },
          children: { type: 'ARRAY', items: { type: 'STRING', description: 'child ref' } },
          why: { type: 'STRING' },
          recipe: RECIPE_SCHEMA,
        },
        required: ['slot', 'idea', 'searchTerm', 'children'],
      },
    },
  },
  required: ['ideas'],
};

export function ideasRequest(brief: IdeaBrief): ModelRequest {
  return {
    system: IDEAS_SYSTEM,
    parts: [{ kind: 'text', text: JSON.stringify(ideaBriefForModel(brief)) }],
    responseSchema: IDEAS_RESPONSE_SCHEMA,
    maxOutputTokens: 8192,
    temperature: 0.6,
    labels: { feature: 'lunchIdeas' },
  };
}
