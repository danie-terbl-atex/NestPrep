import { allergensMentionedIn } from './allergen_words';
import { ALLERGENS, mentions, type Allergen, type ChildFoodRules } from './food_safety';

/**
 * Why something may not go in one child's box (lunch-box ADR-0012), or null
 * when it may: an allergen code it carries or its words name, a free-text
 * allergy it names, or something the child said no to. The reason travels
 * back to the phone, which says it beside the child's name — the model never
 * hears any of it.
 */
export interface Exclusion {
  readonly reason: 'allergy' | 'dislike';
  /** The allergen code, or null for a free-text allergy or a dislike. */
  readonly allergen: Allergen | null;
}

export function exclusionFor(
  rules: ChildFoodRules,
  text: string,
  knownCodes: readonly string[] = [],
): Exclusion | null {
  const named = new Set<string>([...knownCodes, ...allergensMentionedIn(text)]);
  const allergen = ALLERGENS.find((code) => named.has(code) && rules.avoid.has(code));
  if (allergen !== undefined) return { reason: 'allergy', allergen };
  if (rules.otherAllergies.some((allergy) => mentions(text, allergy))) {
    return { reason: 'allergy', allergen: null };
  }
  if (rules.dislikes.some((dislike) => mentions(text, dislike))) {
    return { reason: 'dislike', allergen: null };
  }
  return null;
}

/** Whether a child has any allergy at all — then a product nobody can read is not offered. */
export function hasAnyAllergy(rules: ChildFoodRules): boolean {
  return rules.avoid.size > 0 || rules.otherAllergies.length > 0;
}
