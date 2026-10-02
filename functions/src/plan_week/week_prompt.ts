import type { ModelRequest, ResponseSchema } from '../ai/generative_model';
import { weekBriefForModel, type WeekBrief } from './week_brief';

/**
 * What the model is asked when it builds the week from what the store has
 * (lunch-box ADR-0012): which product goes in each open compartment, and how
 * many boxes one pack of each does. The instruction says nothing about the
 * family; the one message carries the brief as JSON.
 */
export const WEEK_SYSTEM = [
  "You fill a South African family's school lunch boxes for one week from products a",
  'supermarket has in stock.',
  '- Fill only the compartments in each child\'s "open" list, written "{day}_{slot}"',
  '  (day 1 is Monday, 5 is Friday).',
  '- Use only products listed under an idea with the same slot, by "ref", and only for',
  '  children that product lists in "children". Never invent a product.',
  '- Ideas marked "aisle": true are from the supermarket\'s own kids lunchbox range; lean on',
  '  them where they suit the child and the budget.',
  '- Vary the week: the same product on at most three days for one child.',
  '- "budgetCents" is for every child together, in South African cents, and is what the',
  '  shop costs at the till: products are bought in whole packs, so sharing one pack',
  '  across children and days is cheaper. Stay within it where you can; when nothing',
  '  is given, keep it sensible.',
  '- For every product you use, say how many lunch boxes one pack does ("boxesPerPack"):',
  '  a 6-pack of yoghurts does 6, a loaf of bread about 8, a bag of apples about 6.',
  '  "packQuantity", when given, is how many items the pack holds.',
  'Answer with JSON only, in the shape asked for.',
].join('\n');

/** No `maxItems`: Vertex refuses it; `week_reply.ts` bounds the lists. */
export const WEEK_RESPONSE_SCHEMA: ResponseSchema = {
  type: 'OBJECT',
  properties: {
    packs: {
      type: 'ARRAY',
      items: {
        type: 'OBJECT',
        properties: {
          product: { type: 'STRING', description: 'product ref, e.g. p-1' },
          boxesPerPack: { type: 'INTEGER' },
        },
        required: ['product', 'boxesPerPack'],
      },
    },
    lunches: {
      type: 'ARRAY',
      items: {
        type: 'OBJECT',
        properties: {
          child: { type: 'STRING', description: 'child ref, e.g. child-1' },
          day: { type: 'INTEGER', description: '1 (Monday) to 5 (Friday)' },
          slot: { type: 'STRING', enum: ['main', 'fruit', 'veg', 'snack', 'treat'] },
          product: { type: 'STRING', description: 'product ref' },
        },
        required: ['child', 'day', 'slot', 'product'],
      },
    },
  },
  required: ['packs', 'lunches'],
};

export function weekRequest(brief: WeekBrief): ModelRequest {
  return {
    system: WEEK_SYSTEM,
    parts: [{ kind: 'text', text: JSON.stringify(weekBriefForModel(brief)) }],
    responseSchema: WEEK_RESPONSE_SCHEMA,
    maxOutputTokens: 8192,
    temperature: 0.4,
    labels: { feature: 'lunchWeek' },
  };
}
