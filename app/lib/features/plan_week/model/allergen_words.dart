import '../../family_profiles/model/allergen.dart';
import '../../lunch_box/model/lunch_safety.dart';

/// The words that name each allergen in a shop's text (lunch-box ADR-0012):
/// a product's name, its *Allergens* line and its *Ingredients* line, and a
/// lunch idea's own words. The server holds the same lists
/// (`functions/src/plan_week/allergen_words.ts`) and a test reads both.
///
/// They over-match on purpose — "butter" in peanut butter counts as milk —
/// because a safe thing left out costs a swap, and an unsafe thing let in
/// costs a child. "May contain" counts as contains for the same reason.
abstract final class AllergenWords {
  static const byAllergen = <Allergen, List<String>>{
    Allergen.peanut: ['peanut', 'groundnut'],
    Allergen.treeNut: [
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
    Allergen.milk: [
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
    Allergen.egg: ['egg', 'mayonnaise', 'mayo'],
    Allergen.wheat: [
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
    Allergen.soy: ['soy', 'soya'],
    Allergen.fish: [
      'fish',
      'tuna',
      'salmon',
      'pilchard',
      'sardine',
      'hake',
      'anchovy',
    ],
    Allergen.shellfish: [
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
    Allergen.sesame: ['sesame', 'tahini', 'hummus'],
  };

  /// Every allergen whose words [text] mentions, matched the way the lunch
  /// library matches a dislike (`LunchSafety.mentions`).
  static Set<Allergen> mentionedIn(String text) => {
    for (final MapEntry(key: allergen, value: words) in byAllergen.entries)
      if (words.any((word) => LunchSafety.mentions(text, word))) allergen,
  };
}
