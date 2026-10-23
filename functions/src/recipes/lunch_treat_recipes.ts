import type { Recipe } from './recipe';

/**
 * Lunch-box treats NestPrep publishes (recipes ADR-0001). Auto-fill and the
 * starter boxes pack a treat on Fridays only (lunch-box ADR-0003, ADR-0020).
 * Banana oat bites are the treat a nut-, egg- and milk-free box can keep.
 */
export const LUNCH_TREAT_RECIPES: readonly Recipe[] = [
  {
    id: 'banana-oat-bites',
    name: 'Banana oat bites',
    summary: 'Soft baked bites of mashed banana, oats and raisins — sweet with no added sugar.',
    about: null,
    cuisine: 'international',
    contexts: ['lunchBox'],
    placement: { lunchBox: 'treat' },
    tags: [],
    allergens: [],
    dietTags: ['vegetarian', 'vegan'],
    ingredients: [
      { name: 'Ripe bananas', quantity: 2, unit: null, note: 'mashed', group: null },
      { name: 'Rolled oats', quantity: 1, unit: 'cup', note: null, group: null },
      { name: 'Raisins', quantity: 0.25, unit: 'cup', note: null, group: null },
      { name: 'Ground cinnamon', quantity: 0.5, unit: 'tsp', note: null, group: null },
    ],
    steps: [
      'Heat the oven to 180 °C and line a tray with baking paper.',
      'Mix everything together and leave it for five minutes to soften.',
      'Drop teaspoons onto the tray and bake for 15 minutes; cool on the tray.',
    ],
    servings: 16,
    prepMinutes: 10,
    cookMinutes: 15,
    difficulty: 'easy',
    prepAhead: true,
    prepNote: 'Bake on Sunday; they keep four days in a tin.',
    photo: null,
  },
  {
    id: 'apple-crumble-muffins',
    name: 'Apple crumble muffins',
    summary: 'Cinnamon apple muffins with an oat crumble on top.',
    about: null,
    cuisine: 'international',
    contexts: ['lunchBox'],
    placement: { lunchBox: 'treat' },
    tags: [],
    allergens: ['milk', 'egg', 'wheat'],
    dietTags: ['vegetarian'],
    ingredients: [
      { name: 'Cake flour', quantity: 2, unit: 'cup', note: null, group: null },
      { name: 'Baking powder', quantity: 2, unit: 'tsp', note: null, group: null },
      { name: 'Brown sugar', quantity: 0.5, unit: 'cup', note: null, group: null },
      { name: 'Ground cinnamon', quantity: 1, unit: 'tsp', note: null, group: null },
      { name: 'Eggs', quantity: 2, unit: null, note: null, group: null },
      { name: 'Milk', quantity: 0.75, unit: 'cup', note: null, group: null },
      {
        name: 'Melted butter',
        quantity: 80,
        unit: 'g',
        note: 'plus 2 tbsp for the crumble',
        group: null,
      },
      { name: 'Apples', quantity: 2, unit: null, note: 'peeled and grated', group: null },
      { name: 'Rolled oats', quantity: 0.25, unit: 'cup', note: 'for the crumble', group: null },
    ],
    steps: [
      'Heat the oven to 180 °C and line a muffin tray.',
      'Mix the flour, baking powder, most of the sugar and the cinnamon.',
      'Whisk the eggs, milk and butter, stir them in with the apple, and fill the cups.',
      'Rub the oats with the rest of the sugar and butter, sprinkle on top, and bake for 20 minutes.',
    ],
    servings: 12,
    prepMinutes: 15,
    cookMinutes: 20,
    difficulty: 'easy',
    prepAhead: true,
    prepNote: 'Bake a dozen on Sunday; freeze what the week will not eat.',
    photo: null,
  },
];
