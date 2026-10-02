import type { ModelRequest, ResponseSchema } from '../ai/generative_model';
import { ideaBriefForModel, type IdeaBrief } from './idea_brief';

/**
 * What the model is asked when it drafts the week's lunch ideas (lunch-box
 * ADR-0012): a short shopping list a South African grocer stocks, each idea
 * with the words to search the store for — around the store's own lunchbox
 * shelves when the phone read them (ADR-0013). The instruction says nothing about
 * the family; the one message carries the brief as JSON.
 */
export const IDEAS_SYSTEM = [
  "You draft a South African family's school lunch-box shopping list for one week.",
  'Each child has "open" compartments to fill, counted per kind: main, fruit, veg, snack, treat.',
  'Propose ideas that a supermarket such as Checkers sells: one product kind per idea',
  '("wholewheat wraps", "yoghurt tubs", "baby carrots"), not recipes or brands.',
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
  'Answer with JSON only, in the shape asked for.',
].join('\n');

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
    maxOutputTokens: 4096,
    temperature: 0.6,
    labels: { feature: 'lunchIdeas' },
  };
}
