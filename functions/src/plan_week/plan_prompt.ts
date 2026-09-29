import type { ModelRequest, ResponseSchema } from '../ai/generative_model';
import type { PlanBrief } from './plan_brief';

/**
 * What the model is asked, and the shape it must answer in (lunch-box
 * ADR-0011). The instruction says nothing about the family; the one message
 * carries the brief — placeholders, item names, one-word tastes — as JSON.
 */
export const PLAN_SYSTEM = [
  "You plan a South African family's week: school lunch boxes for each child, Monday to Friday,",
  "and the family's dinners.",
  'Rules for lunches:',
  '- Fill only the compartments listed in "open" for that child, as "{day}_{slot}".',
  '- Choose only from that child\'s own "candidates" for that slot, by "ref". Never invent an item.',
  '  Every candidate is already safe for that child; anything not listed is not.',
  '- Vary the week: avoid the same item on more than two days, and mix in "new" things now and then.',
  '- Prefer items whose taste is "loved" or "eaten"; rarely choose "left".',
  '- A "goToBoxes" entry is a whole box the child is known to like: using one on a day is good.',
  '- When "usePantry" is true, prefer items with "inPantry", up to that many boxes in all.',
  '- When "thrifty" is true, prefer items with a lower "centsPerBox".',
  'Rules for dinners:',
  '- Plan only the days in "dinnerDays" (1 is Monday, 7 is Sunday).',
  '- Prefer the family\'s own meals, by "ref". Vary them; do not repeat one in a week.',
  '- At most two days may be a new idea instead: a simple, affordable home meal, with its',
  '  ingredients as short shopping-list lines ("onions", "chicken thighs"), each with an optional',
  '  quantity ("1 kg", "2"). No brand names. Keep names under 60 characters.',
  '- If there are no meals to choose from, suggest new ideas for up to three days.',
  'Answer with JSON only, in the shape asked for.',
].join('\n');

const nullableString: ResponseSchema = { type: 'STRING', nullable: true };

/**
 * No `maxItems` anywhere: Vertex refuses a `responseSchema` carrying it
 * (functions `CLAUDE.md`), so the lists are bounded where the reply is parsed
 * (`plan_reply.ts`).
 */
export const PLAN_RESPONSE_SCHEMA: ResponseSchema = {
  type: 'OBJECT',
  properties: {
    lunches: {
      type: 'ARRAY',
      items: {
        type: 'OBJECT',
        properties: {
          child: { type: 'STRING', description: 'child ref, e.g. child-1' },
          day: { type: 'INTEGER', description: '1 (Monday) to 5 (Friday)' },
          slot: { type: 'STRING', enum: ['main', 'fruit', 'veg', 'snack', 'treat'] },
          item: { type: 'STRING', description: "item ref from that child's candidates" },
        },
        required: ['child', 'day', 'slot', 'item'],
      },
    },
    dinners: {
      type: 'ARRAY',
      items: {
        type: 'OBJECT',
        properties: {
          day: { type: 'INTEGER', description: '1 (Monday) to 7 (Sunday)' },
          meal: { ...nullableString, description: 'meal ref, or null for a new idea' },
          newMeal: {
            type: 'OBJECT',
            nullable: true,
            properties: {
              name: { type: 'STRING' },
              ingredients: {
                type: 'ARRAY',
                items: {
                  type: 'OBJECT',
                  properties: { name: { type: 'STRING' }, quantity: nullableString },
                  required: ['name'],
                },
              },
            },
            required: ['name', 'ingredients'],
          },
        },
        required: ['day'],
      },
    },
  },
  required: ['lunches', 'dinners'],
};

/** The request for one week: the brief, and nothing else about the family. */
export function planRequest(brief: PlanBrief): ModelRequest {
  return {
    system: PLAN_SYSTEM,
    parts: [{ kind: 'text', text: JSON.stringify(briefForModel(brief)) }],
    responseSchema: PLAN_RESPONSE_SCHEMA,
    maxOutputTokens: 8192,
    temperature: 0.4,
    labels: { feature: 'planMyWeek' },
  };
}

/** The brief as the model reads it — placeholders only, no ids. */
export function briefForModel(brief: PlanBrief): unknown {
  return {
    usePantry: brief.usePantry,
    thrifty: brief.thrifty,
    children: brief.children.map((child) => ({
      ref: child.ref,
      open: child.open,
      candidates: child.candidates,
      goToBoxes: child.goToBoxes,
      alreadyPacked: child.alreadyPacked,
    })),
    dinnerDays: brief.dinnerDays,
    meals: brief.meals,
    dinnersPlanned: brief.dinnersPlanned,
  };
}
