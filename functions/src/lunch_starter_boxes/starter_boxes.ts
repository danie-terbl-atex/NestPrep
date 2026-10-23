import type { StarterBoxSource } from './starter_box';

/**
 * The ready-made boxes *Fill the week* offers (lunch-box ADR-0018, ADR-0020),
 * in the order they are shown. Every box has a treat, packed on Fridays only;
 * *Dip and crunch* leaves veg out because its snack is veg sticks, so
 * NestPrep fills that compartment. *Nut, egg and dairy free* holds nothing with peanut,
 * tree nut, egg or milk.
 */
export const STARTER_BOXES: readonly StarterBoxSource[] = [
  {
    id: 'classic-sandwich',
    name: 'Classic sandwich box',
    blurb: 'Egg and cheese sandwich, apple, carrot sticks, popcorn and a crumble muffin.',
    order: 1,
    picks: {
      main: { kind: 'recipe', recipeId: 'egg-and-cheese-sandwich' },
      fruit: { kind: 'quickPick', seedKey: 'apple' },
      veg: { kind: 'quickPick', seedKey: 'carrot-sticks' },
      snack: { kind: 'recipe', recipeId: 'homemade-popcorn' },
      treat: { kind: 'recipe', recipeId: 'apple-crumble-muffins' },
    },
  },
  {
    id: 'wrap-it-up',
    name: 'Wrap it up',
    blurb: 'Chicken and mayo wrap, naartjie, cherry tomatoes, cheese cubes and a Marie biscuit.',
    order: 2,
    picks: {
      main: { kind: 'recipe', recipeId: 'chicken-mayo-wrap' },
      fruit: { kind: 'quickPick', seedKey: 'naartjie' },
      veg: { kind: 'quickPick', seedKey: 'cherry-tomatoes' },
      snack: { kind: 'quickPick', seedKey: 'cheese-cubes' },
      treat: { kind: 'quickPick', seedKey: 'marie-biscuits' },
    },
  },
  {
    id: 'nut-egg-dairy-free',
    name: 'Nut, egg and dairy free',
    blurb: 'Roast chicken, banana, sugar snaps, popcorn and banana oat bites.',
    order: 3,
    picks: {
      main: { kind: 'quickPick', seedKey: 'chicken-drumstick' },
      fruit: { kind: 'quickPick', seedKey: 'banana' },
      veg: { kind: 'quickPick', seedKey: 'sugar-snaps' },
      snack: { kind: 'recipe', recipeId: 'homemade-popcorn' },
      treat: { kind: 'recipe', recipeId: 'banana-oat-bites' },
    },
  },
  {
    id: 'sunday-bake',
    name: 'Sunday bake box',
    blurb: 'Pasta salad, strawberries, pepper strips, cheese and corn muffins, and oat bites.',
    order: 4,
    picks: {
      main: { kind: 'recipe', recipeId: 'veggie-pasta-salad' },
      fruit: { kind: 'quickPick', seedKey: 'strawberries' },
      veg: { kind: 'quickPick', seedKey: 'pepper-strips' },
      snack: { kind: 'recipe', recipeId: 'cheese-corn-muffins' },
      treat: { kind: 'recipe', recipeId: 'banana-oat-bites' },
    },
  },
  {
    id: 'dip-and-crunch',
    name: 'Dip and crunch',
    blurb: 'Rice and veg salad, mango, hummus with veg sticks, and a rusk.',
    order: 5,
    picks: {
      main: { kind: 'quickPick', seedKey: 'rice-salad' },
      fruit: { kind: 'quickPick', seedKey: 'mango' },
      snack: { kind: 'recipe', recipeId: 'hummus-veg-sticks' },
      treat: { kind: 'quickPick', seedKey: 'rusk' },
    },
  },
];
