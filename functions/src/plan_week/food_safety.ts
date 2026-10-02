/**
 * What must stay out of one child's box, and what they would rather not have —
 * the server's copy of the app's `FoodRules.mustAvoid` and `LunchSafety`, and
 * of the rules' `lunchAvoidFor` (lunch-box ADR-0001).
 *
 * Planning a week applies it to the model's ideas and to every store product
 * before the model sees it, and to every choice after (`child_exclusion.ts`,
 * lunch-box ADR-0012). The rules check again when the plan is written, and
 * theirs is the answer that counts (BE-20). No allergy is sent to the model;
 * likes and dislikes are, as words under a placeholder.
 */

export const ALLERGENS = [
  'peanut',
  'treeNut',
  'milk',
  'egg',
  'wheat',
  'soy',
  'fish',
  'shellfish',
  'sesame',
] as const;
export type Allergen = (typeof ALLERGENS)[number];

const NUTS: readonly Allergen[] = ['peanut', 'treeNut'];

export function isAllergen(code: string): code is Allergen {
  return (ALLERGENS as readonly string[]).includes(code);
}

/** One child's food rules, reduced to what planning a box needs. */
export interface ChildFoodRules {
  /** Allergen codes that must not be in their box — nuts included when ruled out. */
  readonly avoid: ReadonlySet<string>;
  /** Free-text allergies ("kiwi") — matched against an item's name. */
  readonly otherAllergies: readonly string[];
  readonly likes: readonly string[];
  readonly dislikes: readonly string[];
}

export interface StoredFoodFacts {
  readonly allergyCodes: readonly string[];
  readonly otherAllergies: readonly string[];
  readonly diet: readonly string[];
  readonly schoolIsNutFree: boolean;
  readonly likes: readonly string[];
  readonly dislikes: readonly string[];
}

/**
 * Their allergies, and both nuts when nuts are ruled out for them by an
 * allergy, their diet or their school — exactly `lunchAvoidFor`.
 */
export function foodRulesFrom(facts: StoredFoodFacts): ChildFoodRules {
  const avoid = new Set(facts.allergyCodes);
  const isNutFree =
    facts.allergyCodes.some((code) => (NUTS as readonly string[]).includes(code)) ||
    facts.diet.includes('nutFree') ||
    facts.schoolIsNutFree;
  if (isNutFree) for (const nut of NUTS) avoid.add(nut);
  return {
    avoid,
    otherAllergies: facts.otherAllergies,
    likes: facts.likes,
    dislikes: facts.dislikes,
  };
}

/**
 * Whether [name] is what [word] names — the app's `LunchSafety.mentions`: the
 * word's stem at the start of a word in the name, case and spacing ignored.
 */
export function mentions(name: string, word: string): boolean {
  const stem = stemOf(normalised(word));
  if (stem.length < 3) return false;
  return new RegExp(`\\b${escapeRegExp(stem)}`).test(normalised(name));
}

export function normalised(text: string): string {
  return text.trim().toLowerCase().replace(/\s+/g, ' ');
}

function stemOf(word: string): string {
  for (const [ending, longerThan] of [
    ['ies', 4],
    ['ie', 4],
    ['es', 4],
    ['y', 4],
  ] as const) {
    if (word.endsWith(ending) && word.length > longerThan) {
      return word.slice(0, word.length - ending.length);
    }
  }
  if (word.endsWith('s') && !word.endsWith('ss') && word.length > 3) return word.slice(0, -1);
  return word;
}

function escapeRegExp(text: string): string {
  return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
