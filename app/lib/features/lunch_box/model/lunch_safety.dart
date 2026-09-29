import '../../../shared/text/normalised_name.dart';
import '../../family_profiles/model/allergen.dart';
import '../../family_profiles/model/food_rules.dart';
import 'lunch_concern.dart';

/// What one child's food rules say about one thing for their box
/// (lunch-box ADR-0001) — `FoodRules.mustAvoid` applied, plus their
/// dislikes. The same answer the rules give for safety: an allergen the child
/// reacts to, or a nut when nuts are ruled out for them.
///
/// The app asks it to flag and to leave things out of suggestions; the rules
/// ask the same question of every slot a write changes, and theirs is the
/// answer that counts (`FE-04`, `BE-20`).
abstract final class LunchSafety {
  /// Every concern, safety first, for something called [name] containing
  /// [allergens], in the box of a child with [rules].
  static List<LunchConcern> concernsFor({
    required String name,
    required Set<Allergen> allergens,
    required FoodRules rules,
  }) {
    final reactsTo = rules.allergens;
    final concerns = <LunchConcern>[
      for (final allergen in Allergen.values)
        if (allergens.contains(allergen) && reactsTo.contains(allergen))
          AllergenConcern(allergen),
    ];
    final hasNut = allergens.any((allergen) => allergen.isNut);
    final isNutCoveredAlready = concerns.any(
      (concern) => concern is AllergenConcern && concern.allergen.isNut,
    );
    if (hasNut && rules.isNutFree && !isNutCoveredAlready) {
      concerns.add(NutRuleConcern(rules.nutFreeReasons));
    }
    for (final dislike in rules.dislikes) {
      if (mentions(name, dislike)) concerns.add(DislikeConcern(dislike));
    }
    return concerns;
  }

  static bool isSafe({
    required Set<Allergen> allergens,
    required FoodRules rules,
  }) => !allergens.any(rules.mustAvoid);

  /// Whether a thing called [name] is what [word] names: "Cheese and tomato
  /// sandwich" mentions "Tomatoes", "Strawberries" mentions "strawberry",
  /// "Veggie wrap" does not mention "egg". The word's stem is matched at the
  /// start of a word in the name, case and spacing ignored — the same key the
  /// library deduplicates by.
  static bool mentions(String name, String word) {
    final stem = _stem(normalisedName(word));
    if (stem.length < 3) return false;
    return RegExp('\\b${RegExp.escape(stem)}').hasMatch(normalisedName(name));
  }

  /// The word with the endings English pluralises by taken off, so the
  /// singular and the plural share a stem: berry and berries both "berr".
  static String _stem(String word) {
    for (final (ending, longerThan) in const [
      ('ies', 4),
      ('ie', 4),
      ('es', 4),
      ('y', 4),
    ]) {
      if (word.endsWith(ending) && word.length > longerThan) {
        return word.substring(0, word.length - ending.length);
      }
    }
    if (word.endsWith('s') && !word.endsWith('ss') && word.length > 3) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }
}
