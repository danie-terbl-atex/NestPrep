import type { Allergen } from '../plan_week/food_safety';
import type { LunchSlot } from '../plan_week/week_documents';

export interface SeedFood {
  readonly name: string;
  readonly slot: LunchSlot;
  /** What it usually contains, in `ALLERGENS` order — the codes its `seed-<key>` item starts with. */
  readonly allergens: readonly Allergen[];
}

/**
 * The library every household starts with, by seed key — a mirror of the
 * app's `LunchSeedCatalogue`, which `seed_foods.test.ts` holds it to. A pick
 * whose item id is `seed-<key>` is one of these foods, so its picture can be
 * shared between households: the prompt names the catalogue's food, never the
 * household's (perhaps renamed) copy of it (lunch-box ADR-0015). A starter
 * box's quick pick copies its name and codes from here (lunch-box ADR-0018).
 */
export const SEED_FOODS: Readonly<Record<string, SeedFood>> = {
  'cheese-tomato': {
    name: 'Cheese and tomato sandwich',
    slot: 'main',
    allergens: ['milk', 'wheat', 'soy'],
  },
  'peanut-butter': {
    name: 'Peanut butter and jam sandwich',
    slot: 'main',
    allergens: ['peanut', 'wheat', 'soy'],
  },
  'chicken-mayo': { name: 'Chicken mayo wrap', slot: 'main', allergens: ['egg', 'wheat'] },
  'egg-mayo': { name: 'Egg mayo sandwich', slot: 'main', allergens: ['egg', 'wheat', 'soy'] },
  'tuna-sandwich': {
    name: 'Tuna sandwich',
    slot: 'main',
    allergens: ['egg', 'wheat', 'soy', 'fish'],
  },
  'pasta-salad': { name: 'Pasta salad', slot: 'main', allergens: ['egg', 'wheat'] },
  frikkadels: { name: 'Mini frikkadels', slot: 'main', allergens: ['egg', 'wheat'] },
  'chicken-drumstick': { name: 'Roast chicken drumstick', slot: 'main', allergens: [] },
  'rice-salad': { name: 'Rice and veg salad', slot: 'main', allergens: [] },
  'mealie-bread': { name: 'Mealie bread slice', slot: 'main', allergens: ['milk', 'egg', 'wheat'] },
  'cheese-rolls': { name: 'Cheese rolls', slot: 'main', allergens: ['milk', 'wheat'] },
  'hummus-pita': { name: 'Hummus and pita', slot: 'main', allergens: ['wheat', 'sesame'] },
  apple: { name: 'Apple slices', slot: 'fruit', allergens: [] },
  banana: { name: 'Banana', slot: 'fruit', allergens: [] },
  naartjie: { name: 'Naartjie', slot: 'fruit', allergens: [] },
  grapes: { name: 'Grapes', slot: 'fruit', allergens: [] },
  pear: { name: 'Pear', slot: 'fruit', allergens: [] },
  strawberries: { name: 'Strawberries', slot: 'fruit', allergens: [] },
  mango: { name: 'Mango cubes', slot: 'fruit', allergens: [] },
  watermelon: { name: 'Watermelon wedges', slot: 'fruit', allergens: [] },
  litchis: { name: 'Litchis', slot: 'fruit', allergens: [] },
  'carrot-sticks': { name: 'Carrot sticks', slot: 'veg', allergens: [] },
  cucumber: { name: 'Cucumber rounds', slot: 'veg', allergens: [] },
  'cherry-tomatoes': { name: 'Cherry tomatoes', slot: 'veg', allergens: [] },
  'sugar-snaps': { name: 'Sugar snap peas', slot: 'veg', allergens: [] },
  'baby-corn': { name: 'Baby corn', slot: 'veg', allergens: [] },
  'pepper-strips': { name: 'Sweet pepper strips', slot: 'veg', allergens: [] },
  mielie: { name: 'Mielie on the cob', slot: 'veg', allergens: [] },
  biltong: { name: 'Biltong', slot: 'snack', allergens: [] },
  droewors: { name: 'Droëwors', slot: 'snack', allergens: [] },
  'cheese-cubes': { name: 'Cheese cubes', slot: 'snack', allergens: ['milk'] },
  yoghurt: { name: 'Yoghurt tub', slot: 'snack', allergens: ['milk'] },
  popcorn: { name: 'Popcorn', slot: 'snack', allergens: [] },
  crackers: { name: 'Crackers and cheese', slot: 'snack', allergens: ['milk', 'wheat'] },
  'rice-cakes': { name: 'Rice cakes', slot: 'snack', allergens: [] },
  raisins: { name: 'Raisins', slot: 'snack', allergens: [] },
  pretzels: { name: 'Pretzels', slot: 'snack', allergens: ['wheat'] },
  'trail-mix': { name: 'Trail mix', slot: 'snack', allergens: ['peanut', 'treeNut'] },
  rusk: { name: 'Rusk', slot: 'treat', allergens: ['milk', 'egg', 'wheat'] },
  'marie-biscuits': { name: 'Marie biscuits', slot: 'treat', allergens: ['milk', 'wheat'] },
  muffin: { name: 'Banana muffin', slot: 'treat', allergens: ['milk', 'egg', 'wheat'] },
  crunchie: { name: 'Oat crunchie', slot: 'treat', allergens: ['milk', 'wheat'] },
  chocolate: { name: 'Small chocolate', slot: 'treat', allergens: ['milk', 'soy'] },
  jelly: { name: 'Jelly sweets', slot: 'treat', allergens: [] },
  koeksister: { name: 'Mini koeksister', slot: 'treat', allergens: ['milk', 'wheat'] },
};

export const SEED_ITEM_PREFIX = 'seed-';
