import '../../../shared/text/normalised_name.dart';
import '../../groceries/data/grocery_repository.dart';
import '../../groceries/model/grocery_source.dart';
import '../model/dinner_idea.dart';

/// Where a planned week's new dinners send what they need (lunch-box
/// ADR-0011): the household's one grocery list, through groceries' own
/// repository, one line per thing, marked as the plan's. A name already on
/// the list and not yet bought — or twice in the plan — is added once.
///
/// Meals the household already has carry no ingredients on this build;
/// groceries' plan sync (groceries ADR-0002) takes over those at the merge.
final class PlanWeekGroceries {
  const PlanWeekGroceries({
    required GroceryRepository groceryRepository,
    required this.householdId,
    required this.memberId,
  }) : _groceries = groceryRepository;

  final GroceryRepository _groceries;
  final String householdId;
  final String memberId;

  /// Adds [ingredients] and returns how many lines it added.
  Future<int> add(List<IdeaIngredient> ingredients) async {
    final list = await _groceries.watchItems(householdId).first;
    final onTheList = {
      for (final item in list)
        if (!item.isBought) normalisedName(item.name),
    };
    var added = 0;
    for (final line in ingredients) {
      if (!onTheList.add(normalisedName(line.name))) continue;
      await _groceries.add(
        householdId: householdId,
        name: line.name,
        quantity: line.quantity,
        addedBy: memberId,
        origin: GrocerySource.plan,
      );
      added++;
    }
    return added;
  }
}
