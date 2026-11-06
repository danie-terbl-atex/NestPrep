import '../../lunch_box/model/lunch_slot.dart';
import '../../lunch_box/model/lunch_variety.dart';
import '../../lunch_box/model/lunch_week.dart';
import '../model/checked_product.dart';
import '../model/idea_search.dart';
import '../model/lunch_idea.dart';
import '../model/packing_preference.dart';
import '../model/treat_days.dart';

/// What the phone sends `buildLunchWeek` (lunch-box ADR-0012 §5), within the
/// contract's bounds: at most [ideaLimit] ideas that found something kept —
/// the lunchbox aisle's shelves marked so (ADR-0013), a dish with its
/// ingredients' products (ADR-0021) —
/// each with at most [productLimit] kept products, names and brands cut to
/// the contract's lengths — the brief's packing choices and the compartments
/// kept the same all week (ADR-0028). Pure, so the
/// shape is tested without Functions.
abstract final class LunchWeekRequest {
  /// The model's 25 ideas and the aisle's 12 shelves.
  static const ideaLimit = 37;
  static const productLimit = 6;

  /// A dish's ingredients and the products sent for each (lunch-box
  /// ADR-0021 §3): the first few every one of the dish's children may have,
  /// in the shop's order — the server buys the first that passes its check.
  static const ingredientLimit = 8;
  static const productsPerIngredient = 3;

  static Map<String, Object?> toWire({
    required String householdId,
    required LunchWeek week,
    required Set<String> childIds,
    required List<IdeaSearch> searches,
    required PackingChoice packing,
    LunchVariety variety = LunchVariety.standard,
  }) => {
    'householdId': householdId,
    'week': week.key,
    'childIds': [...childIds]..sort(),
    'slots': wireNames(LunchSlot.values, packing.slots),
    'preferences': wireNames(PackingPreference.values, packing.preferences),
    'treatDays': TreatDays.inOrder(packing.treatDays),
    'sameAllWeek': variety.names,
    'ideas': [
      for (final search in searches.where((s) => s.hasKept).take(ideaLimit))
        _idea(search, childIds),
    ],
  };

  static Map<String, Object?> _idea(IdeaSearch search, Set<String> childIds) {
    final dish = search.idea.dish;
    final forChildren = [
      for (final childId
          in dish == null ? search.idea.childIds : search.dishChildIds)
        if (childIds.contains(childId)) childId,
    ];
    return {
      'id': search.ideaId,
      'slot': search.idea.slot.name,
      'fromAisle': search.idea.origin == IdeaOrigin.aisle,
      'childIds': forChildren,
      'products': [
        for (final product in search.kept.take(productLimit)) _product(product),
      ],
      if (dish != null)
        'dish': {
          'name': _cut(dish.name, 60),
          'ingredients': [
            for (final find in search.ingredients.take(ingredientLimit))
              {
                'name': _cut(find.ingredient.name, 60),
                'searchTerm': _cut(find.ingredient.searchTerm, 40),
                'products': [
                  for (final product
                      in find
                          .keptForAll(forChildren)
                          .take(productsPerIngredient))
                    _product(product),
                ],
              },
          ],
        },
    };
  }

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
      // The server keeps an unknown product from every child with an
      // allergy; one its shop's policy offers on its name is sent as known.
      'allergensKnown': checked.isKnown || checked.isJudgedByName,
      'packQuantity': switch (product.packCount) {
        final count? when count >= 1 && count <= 100 => count,
        _ => null,
      },
    };
  }

  static String _cut(String text, int longest) =>
      text.length <= longest ? text : text.substring(0, longest);
}
