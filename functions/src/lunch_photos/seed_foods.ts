import type { LunchSlot } from '../plan_week/week_documents';

export interface SeedFood {
  readonly name: string;
  readonly slot: LunchSlot;
}

/**
 * The library every household starts with, by seed key — a mirror of the
 * app's `LunchSeedCatalogue`, which `seed_foods.test.ts` holds it to. A pick
 * whose item id is `seed-<key>` is one of these foods, so its picture can be
 * shared between households: the prompt names the catalogue's food, never the
 * household's (perhaps renamed) copy of it (lunch-box ADR-0015).
 */
export const SEED_FOODS: Readonly<Record<string, SeedFood>> = {
  'cheese-tomato': { name: 'Cheese and tomato sandwich', slot: 'main' },
  'peanut-butter': { name: 'Peanut butter and jam sandwich', slot: 'main' },
  'chicken-mayo': { name: 'Chicken mayo wrap', slot: 'main' },
  'egg-mayo': { name: 'Egg mayo sandwich', slot: 'main' },
  'tuna-sandwich': { name: 'Tuna sandwich', slot: 'main' },
  'pasta-salad': { name: 'Pasta salad', slot: 'main' },
  frikkadels: { name: 'Mini frikkadels', slot: 'main' },
  'chicken-drumstick': { name: 'Roast chicken drumstick', slot: 'main' },
  'rice-salad': { name: 'Rice and veg salad', slot: 'main' },
  'mealie-bread': { name: 'Mealie bread slice', slot: 'main' },
  'cheese-rolls': { name: 'Cheese rolls', slot: 'main' },
  'hummus-pita': { name: 'Hummus and pita', slot: 'main' },
  apple: { name: 'Apple slices', slot: 'fruit' },
  banana: { name: 'Banana', slot: 'fruit' },
  naartjie: { name: 'Naartjie', slot: 'fruit' },
  grapes: { name: 'Grapes', slot: 'fruit' },
  pear: { name: 'Pear', slot: 'fruit' },
  strawberries: { name: 'Strawberries', slot: 'fruit' },
  mango: { name: 'Mango cubes', slot: 'fruit' },
  watermelon: { name: 'Watermelon wedges', slot: 'fruit' },
  litchis: { name: 'Litchis', slot: 'fruit' },
  'carrot-sticks': { name: 'Carrot sticks', slot: 'veg' },
  cucumber: { name: 'Cucumber rounds', slot: 'veg' },
  'cherry-tomatoes': { name: 'Cherry tomatoes', slot: 'veg' },
  'sugar-snaps': { name: 'Sugar snap peas', slot: 'veg' },
  'baby-corn': { name: 'Baby corn', slot: 'veg' },
  'pepper-strips': { name: 'Sweet pepper strips', slot: 'veg' },
  mielie: { name: 'Mielie on the cob', slot: 'veg' },
  biltong: { name: 'Biltong', slot: 'snack' },
  droewors: { name: 'Droëwors', slot: 'snack' },
  'cheese-cubes': { name: 'Cheese cubes', slot: 'snack' },
  yoghurt: { name: 'Yoghurt tub', slot: 'snack' },
  popcorn: { name: 'Popcorn', slot: 'snack' },
  crackers: { name: 'Crackers and cheese', slot: 'snack' },
  'rice-cakes': { name: 'Rice cakes', slot: 'snack' },
  raisins: { name: 'Raisins', slot: 'snack' },
  pretzels: { name: 'Pretzels', slot: 'snack' },
  'trail-mix': { name: 'Trail mix', slot: 'snack' },
  rusk: { name: 'Rusk', slot: 'treat' },
  'marie-biscuits': { name: 'Marie biscuits', slot: 'treat' },
  muffin: { name: 'Banana muffin', slot: 'treat' },
  crunchie: { name: 'Oat crunchie', slot: 'treat' },
  chocolate: { name: 'Small chocolate', slot: 'treat' },
  jelly: { name: 'Jelly sweets', slot: 'treat' },
  koeksister: { name: 'Mini koeksister', slot: 'treat' },
};

export const SEED_ITEM_PREFIX = 'seed-';
