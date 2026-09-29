import '../../../shared/async/combine_latest.dart';
import '../../household/model/household_area.dart';
import '../../lunch_box/model/lunch_week.dart';
import '../../meal_planning/data/meal_repository.dart';
import '../../meal_planning/model/meal.dart';
import '../../meal_planning/model/week_plan.dart';
import '../model/grocery_amount.dart';
import '../model/grocery_need.dart';
import '../model/grocery_need_reason.dart';
import 'grocery_suggestion_source.dart';

/// The week's meal plan as grocery needs (groceries ADR-0002, meal-planning
/// ADR-0002): every ingredient of every planned meal, once per slot the meal
/// fills, with the slot as its reason. A meal eaten twice needs its
/// ingredients twice.
///
/// Reads the meal library and the one week document — the same two listeners
/// the meal plan screen holds, so on a phone that has shown the week both are
/// already in the cache.
final class MealPlanGrocerySource implements GrocerySuggestionSource {
  const MealPlanGrocerySource(this._repository);

  final MealRepository _repository;

  @override
  String get id => 'meals';

  @override
  HouseholdArea get area => HouseholdArea.meals;

  @override
  Stream<List<GroceryNeed>> watchNeeds(String householdId, LunchWeek week) =>
      combineLatest2(
        _repository.watchMeals(householdId),
        _repository.watchWeek(householdId, week.monday),
        needsOf,
      );

  /// Pure, so the arithmetic is tested without a stream.
  static List<GroceryNeed> needsOf(List<Meal> meals, WeekPlan plan) {
    final byId = {for (final meal in meals) meal.id: meal};
    return [
      for (var day = 1; day <= WeekPlan.daysInAWeek; day++)
        for (final slot in MealSlot.values)
          if (byId[plan.mealIdAt(day, slot) ?? ''] case final meal?)
            for (final line in meal.ingredients)
              if (line.name.trim().isNotEmpty)
                GroceryNeed(
                  name: line.name,
                  amount: switch (line.amount) {
                    final amount? => GroceryAmount(amount, line.unit),
                    null => null,
                  },
                  reason: MealPlanReason(
                    isoWeekday: day,
                    slot: slot,
                    mealName: meal.name,
                  ),
                ),
    ];
  }
}
