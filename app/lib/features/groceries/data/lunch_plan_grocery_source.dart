import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../../household/model/household_area.dart';
import '../../lunch_box/data/lunch_week_reader.dart';
import '../../lunch_box/model/lunch_week.dart';
import '../../lunch_box/model/lunch_week_items.dart';
import '../../meal_planning/model/ingredient_unit.dart';
import '../../recipes/data/recipe_repository.dart';
import '../../recipes/model/recipe.dart';
import '../../recipes/model/recipe_link.dart';
import '../model/grocery_amount.dart';
import '../model/grocery_need.dart';
import '../model/grocery_need_reason.dart';
import 'grocery_suggestion_source.dart';

/// The week's lunch boxes as grocery needs, through lunch-box's read API
/// (`LunchWeekReader.watchWeekItems`, lunch-box overview *Contracts*): one need
/// per item, already summed across every day and child, counted in boxes and
/// never converted to an amount (groceries ADR-0003) — **except an item made
/// from a recipe, which needs that recipe's ingredients**, each scaled by the
/// boxes it fills (groceries ADR-0006). A recipe that cannot be read —
/// missing, or a read that failed — is counted like any item, so a need is
/// never lost; a failed read is logged and tried again next time. Recipes
/// never change, so each is read once per source.
///
/// The Sunday prep list reads the same rows for a different question — what
/// to make ahead — so the two never disagree about what the week holds.
final class LunchPlanGrocerySource implements GrocerySuggestionSource {
  LunchPlanGrocerySource(this._reader, this._recipes);

  final LunchWeekReader _reader;
  final RecipeRepository _recipes;

  /// Link → the recipe, or null when it is not there; a failed read is not
  /// kept, so it is tried again.
  final _read = <RecipeLink, Recipe?>{};

  @override
  String get id => 'lunch';

  @override
  HouseholdArea get area => HouseholdArea.lunch;

  @override
  Stream<List<GroceryNeed>> watchNeeds(String householdId, LunchWeek week) =>
      _reader.watchWeekItems(householdId, week).asyncMap((items) async {
        final links = {for (final item in items) ?item.recipeLink};
        final recipes = <RecipeLink, Recipe>{
          for (final link in links) link: ?await _recipe(householdId, link),
        };
        return needsOf(items, recipes: recipes);
      });

  Future<Recipe?> _recipe(String householdId, RecipeLink link) async {
    if (_read.containsKey(link)) return _read[link];
    try {
      return _read[link] = await _recipes.fetchLinked(householdId, link);
    } on AppFailure catch (failure) {
      // Handled: the item is counted instead (groceries ADR-0006 §3).
      AppLog.failure(
        'read lunch recipe for groceries',
        code: failure.runtimeType.toString(),
        error: failure,
      );
      return null;
    }
  }

  /// Pure, so the arithmetic is tested without a stream.
  static List<GroceryNeed> needsOf(
    List<LunchWeekItem> items, {
    Map<RecipeLink, Recipe> recipes = const {},
  }) => [
    for (final item in items)
      if (item.portions > 0 && item.name.trim().isNotEmpty)
        ...switch (recipes[item.recipeLink]) {
          final recipe? => _ingredientsOf(recipe, item),
          null => [GroceryNeed(name: item.name, reason: _reasonOf(item))],
        },
  ];

  /// Each ingredient line, its quantity times the boxes over the servings,
  /// in its unit; a unit this build does not know gives a reason and no
  /// amount, rather than a count that is not one.
  static List<GroceryNeed> _ingredientsOf(Recipe recipe, LunchWeekItem item) {
    final scale = item.portions / recipe.servings;
    return [
      for (final line in recipe.ingredients)
        if (line.name.trim().isNotEmpty)
          GroceryNeed(
            name: line.name,
            amount: switch ((line.quantity, line.unit)) {
              (final quantity?, null) => GroceryAmount(quantity * scale),
              (final quantity?, final code?) => switch (IngredientUnit.fromCode(
                code,
              )) {
                final unit? => GroceryAmount(quantity * scale, unit),
                null => null,
              },
              _ => null,
            },
            reason: _reasonOf(item),
          ),
    ];
  }

  static LunchPlanReason _reasonOf(LunchWeekItem item) =>
      LunchPlanReason(boxes: item.portions, childIds: item.childIds);
}
