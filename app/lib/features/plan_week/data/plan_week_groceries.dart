import '../../../shared/text/normalised_name.dart';
import '../../groceries/data/grocery_repository.dart';
import '../../groceries/model/grocery_plan_changes.dart';
import '../../lunch_box/model/lunch_week.dart';
import '../model/dinner_idea.dart';

/// Where a planned week's new dinners send what they need (lunch-box
/// ADR-0011): the household's one grocery list, as **planned items** — the
/// groceries feature's one way of saying where a line nobody typed came from
/// (groceries ADR-0002): the week, the normalised name and the reason shown.
/// The dinners are saved as meals with their ingredients, so the meal plan's
/// own grocery source asks for the same lines, and *keep in step* refreshes
/// them rather than taking them off. A name already on the list and not yet
/// bought — or twice in the plan — is added once; everything in one batch.
final class PlanWeekGroceries {
  const PlanWeekGroceries({
    required GroceryRepository groceryRepository,
    required this.householdId,
    required this.memberId,
  }) : _groceries = groceryRepository;

  final GroceryRepository _groceries;
  final String householdId;
  final String memberId;

  /// Adds [ingredients] for [week] and returns how many lines it added.
  Future<int> add(
    List<IdeaIngredient> ingredients, {
    required LunchWeek week,
    required String note,
  }) async {
    final list = await _groceries.watchItems(householdId).first;
    final onTheList = {
      for (final item in list)
        if (!item.isBought) normalisedName(item.name),
    };
    final taken = {for (final item in list) item.id};
    final creates = <PlannedItemCreate>[];
    for (final line in ingredients) {
      final key = normalisedName(line.name);
      if (!onTheList.add(key)) continue;
      final id = GroceryPlanChanges.freeIdFor(week.key, key, taken);
      taken.add(id);
      creates.add((
        id: id,
        name: line.name,
        quantity: line.quantity,
        key: key,
        week: week.key,
        note: note,
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
