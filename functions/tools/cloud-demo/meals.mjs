/**
 * The meal library and this week's and next week's plan (meal planning
 * ADR-0001). A plan is keyed by its Monday and maps `{day}_{meal}` to a meal
 * id; ingredients carry an amount and a unit only where a shop would.
 */
import { writeAll } from './context.mjs';
import { WHO } from './cast.mjs';

const { mom, dad, gran } = WHO;

/** [id, name, addedBy, ingredients as [name, amount?, unit?]] */
const MEALS = [
  [
    'bolognese',
    'Spaghetti bolognese',
    mom,
    [
      ['Beef mince', 500, 'g'],
      ['Spaghetti', 1, 'pack'],
      ['Chopped tomatoes', 2, 'tin'],
      ['Onion', 2],
      ['Garlic'],
      ['Cheddar', 200, 'g'],
    ],
  ],
  [
    'bobotie',
    'Bobotie with yellow rice',
    gran,
    [
      ['Beef mince', 1, 'kg'],
      ['Eggs', 2],
      ['Milk', 250, 'ml'],
      ['Bread', 1, 'loaf'],
      ['Chutney', 1, 'bottle'],
      ['Rice', 500, 'g'],
      ['Turmeric', 1, 'tsp'],
      ['Raisins', 100, 'g'],
    ],
  ],
  [
    'braai',
    'Braai with pap and chakalaka',
    dad,
    [
      ['Boerewors', 1, 'kg'],
      ['Lamb chops', 800, 'g'],
      ['Maize meal', 1, 'kg'],
      ['Chakalaka', 2, 'tin'],
      ['Charcoal', 1, 'pack'],
    ],
  ],
  [
    'chicken-stir-fry',
    'Chicken stir-fry',
    mom,
    [
      ['Chicken breasts', 600, 'g'],
      ['Stir-fry veg', 2, 'pack'],
      ['Soy sauce', 3, 'tbsp'],
      ['Egg noodles', 1, 'pack'],
    ],
  ],
  [
    'fish-fingers',
    'Fish fingers, mash and peas',
    mom,
    [
      ['Fish fingers', 1, 'pack'],
      ['Potatoes', 2, 'kg'],
      ['Frozen peas', 1, 'pack'],
      ['Butter', 1, 'tbsp'],
    ],
  ],
  [
    'chicken-curry',
    'Mild chicken curry',
    gran,
    [
      ['Chicken thighs', 1, 'kg'],
      ['Coconut milk', 1, 'tin'],
      ['Curry paste', 2, 'tbsp'],
      ['Rice', 500, 'g'],
      ['Onion', 1],
    ],
  ],
  [
    'pizza',
    'Homemade pizza night',
    dad,
    [
      ['Pizza bases', 2, 'pack'],
      ['Mozzarella', 400, 'g'],
      ['Tomato paste', 1, 'tin'],
      ['Ham', 200, 'g'],
      ['Pineapple', 1, 'tin'],
    ],
  ],
  [
    'potjie',
    'Chicken potjie',
    dad,
    [
      ['Chicken pieces', 1.5, 'kg'],
      ['Potatoes', 1, 'kg'],
      ['Carrots', 500, 'g'],
      ['Baby marrows', 250, 'g'],
      ['Chicken stock', 500, 'ml'],
    ],
  ],
  [
    'tacos',
    'Beef tacos',
    mom,
    [
      ['Beef mince', 500, 'g'],
      ['Taco shells', 1, 'pack'],
      ['Lettuce', 1],
      ['Avocado', 2],
      ['Sour cream', 250, 'ml'],
    ],
  ],
  [
    'roast-chicken',
    'Sunday roast chicken',
    gran,
    [
      ['Whole chicken', 1],
      ['Potatoes', 1, 'kg'],
      ['Butternut', 1],
      ['Gravy powder', 1, 'pack'],
    ],
  ],
  [
    'mac-cheese',
    'Mac and cheese',
    mom,
    [
      ['Macaroni', 500, 'g'],
      ['Cheddar', 300, 'g'],
      ['Milk', 500, 'ml'],
      ['Butter', 2, 'tbsp'],
    ],
  ],
  [
    'soup',
    'Butternut soup and toast',
    gran,
    [
      ['Butternut', 2],
      ['Onion', 1],
      ['Vegetable stock', 1, 'l'],
      ['Bread', 1, 'loaf'],
    ],
  ],
  ['oats', 'Oats with banana', mom, [['Rolled oats', 1, 'kg'], ['Bananas', 6], ['Honey']]],
  [
    'flapjacks',
    'Flapjacks',
    dad,
    [
      ['Cake flour', 500, 'g'],
      ['Eggs', 3],
      ['Milk', 500, 'ml'],
      ['Golden syrup', 1, 'bottle'],
    ],
  ],
  [
    'eggs-toast',
    'Scrambled eggs on toast',
    dad,
    [
      ['Eggs', 6],
      ['Bread', 1, 'loaf'],
      ['Butter', 1, 'tbsp'],
    ],
  ],
  [
    'bunny-chow',
    'Bean bunny chow',
    mom,
    [
      ['Sugar beans', 2, 'tin'],
      ['Bread', 2, 'loaf'],
      ['Curry paste', 2, 'tbsp'],
      ['Potatoes', 500, 'g'],
    ],
  ],
  [
    'toasted-sarmies',
    'Toasted cheese sarmies',
    mom,
    [
      ['Bread', 1, 'loaf'],
      ['Cheddar', 200, 'g'],
      ['Tomatoes', 3],
    ],
  ],
];

/** Two weeks of slots: this week, then next. */
const PLAN = [
  {
    '1_dinner': 'bolognese',
    '2_dinner': 'chicken-stir-fry',
    '3_dinner': 'fish-fingers',
    '4_dinner': 'chicken-curry',
    '5_dinner': 'pizza',
    '6_breakfast': 'flapjacks',
    '6_lunch': 'toasted-sarmies',
    '6_dinner': 'tacos',
    '7_breakfast': 'eggs-toast',
    '7_lunch': 'roast-chicken',
    '7_dinner': 'soup',
  },
  {
    '1_breakfast': 'oats',
    '1_dinner': 'bobotie',
    '2_dinner': 'mac-cheese',
    '3_dinner': 'bunny-chow',
    '4_dinner': 'chicken-stir-fry',
    '5_dinner': 'braai',
    '6_breakfast': 'flapjacks',
    '6_dinner': 'pizza',
    '7_lunch': 'potjie',
    '7_dinner': 'soup',
  },
];

export const mealId = (id) => `demo-${id}`;

/** The meals of [week] (0 this, 1 next), for the grocery list's planned lines. */
export function plannedMeals(week) {
  return Object.entries(PLAN[week]).map(([slot, id]) => ({
    slot,
    meal: MEALS.find(([candidate]) => candidate === id),
  }));
}

export async function seedMeals(ctx) {
  const { day, at, col } = ctx;
  const docs = MEALS.map(([id, name, addedBy, ingredients]) => [
    col('meals').doc(mealId(id)),
    {
      name,
      nameKey: name.toLowerCase(),
      addedBy,
      createdAt: at(day(-21), '19:00'),
      ingredients: ingredients.map(([ingredient, amount, unit]) => ({
        name: ingredient,
        ...(amount === undefined ? {} : { amount }),
        ...(unit === undefined ? {} : { unit }),
      })),
    },
  ]);
  PLAN.forEach((slots, week) => {
    docs.push([
      col('mealPlans').doc(day(week * 7)),
      { slots: Object.fromEntries(Object.entries(slots).map(([slot, id]) => [slot, mealId(id)])) },
    ]);
  });
  await writeAll(ctx.store, docs);
  return `meals: ${String(MEALS.length)} in the library, ${String(PLAN.reduce((n, slots) => n + Object.keys(slots).length, 0))} planned slots over 2 weeks`;
}
