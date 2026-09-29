import '../../../shared/text/normalised_name.dart';
import '../../groceries/data/grocery_repository.dart';
import '../../groceries/model/grocery_source.dart';
import '../model/lunch_pantry_week.dart';

/// Where the pantry's shortfall goes (lunch-box ADR-0006): the household's
/// one grocery list, through groceries' own repository, one line per thing,
/// marked as the pantry's. A name already on the list and not yet bought is
/// not added twice.
final class LunchPantryGroceries {
  const LunchPantryGroceries({
    required GroceryRepository groceryRepository,
    required this.householdId,
    required this.memberId,
  }) : _groceries = groceryRepository;

  final GroceryRepository _groceries;
  final String householdId;
  final String memberId;

  /// Adds [shortfall] and returns how many lines it added.
  Future<int> add(
    List<LunchShortfall> shortfall, {
    required String Function(int boxes) quantityFor,
  }) async {
    final list = await _groceries.watchItems(householdId).first;
    final onTheList = {
      for (final item in list)
        if (!item.isBought) normalisedName(item.name),
    };
    var added = 0;
    for (final missing in shortfall) {
      if (onTheList.contains(normalisedName(missing.item.name))) continue;
      await _groceries.add(
        householdId: householdId,
        name: missing.item.name,
        quantity: quantityFor(missing.boxes),
        addedBy: memberId,
        origin: GrocerySource.pantry,
      );
      added++;
    }
    return added;
  }
}
