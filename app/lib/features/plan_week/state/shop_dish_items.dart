import '../../../shared/text/cut_text.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/model/lunch_item.dart';
import '../../lunch_box/model/lunch_slot.dart';
import '../../lunch_box/state/lunch_library_items.dart';
import '../data/lunch_recipe_saver.dart';
import '../model/planned_dish.dart';
import '../model/shop_week.dart';

/// One dish of a used week, as the library item it became and what its
/// boxes cost (lunch-box ADR-0021 §5).
typedef SavedDish = ({LunchItem item, int cents, int boxes});

/// The dishes a used week packs, made real in order (`BE-06`, `BE-07`):
/// first each dish's household recipe (`saveLunchRecipes`, recipes
/// ADR-0002), then its library item — named after the dish, in the main
/// compartment, linked to that recipe, at `dish-<recipeId>` so a retry or a
/// second phone writes the same one — carrying the recipe's codes and every
/// code the bought products' labels name. The rules refuse an item with
/// fewer codes than its recipe.
final class ShopDishItems {
  ShopDishItems({
    required this._recipes,
    required this._library,
    required this.householdId,
    required this.memberId,
  });

  final LunchRecipeSaver _recipes;
  final LunchLibraryItems _library;
  final String householdId;
  final String memberId;

  /// Idea id → the saved dish, for every dish [plan] packs at least once.
  Future<Map<String, SavedDish>> save(ShopWeek plan, LunchBoard board) async {
    final used = [
      for (final dish in plan.dishes.values)
        if (plan.boxesOfDish(dish.ideaId) > 0) dish,
    ];
    if (used.isEmpty) return const {};
    final saved = await _recipes.save(
      householdId: householdId,
      dishes: [
        for (final dish in used)
          (draft: dish.draft, alsoContains: dish.labelAllergens),
      ],
    );
    final dishes = <String, SavedDish>{};
    for (final (index, dish) in used.indexed) {
      final item = await _library.ensure(_itemOf(dish, saved[index]), board);
      final boxes = plan.boxesOfDish(dish.ideaId);
      dishes[dish.ideaId] = (
        item: item,
        cents: dish.costFor(boxes, plan.boxesPerPackOf).cents,
        boxes: boxes,
      );
    }
    return dishes;
  }

  LunchItem _itemOf(PlannedDish dish, SavedLunchRecipe recipe) =>
      LunchItem.named(
        id: 'dish-${recipe.id}',
        name: cutText(dish.draft.name, LunchItem.nameLimit),
        slot: LunchSlot.main,
        allergens: {
          ...recipe.allergens,
          ...dish.draft.allergens,
          ...dish.labelAllergens,
        },
        addedBy: memberId,
        prepAhead: dish.draft.prepAhead,
        prepNote: switch (dish.draft.prepNote) {
          final note? => cutText(note, LunchItem.prepNoteLimit),
          null => null,
        },
        householdRecipeId: recipe.id,
      );
}
