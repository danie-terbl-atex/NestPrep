/**
 * The lunch box's money and cupboard (lunch-box ADR-0006 pantry, ADR-0007
 * budget, ADR-0009 prep): this week's Sunday-prep ticks, what things cost and
 * for how many boxes, the weekly budget, and the pantry, with the pretzels
 * nearly gone and the droëwors out. Ids are the library's
 * (`seed-{key}`), which `lunch.mjs` writes.
 */
import { isoWeekOf, writeAll } from './context.mjs';
import { WHO } from './cast.mjs';

const { mom } = WHO;

/** [item key, rands, portions] */
const PRICES = [
  ['biltong', 89, 8],
  ['droewors', 65, 6],
  ['naartjie', 35, 10],
  ['apple', 30, 8],
  ['grapes', 45, 6],
  ['banana', 25, 7],
  ['strawberries', 40, 4],
  ['mango', 38, 4],
  ['cheese-cubes', 70, 10],
  ['yoghurt', 55, 6],
  ['popcorn', 20, 10],
  ['rice-cakes', 32, 8],
  ['pretzels', 28, 6],
  ['crackers', 45, 8],
  ['chicken-mayo', 110, 6],
  ['pasta-salad', 60, 6],
  ['cheese-rolls', 48, 6],
  ['carrot-sticks', 18, 6],
  ['jelly', 22, 6],
  ['marie-biscuits', 20, 10],
];

/** [item key, boxes' worth left] */
const PANTRY = [
  ['popcorn', 6],
  ['rice-cakes', 5],
  ['raisins', 8],
  ['pretzels', 2],
  ['crackers', 4],
  ['biltong', 3],
  ['droewors', 0],
  ['jelly', 7],
  ['marie-biscuits', 9],
  ['cheese-cubes', 3],
];

const PREPPED = ['rice-salad', 'frikkadels', 'pasta-salad', 'carrot-sticks', 'popcorn'];

export async function seedLunchStock(ctx) {
  const { day, at, col } = ctx;
  const id = (key) => `seed-${key}`;
  const docs = [[col('lunchPrep').doc(isoWeekOf(ctx.today)), { done: PREPPED.map(id) }]];
  for (const [key, rands, portions] of PRICES) {
    docs.push([
      col('lunchPrices').doc(id(key)),
      {
        cents: rands * 100,
        portions,
        currency: 'ZAR',
        updatedBy: mom,
        updatedAt: at(day(-6), '18:00'),
      },
    ]);
  }
  docs.push([
    col('lunchBudget').doc('weekly'),
    { cents: 35000, currency: 'ZAR', updatedBy: mom, updatedAt: at(day(-14), '18:00') },
  ]);
  for (const [key, portions] of PANTRY) {
    docs.push([
      col('lunchPantry').doc(id(key)),
      { portions, updatedBy: mom, updatedAt: at(day(-1), '17:00') },
    ]);
  }
  await writeAll(ctx.store, docs);
  return `lunch stock: ${String(PREPPED.length)} prep ticks, ${String(PRICES.length)} prices, R350 weekly budget, ${String(PANTRY.length)} pantry lines`;
}
