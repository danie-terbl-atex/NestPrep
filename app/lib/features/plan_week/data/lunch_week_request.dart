import '../../lunch_box/model/lunch_week.dart';
import '../model/checked_product.dart';
import '../model/idea_search.dart';
import '../model/lunch_idea.dart';

/// What the phone sends `buildLunchWeek` (lunch-box ADR-0012 §5), within the
/// contract's bounds: at most [ideaLimit] ideas that found something kept —
/// the lunchbox aisle's shelves marked so (ADR-0013) —
/// each with at most [productLimit] kept products, names and brands cut to
/// the contract's lengths. Pure, so the shape is tested without Functions.
abstract final class LunchWeekRequest {
  /// The model's 25 ideas and the aisle's 12 shelves.
  static const ideaLimit = 37;
  static const productLimit = 6;

  static Map<String, Object?> toWire({
    required String householdId,
    required LunchWeek week,
    required Set<String> childIds,
    required List<IdeaSearch> searches,
  }) => {
    'householdId': householdId,
    'week': week.key,
    'childIds': [...childIds]..sort(),
    'ideas': [
      for (final search
          in searches.where((s) => s.kept.isNotEmpty).take(ideaLimit))
        {
          'id': search.ideaId,
          'slot': search.idea.slot.name,
          'fromAisle': search.idea.origin == IdeaOrigin.aisle,
          'childIds': [
            for (final childId in search.idea.childIds)
              if (childIds.contains(childId)) childId,
          ],
          'products': [
            for (final product in search.kept.take(productLimit))
              _product(product),
          ],
        },
    ],
  };

  static Map<String, Object?> _product(CheckedProduct checked) {
    final product = checked.product;
    return {
      'productId': product.id,
      'name': _cut(product.name, 120),
      'brand': switch (product.brand) {
        final brand? => _cut(brand, 60),
        null => null,
      },
      'priceCents': product.price.cents,
      'isOnPromotion': product.isOnPromotion,
      'allergens': [for (final allergen in checked.allergens) allergen.name],
      'allergensKnown': checked.isKnown,
      'packQuantity': switch (product.packCount) {
        final count? when count >= 1 && count <= 100 => count,
        _ => null,
      },
    };
  }

  static String _cut(String text, int longest) =>
      text.length <= longest ? text : text.substring(0, longest);
}
