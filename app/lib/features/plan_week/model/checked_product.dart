import 'package:flutter/foundation.dart';

import '../../add_to_checkers/model/checkers_product.dart';
import '../../family_profiles/model/allergen.dart';
import '../../family_profiles/model/food_rules.dart';
import 'allergen_words.dart';
import 'food_text_check.dart';
import 'left_out_reason.dart';

/// One shop product as NestPrep judged it for one lunch idea (lunch-box
/// ADR-0012): the allergens its name, *Allergens* and *Ingredients* lines
/// name, whether anything was known at all, which of the idea's children it
/// may go to, and why it is kept from the rest.
@immutable
final class CheckedProduct {
  CheckedProduct._({
    required this.product,
    required Set<Allergen> allergens,
    required this.isKnown,
    required Set<String> childIds,
    required List<LeftOutReason> reasons,
  }) : allergens = Set.unmodifiable(allergens),
       childIds = Set.unmodifiable(childIds),
       reasons = List.unmodifiable(reasons);

  /// [product] judged for each child in [rulesByChild] — child id to the
  /// rules the phone holds for them now.
  factory CheckedProduct.of(
    CheckersProduct product,
    Map<String, FoodRules> rulesByChild,
  ) {
    final contents = [
      ?product.allergenText,
      ?product.ingredientsText,
    ].join(' ');
    final allergens = AllergenWords.mentionedIn('${product.name} $contents');
    final isKnown = product.hasContentsText;
    final everybody = [
      if (!product.isInStock) const LeftOutReason(LeftOutKind.outOfStock),
      if (product.isSoldByWeight) const LeftOutReason(LeftOutKind.soldByWeight),
    ];
    final childIds = <String>{};
    final reasons = [...everybody];
    if (everybody.isEmpty) {
      for (final MapEntry(key: childId, value: rules) in rulesByChild.entries) {
        final reason = FoodTextCheck.reasonFor(
          childId: childId,
          name: product.name,
          allergens: allergens,
          rules: rules,
          contents: contents,
          isKnown: isKnown,
        );
        if (reason == null) {
          childIds.add(childId);
        } else {
          reasons.add(reason);
        }
      }
    }
    return CheckedProduct._(
      product: product,
      allergens: allergens,
      isKnown: isKnown,
      childIds: childIds,
      reasons: reasons,
    );
  }

  final CheckersProduct product;

  /// What the shop's words say is in it — the codes a library item made
  /// from it carries into every box (lunch-box ADR-0001).
  final Set<Allergen> allergens;
  final bool isKnown;

  /// The children it may go to.
  final Set<String> childIds;

  /// Why it is kept from everybody, or from the children not in [childIds].
  final List<LeftOutReason> reasons;

  bool get isKept => childIds.isNotEmpty;

  String get productId => product.id;
}
