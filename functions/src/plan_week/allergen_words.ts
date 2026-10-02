import { ALLERGENS, mentions, type Allergen } from './food_safety';

/**
 * The words each allergen code is known by in a shop's text (lunch-box
 * ADR-0012): an idea the model drafts and a product the phone found are read
 * for these. The app holds the same table in `allergen_words.dart`, and
 * `allergen_words_match_the_app.test.ts` keeps the two equal.
 *
 * Over-matching is deliberate — "butter" in peanut butter counts as milk, a
 * bare "nut" counts as a tree nut — because a safe product left out costs a
 * swap, and an unsafe one let in costs a child.
 */
export const ALLERGEN_WORDS: Readonly<Record<Allergen, readonly string[]>> = {
  peanut: ['peanut', 'groundnut'],
  treeNut: [
    'almond',
    'cashew',
    'walnut',
    'hazelnut',
    'pecan',
    'pistachio',
    'macadamia',
    'brazil nut',
    'tree nut',
    'nut',
  ],
  milk: [
    'milk',
    'cheese',
    'yoghurt',
    'yogurt',
    'butter',
    'cream',
    'dairy',
    'whey',
    'lactose',
    'casein',
  ],
  egg: ['egg', 'mayonnaise', 'mayo'],
  wheat: [
    'wheat',
    'gluten',
    'flour',
    'bread',
    'wrap',
    'pasta',
    'biscuit',
    'cracker',
    'rusk',
    'muffin',
    'couscous',
  ],
  soy: ['soy', 'soya'],
  fish: ['fish', 'tuna', 'salmon', 'pilchard', 'sardine', 'hake', 'anchovy'],
  shellfish: [
    'shellfish',
    'prawn',
    'shrimp',
    'crab',
    'lobster',
    'mussel',
    'oyster',
    'calamari',
    'squid',
    'crustacean',
    'mollusc',
  ],
  sesame: ['sesame', 'tahini', 'hummus'],
};

/** Every allergen code whose words [text] mentions. */
export function allergensMentionedIn(text: string): Allergen[] {
  return ALLERGENS.filter((code) => ALLERGEN_WORDS[code].some((word) => mentions(text, word)));
}
