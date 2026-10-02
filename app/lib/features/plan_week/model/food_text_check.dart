import '../../family_profiles/model/allergen.dart';
import '../../family_profiles/model/food_rules.dart';
import '../../lunch_box/model/lunch_safety.dart';
import 'left_out_reason.dart';

/// Whether something described only in words may go in one child's box
/// (lunch-box ADR-0012): a lunch idea, or a shop's product with what the shop
/// says is in it. The fixed allergens are the words' (`AllergenWords`); the
/// child's own written allergies and dislikes are matched as the lunch
/// library matches them. Allergies come first, so the reason shown is the
/// one that matters most.
abstract final class FoodTextCheck {
  /// Why [name] — containing [allergens], with [contents] the rest of what is
  /// known about it — may not go to the child [childId] with [rules]; null
  /// when it may. [isKnown] false means nothing is known about its contents.
  static LeftOutReason? reasonFor({
    required String childId,
    required String name,
    required Set<Allergen> allergens,
    required FoodRules rules,
    String contents = '',
    bool isKnown = true,
  }) {
    for (final allergen in Allergen.values) {
      if (!allergens.contains(allergen) || !rules.mustAvoid(allergen)) {
        continue;
      }
      return LeftOutReason(
        rules.allergens.contains(allergen)
            ? LeftOutKind.allergy
            : LeftOutKind.nutRule,
        childId: childId,
        allergen: allergen,
      );
    }
    final text = '$name $contents';
    for (final allergy in rules.allergies) {
      final word = allergy.otherName;
      if (word != null && LunchSafety.mentions(text, word)) {
        return LeftOutReason(
          LeftOutKind.otherAllergy,
          childId: childId,
          word: word,
        );
      }
    }
    if (!isKnown && hasAllergies(rules)) {
      return LeftOutReason(LeftOutKind.unknownContents, childId: childId);
    }
    for (final dislike in rules.dislikes) {
      if (LunchSafety.mentions(name, dislike)) {
        return LeftOutReason(
          LeftOutKind.dislike,
          childId: childId,
          word: dislike,
        );
      }
    }
    return null;
  }

  /// Anything a box must be kept free of for them: an allergy of any kind,
  /// or the nut rule.
  static bool hasAllergies(FoodRules rules) =>
      rules.allergies.isNotEmpty || rules.isNutFree;
}
