import type { NoulQuestion } from '@typesafe-ai/sdk';

import { noulOf, type Answers } from '../ai/decision_call';
import type { DecisionRequest } from '../ai/decision_model';
import type { RankProductMatchesInput } from './schemas';

export const MATCH_STATE =
  'A household member is buying the items on their grocery list from the Checkers Sixty60 grocery catalogue.';

export const BUYING_RULES: readonly string[] = [
  'Pick the plain, everyday form of the item unless the item asks for something more specific.',
  'Do not pick a flavoured, sweetened, crumbed, marinated or ready-meal version unless the item asks for one.',
  'Pick a fresh product over a processed one unless the item names a tinned or frozen form.',
  'If the item names a brand, pick a product of that brand.',
  'A product that only contains the item is not the item: basil pesto is not basil.',
];

export const MATCH_QUESTION =
  'Is `product` the `grocery_item` the shopper should buy, following every rule in `buying_rules`?';

export interface RankedMatch {
  readonly productId: string;
  readonly fit: number;
}

export function matchId(index: number): string {
  return `p${String(index)}`;
}

export function matchRequest(input: RankProductMatchesInput): DecisionRequest {
  return {
    label: 'productMatch',
    state: MATCH_STATE,
    questions: Object.fromEntries(
      input.products.map((product, index): [string, NoulQuestion] => [
        matchId(index),
        {
          type: 'noul',
          instructions: {
            question: MATCH_QUESTION,
            grocery_item: input.item,
            product: {
              name: product.name,
              ...(product.brand !== null && product.brand !== '' && { brand: product.brand }),
              price: `R${(product.priceCents / 100).toFixed(2)}`,
            },
            buying_rules: [...BUYING_RULES],
          },
        },
      ]),
    ),
  };
}

/** Best first; equal scores keep the shop's order. */
export function rankedFrom(answers: Answers, input: RankProductMatchesInput): RankedMatch[] {
  return input.products
    .map((product, index) => ({
      productId: product.productId,
      fit: noulOf(answers, matchId(index)) ?? 0,
      index,
    }))
    .sort((a, b) => b.fit - a.fit || a.index - b.index)
    .map(({ productId, fit }) => ({ productId, fit }));
}
