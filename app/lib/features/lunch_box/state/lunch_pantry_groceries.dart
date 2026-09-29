import '../../../shared/text/normalised_name.dart';
import '../../groceries/data/grocery_repository.dart';
import '../../groceries/model/grocery_plan_changes.dart';
import '../model/lunch_pantry_week.dart';
import '../model/lunch_week.dart';

/// Where the pantry's shortfall goes (lunch-box ADR-0006): the household's
/// one grocery list, as **planned items** — the groceries feature's one way of
/// saying where a line nobody typed came from (groceries ADR-0002): the
/// week, the normalised name and the reason shown. So the plans' sheet sees
/// them as already on the list, *keep in step* refreshes them like its own,
/// and a person's edit adopts them. A name already on the list and not yet
/// bought is not added twice; everything goes in one batch.
final class LunchPantryGroceries {
  const LunchPantryGroceries({
    required GroceryRepository groceryRepository,
    required this.householdId,
    required this.memberId,
  }) : _groceries = groceryRepository;

  final GroceryRepository _groceries;
  final String householdId;
  final String memberId;

  /// Adds [shortfall] for [week] and returns how many lines it added.
  Future<int> add(
    List<LunchShortfall> shortfall, {
    required LunchWeek week,
    required String Function(int boxes) quantityFor,
    required String Function(int boxes) noteFor,
  }) async {
    final list = await _groceries.watchItems(householdId).first;
    final onTheList = {
      for (final item in list)
        if (!item.isBought) normalisedName(item.name),
    };
    final taken = {for (final item in list) item.id};
    final creates = <PlannedItemCreate>[];
    for (final missing in shortfall) {
      final key = normalisedName(missing.item.name);
      if (!onTheList.add(key)) continue;
      final id = GroceryPlanChanges.freeIdFor(week.key, key, taken);
      taken.add(id);
      creates.add((
        id: id,
        name: missing.item.name,
        quantity: quantityFor(missing.boxes),
        key: key,
        week: week.key,
        note: noteFor(missing.boxes),
      ));
    }
    if (creates.isEmpty) return 0;
    await _groceries.applyPlanChanges(
      householdId: householdId,
      changes: GroceryPlanChanges(creates: creates),
      memberId: memberId,
    );
    return creates.length;
  }
}
