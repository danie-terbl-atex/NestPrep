import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import 'checked_product.dart';
import 'dish_draft.dart';

/// One ingredient of a dish looked for at the shop (lunch-box ADR-0021 §3):
/// what the shop found for its search words, each product judged for the
/// dish's children — or the failure, kept for the log and said as "not
/// found". An ingredient the shop has nothing for is left to the household.
@immutable
final class IngredientFind {
  IngredientFind({
    required this.ingredient,
    List<CheckedProduct> found = const [],
    this.failure,
  }) : found = List.unmodifiable(found);

  final DishIngredient ingredient;

  /// In the shop's order.
  final List<CheckedProduct> found;
  final AppFailure? failure;

  /// The products every one of [childIds] may have, in the shop's order —
  /// what the week may buy this ingredient as.
  List<CheckedProduct> keptForAll(Iterable<String> childIds) => [
    for (final product in found)
      if (product.isKept && childIds.every(product.childIds.contains)) product,
  ];
}
