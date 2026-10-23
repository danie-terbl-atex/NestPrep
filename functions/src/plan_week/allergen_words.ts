import { ALLERGENS, mentions, normalised, type Allergen } from './food_safety';

/**
 * The words each allergen code is known by in a shop's text (lunch-box
 * ADR-0012): an idea the model drafts and a product the phone found are read
 * for these. The app holds the same table in `allergen_words.dart`, and
 * `allergen_words_match_the_app.test.ts` keeps the two equal.
 *
 * Over-matching is deliberate — "butter" in peanut butter counts as milk, a
 * bare "nut" counts as a tree nut — because a safe product left out costs a
 * swap, and an unsafe one let in costs a child.
 *
 * "wholewheat" and "tortilla" are wheat for a dish's ingredients (lunch-box
 * ADR-0021): "wholewheat" never reads as a word starting "wheat", and a
 * tortilla is a wrap by another name.
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
    'tortilla',
    'wholewheat',
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

/**
 * Whole-word food names that contain an allergen word but never the allergen
 * (recipes ADR-0004): taken out of the text before the words are read, so
 * butternut squash is not milk and nutmeg is not a tree nut. Everything else
 * in the text still counts — "peanut butter" is still milk. Reviewed as a
 * safety change; never coconut, pine nut or anything a shop might make with
 * the allergen. The app holds the same list, and the same test reads both.
 */
export const NOT_ALLERGEN_PHRASES: readonly string[] = [
  'butternut',
  'butter bean',
  'butter beans',
  'nutmeg',
  'cream of tartar',
  'cream soda',
];

/** Every allergen code whose words [text] mentions. */
export function allergensMentionedIn(text: string): Allergen[] {
  const read = withoutNotAllergenPhrases(text);
  return ALLERGENS.filter((code) => ALLERGEN_WORDS[code].some((word) => mentions(read, word)));
}

function withoutNotAllergenPhrases(text: string): string {
  return NOT_ALLERGEN_PHRASES.reduce(
    (read, phrase) => read.replace(new RegExp(`\\b${phrase}\\b`, 'g'), ' '),
    normalised(text),
  );
}
