import type { ChoiceQuestion, NoulQuestion } from '@typesafe-ai/sdk';

import { choiceOf, noulOf, type Answers } from '../ai/decision_call';
import type { DecisionQuestions, DecisionRequest } from '../ai/decision_model';
import { packingInstructions } from './packing_preferences';
import type { WeekBrief, WeekBriefProduct } from './week_brief';
import type { LunchSlot } from './week_documents';

/** What Jev is asked about the store's products (foundation ADR-0021): names, prices, packing lines — never a child. */
export const COMPARTMENTS: Readonly<Record<LunchSlot, string>> = {
  main: 'the main food, such as a sandwich, wrap, roll, pasta or something filling',
  fruit: 'a portion of fruit',
  veg: 'a portion of vegetables',
  snack: 'a small snack, such as yoghurt, crackers, cheese or a muesli bar',
  treat: 'a small Friday treat',
};

export const FIT_QUESTION =
  "Is `product` a good thing to put in a child's school lunch box as `compartment`?";
export const FIT_QUESTION_PACKING =
  "Is `product` a good thing to put in a child's school lunch box as `compartment`, following every line in `packing`?";

export const BOXES_QUESTION =
  "One child's portion goes in each lunch box. How many lunch boxes does one pack of `product` fill? A 6-pack of yoghurts fills 6, a loaf of bread about 8, a bag of apples about 6, a single fruit cup 1.";
export const BOX_COUNTS = [1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 30] as const;

export interface WeekDecisions {
  readonly fit: Readonly<Record<string, number>>;
  readonly boxes: Readonly<Record<string, number>>;
}

export function fitId(product: WeekBriefProduct): string {
  return `fit|${product.ref}`;
}

export function boxesId(product: WeekBriefProduct): string {
  return `boxes|${product.ref}`;
}

export function weekDecisionRequest(brief: WeekBrief): DecisionRequest {
  const packing = packingInstructions(brief.preferences);
  const questions: Record<string, DecisionQuestions[string]> = {};
  for (const product of brief.products) {
    questions[fitId(product)] = fitQuestion(product, packing.length > 0);
    if (product.product.packQuantity === null) questions[boxesId(product)] = boxesQuestion(product);
  }
  return {
    label: 'lunchWeek',
    state: {
      task: "A parent in South Africa is packing a week of children's lunch boxes from products a supermarket has in stock.",
      ...(packing.length > 0 && { packing }),
    },
    questions,
  };
}

export function weekDecisionsFrom(answers: Answers, brief: WeekBrief): WeekDecisions {
  const fit: Record<string, number> = {};
  const boxes: Record<string, number> = {};
  for (const product of brief.products) {
    fit[product.ref] = noulOf(answers, fitId(product)) ?? 0;
    const count = Number(choiceOf(answers, boxesId(product)));
    if (Number.isInteger(count) && count > 0) boxes[product.ref] = count;
  }
  return { fit, boxes };
}

function fitQuestion(product: WeekBriefProduct, withPacking: boolean): NoulQuestion {
  return {
    type: 'noul',
    instructions: {
      question: withPacking ? FIT_QUESTION_PACKING : FIT_QUESTION,
      compartment: COMPARTMENTS[product.slot],
      product: describe(product),
    },
  };
}

function boxesQuestion(product: WeekBriefProduct): ChoiceQuestion {
  return {
    type: 'choice',
    instructions: { question: BOXES_QUESTION, product: describe(product) },
    criteria: Object.fromEntries(
      BOX_COUNTS.map((count) => [
        String(count),
        count === 1 ? 'one lunch box' : `${String(count)} lunch boxes`,
      ]),
    ),
  };
}

function describe({ product }: WeekBriefProduct): Record<string, string> {
  return {
    name: product.name,
    ...(product.brand !== null && product.brand !== '' && { brand: product.brand }),
    price: `R${(product.priceCents / 100).toFixed(2)}`,
    ...(product.isOnPromotion && { promotion: 'on promotion' }),
  };
}
