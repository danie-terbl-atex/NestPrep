import 'package:flutter/foundation.dart';

import '../../../shared/money/money.dart';
import '../../family_profiles/model/allergen.dart';
import 'checked_product.dart';
import 'dish_draft.dart';

/// One ingredient of a planned dish and the shop product it is bought as.
typedef PlannedDishPart = ({String ingredient, CheckedProduct product});

/// A dish in the week (lunch-box ADR-0021 §4): the draft the model wrote,
/// and the products the server chose to buy it as — one per ingredient the
/// shop had; the rest are the household's.
@immutable
final class PlannedDish {
  PlannedDish({
    required this.ideaId,
    required this.draft,
    required List<PlannedDishPart> parts,
  }) : parts = List.unmodifiable(parts);

  /// The id a dish stands under in the week — the server's
  /// `dish:<ideaId>`, never a shop's.
  static String productIdOf(String ideaId) => 'dish:$ideaId';

  final String ideaId;
  final DishDraft draft;
  final List<PlannedDishPart> parts;

  String get productId => productIdOf(ideaId);

  /// What the chosen products' labels add to the dish's own words — sent
  /// with the recipe, so it is at least as strict as what is bought.
  Set<Allergen> get labelAllergens => {
    for (final part in parts) ...part.product.allergens,
  };

  /// What [boxes] of the dish cost at the till: each ingredient product's
  /// whole packs for those boxes, at its shelf price (ADR-0021 §5) — the
  /// price its library item is given, per dish, as the server sums it.
  Money costFor(int boxes, int Function(String productId) boxesPerPackOf) =>
      parts.fold(const Money.zero(), (sum, part) {
        final perPack = boxesPerPackOf(part.product.productId).clamp(1, 100);
        final packs = boxes <= 0 ? 0 : (boxes + perPack - 1) ~/ perPack;
        final price = part.product.product.price;
        return sum + Money(packs * price.cents, currency: price.currency);
      });
}
