import { isAllergen, mentions, type Allergen, type ChildFoodRules } from './food_safety';

/**
 * Whether a dinner nobody in the household has cooked before may be proposed
 * (lunch-box ADR-0011). A meal in the family's own library carries no allergen
 * codes (meal-planning ADR-0002 keeps named lines), so a new idea is checked
 * by the words in it: its name and every ingredient against the words each of
 * the household's allergens is known by, for everybody's allergies, and
 * against everybody's free-text allergies.
 *
 * Words are a net, not a guarantee — "sauce" can hide milk — which is why the
 * review says a new idea is to be checked, and why a new idea is only ever a
 * suggestion a parent accepts. What it catches is dropped before anybody sees
 * it; nothing about anybody's allergy is sent to the model to do it.
 */
export const ALLERGEN_WORDS: Readonly<Record<Allergen, readonly string[]>> = {
  peanut: ['peanut', 'groundnut', 'satay'],
  treeNut: [
    'nut',
    'almond',
    'cashew',
    'walnut',
    'pecan',
    'hazelnut',
    'pistachio',
    'macadamia',
    'brazil nut',
    'pesto',
    'praline',
    'marzipan',
  ],
  milk: ['milk', 'cheese', 'butter', 'cream', 'yoghurt', 'yogurt', 'custard', 'feta', 'parmesan'],
  egg: ['egg', 'mayonnaise', 'mayo', 'meringue', 'omelette', 'quiche', 'frittata'],
  wheat: [
    'wheat',
    'flour',
    'bread',
    'pasta',
    'spaghetti',
    'macaroni',
    'noodle',
    'couscous',
    'wrap',
    'pie',
    'pastry',
    'roti',
    'bun',
    'crumb',
  ],
  soy: ['soy', 'soya', 'tofu', 'edamame', 'miso'],
  fish: ['fish', 'hake', 'tuna', 'salmon', 'snoek', 'sardine', 'pilchard', 'anchov', 'haddock'],
  shellfish: ['prawn', 'shrimp', 'crab', 'lobster', 'mussel', 'calamari', 'squid', 'oyster'],
  sesame: ['sesame', 'tahini', 'hummus'],
};

export interface DinnerIdea {
  readonly name: string;
  readonly ingredients: readonly { readonly name: string; readonly quantity: string | null }[];
}

export function isDinnerIdeaSafe(idea: DinnerIdea, everybody: readonly ChildFoodRules[]): boolean {
  const words = new Set<string>();
  for (const rules of everybody) {
    for (const code of rules.avoid) {
      if (!isAllergen(code)) continue;
      for (const word of ALLERGEN_WORDS[code]) words.add(word);
    }
    for (const other of rules.otherAllergies) words.add(other);
  }
  const texts = [idea.name, ...idea.ingredients.map((line) => line.name)];
  return !texts.some((text) => [...words].some((word) => mentions(text, word)));
}
