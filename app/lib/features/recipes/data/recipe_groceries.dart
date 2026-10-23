import '../../../shared/text/normalised_name.dart';
import '../../groceries/data/grocery_repository.dart';
import '../../plan_week/data/shop_week_groceries.dart';
import '../../plan_week/model/shop_list_entry.dart';
import '../model/recipe_shop_line.dart';

/// Where *Add to grocer* sends what a recipe still needs (recipes ADR-0005):
/// the household's one grocery list. A line with a product goes on matched,
/// through the same writer *Plan my week* uses — so it is added once, never
/// twice, and a cart push works without anybody picking (groceries ADR-0007).
/// A line the shop had nothing for goes on by name, unless an unbought item
/// of that name is there already.
final class RecipeGroceries {
  const RecipeGroceries({
    required GroceryRepository groceryRepository,
    required this._matched,
    required this.householdId,
    required this.memberId,
  }) : _groceries = groceryRepository;

  final GroceryRepository _groceries;
  final ShopWeekGroceries _matched;
  final String householdId;
  final String memberId;

  /// Adds every included line; answers the matched ones as they now stand
  /// on the list, for a cart push, and how many unmatched lines were added.
  Future<({List<ShopListEntry> matched, int unmatched})> add(
    List<RecipeShopLine> lines,
  ) async {
    final included = [
      for (final line in lines)
        if (line.isIncluded) line,
    ];
    final matched = await _matched.add([
      for (final line in included)
        if (line.chosen case final product?)
          (
            product: product,
            name: line.name,
            quantity: line.quantity,
            packs: 1,
          ),
    ]);
    final bare = [
      for (final line in included)
        if (line.chosen == null) line,
    ];
    if (bare.isEmpty) return (matched: matched, unmatched: 0);
    final list = await _groceries.watchItems(householdId).first;
    final waiting = {
      for (final item in list)
        if (!item.isBought) normalisedName(item.name),
    };
    var unmatched = 0;
    for (final line in bare) {
      if (!waiting.add(normalisedName(line.name))) continue;
      await _groceries.add(
        householdId: householdId,
        name: line.name,
        quantity: line.quantity,
        addedBy: memberId,
      );
      unmatched++;
    }
    return (matched: matched, unmatched: unmatched);
  }
}
