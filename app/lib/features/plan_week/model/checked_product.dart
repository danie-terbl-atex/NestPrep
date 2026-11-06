import 'package:flutter/foundation.dart';

import '../../add_to_checkers/model/retailer_product.dart';
import '../../family_profiles/model/allergen.dart';
import '../../family_profiles/model/food_rules.dart';
import '../../groceries/model/product_match.dart';
import 'allergen_words.dart';
import 'food_text_check.dart';
import 'left_out_reason.dart';

/// What a shop's product may do for a child with any allergy when the shop
/// says nothing of what is in it.
enum UnknownContents {
  /// It is kept from them.
  hidden,

  /// It is judged on its name alone and offered, with a caution to check
  /// the label.
  offeredWithCaution,
}

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
    required this.isJudgedByName,
    required Set<String> childIds,
    required Set<String> labelCheckChildIds,
    required List<LeftOutReason> reasons,
  }) : allergens = Set.unmodifiable(allergens),
       childIds = Set.unmodifiable(childIds),
       labelCheckChildIds = Set.unmodifiable(labelCheckChildIds),
       reasons = List.unmodifiable(reasons);

  /// [shop]'s policy for a product it says nothing of: Woolworths publishes
  /// no contents for fresh produce, so its unknown products are offered on
  /// their names, with a caution.
  static UnknownContents unknownContentsAt(ProductRetailer shop) =>
      switch (shop) {
        ProductRetailer.checkers ||
        ProductRetailer.pickNPay => UnknownContents.hidden,
        ProductRetailer.woolworths => UnknownContents.offeredWithCaution,
      };

  /// [product] judged for each child in [rulesByChild] — child id to the
  /// rules the phone holds for them now.
  factory CheckedProduct.of(
    RetailerProduct product,
    Map<String, FoodRules> rulesByChild,
  ) {
    final contents = [
      ?product.allergenText,
      ?product.ingredientsText,
    ].join(' ');
    final allergens = AllergenWords.mentionedIn('${product.name} $contents');
    final isKnown = product.hasContentsText;
    final isJudgedByName =
        !isKnown &&
        unknownContentsAt(product.retailer) ==
            UnknownContents.offeredWithCaution;
    final everybody = [
      if (!product.isInStock) const LeftOutReason(LeftOutKind.outOfStock),
      if (product.isSoldByWeight) const LeftOutReason(LeftOutKind.soldByWeight),
    ];
    final childIds = <String>{};
    final labelCheckChildIds = <String>{};
    final reasons = [...everybody];
    if (everybody.isEmpty) {
      for (final MapEntry(key: childId, value: rules) in rulesByChild.entries) {
        final reason = FoodTextCheck.reasonFor(
          childId: childId,
          name: product.name,
          allergens: allergens,
          rules: rules,
          contents: contents,
          isKnown: isKnown || isJudgedByName,
        );
        if (reason == null) {
          childIds.add(childId);
          if (isJudgedByName && FoodTextCheck.hasAllergies(rules)) {
            labelCheckChildIds.add(childId);
          }
        } else {
          reasons.add(reason);
        }
      }
    }
    return CheckedProduct._(
      product: product,
      allergens: allergens,
      isKnown: isKnown,
      isJudgedByName: isJudgedByName,
      childIds: childIds,
      labelCheckChildIds: labelCheckChildIds,
      reasons: reasons,
    );
  }

  final RetailerProduct product;

  /// What the shop's words say is in it — the codes a library item made
  /// from it carries into every box (lunch-box ADR-0001).
  final Set<Allergen> allergens;
  final bool isKnown;

  /// Nothing is known of what is in it, and its shop's policy offers it on
  /// its name alone ([unknownContentsAt]).
  final bool isJudgedByName;

  /// The children it may go to.
  final Set<String> childIds;

  /// The children with an allergy it may go to although nothing is known of
  /// what is in it — whoever picks it for them is told to check the label.
  final Set<String> labelCheckChildIds;

  bool needsLabelCheckFor(String childId) =>
      labelCheckChildIds.contains(childId);

  /// Why it is kept from everybody, or from the children not in [childIds].
  final List<LeftOutReason> reasons;

  bool get isKept => childIds.isNotEmpty;

  String get productId => product.id;
}
