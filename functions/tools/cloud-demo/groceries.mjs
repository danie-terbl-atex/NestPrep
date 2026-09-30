/**
 * The live grocery list (groceries ADR-0001, ADR-0002): lines people typed,
 * a few bought this morning and still shown struck through, older ones kept
 * as quick-add history, and planned lines the week's meals and lunches asked
 * for — each with the reason the list shows. `keepInStep` is off, so the app
 * never rewrites the planned lines to its own arithmetic.
 */
import { isoWeekOf, writeAll } from './context.mjs';
import { WHO } from './cast.mjs';

const { mom, dad, gran, helper } = WHO;

/** [name, quantity, addedBy, addedHoursAgo, boughtBy?, boughtHoursAgo?] */
const TYPED = [
  ['Milk', '2 l', mom, 20, dad, 3],
  ['Brown bread', '2 loaves', mom, 20, dad, 3],
  ['Nappies — size 4', '1 pack', gran, 26],
  ['Wet wipes', '3 packs', gran, 26],
  ['Toothpaste', null, mom, 8],
  ['Coffee beans', '500 g', dad, 30],
  ['Rooibos tea', null, gran, 5],
  ['Dishwasher tablets', null, helper, 4],
  ['Eggs', '18', mom, 9, mom, 1],
  ['Bananas', null, mom, 9],
  ['Apples', '1 bag', mom, 9],
  ['Yoghurt tubs', '12', mom, 9],
  ['Party balloons', '2 packs', mom, 2],
  ['Birthday candles', '6', gran, 2],
  ['Sunscreen', 'SPF 50', dad, 50],
  ['Maize meal', '5 kg', dad, 90, dad, 70],
  ['Washing powder', null, helper, 120, mom, 96],
];

/** Planned lines: [name, quantity, why]. Lunch lines count boxes, so have no quantity. */
const PLANNED = [
  ['Chicken thighs', '1 kg', 'For Thursday dinner'],
  ['Coconut milk', '1 tin', 'For Thursday dinner'],
  ['Mozzarella', '400 g', 'For Friday dinner'],
  ['Pizza bases', '2 packs', 'For Friday dinner'],
  ['Taco shells', '1 pack', 'For Saturday dinner'],
  ['Avocado', '×2', 'For Saturday dinner'],
  ['Whole chicken', '×1', 'For Sunday lunch'],
  ['Butternut', '×3', 'For Sunday lunch + Sunday dinner'],
  ['Naartjies', null, 'For 3 of Lerato’s lunches'],
  ['Biltong', null, 'For 4 lunches (Lerato, Sipho)'],
];

const slug = (key) => key.replace(/[^\p{L}\p{N}]+/gu, '-').replace(/^-+|-+$/g, '');

export async function seedGroceries(ctx) {
  const { col, ago } = ctx;
  const week = isoWeekOf(ctx.today);
  const docs = TYPED.map(([name, quantity, addedBy, addedAgo, boughtBy = null, boughtAgo]) => [
    col('groceryItems').doc(`demo-${slug(name.toLowerCase())}`),
    {
      name,
      quantity,
      addedBy,
      addedAt: ago(addedAgo),
      boughtBy,
      boughtAt: boughtBy === null ? null : ago(boughtAgo),
      sourceKey: null,
      sourceWeek: null,
      sourceNote: null,
    },
  ]);
  for (const [name, quantity, why] of PLANNED) {
    const key = name.toLowerCase();
    docs.push([
      col('groceryItems').doc(`plan-${week}-${slug(key)}`),
      {
        name,
        quantity,
        addedBy: mom,
        addedAt: ago(6),
        boughtBy: null,
        boughtAt: null,
        sourceKey: key,
        sourceWeek: week,
        sourceNote: why,
      },
    ]);
  }
  docs.push([
    col('grocerySettings').doc('plans'),
    {
      keepInStep: false,
      staples: ['salt', 'olive oil', 'sugar', 'garlic', 'honey'],
      updatedBy: mom,
      updatedAt: ago(200),
    },
  ]);
  await writeAll(ctx.store, docs);
  const bought = TYPED.filter((line) => line[4] !== undefined).length;
  return `groceries: ${String(TYPED.length + PLANNED.length)} lines (${String(bought)} bought, ${String(PLANNED.length)} from plans)`;
}
