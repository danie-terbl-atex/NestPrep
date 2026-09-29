import '../../../shared/time/calendar_date.dart';
import '../model/meal.dart';
import '../model/meal_ingredient.dart';
import '../model/week_plan.dart';

/// What meal planning needs from Firestore. Two reads: the household's library,
/// and the one document that is the week being looked at (meal-planning
/// ADR-0001).
abstract interface class MealRepository {
  Stream<List<Meal>> watchMeals(String householdId);

  /// The plan for the week starting [monday]. Emits an empty plan when the
  /// document does not exist — a week nobody has planned is not an error.
  Stream<WeekPlan> watchWeek(String householdId, CalendarDate monday);

  /// Reads one week once, for copying it forward.
  Future<WeekPlan> readWeek(String householdId, CalendarDate monday);

  /// Adds a meal to the library, or returns the existing one when the household
  /// has typed that name before.
  Future<String> addMeal({
    required String householdId,
    required String name,
    required String addedBy,
  });

  Future<void> renameMeal({
    required String householdId,
    required String mealId,
    required String name,
  });

  /// Replaces what a meal needs (meal-planning ADR-0002). Any meals editor may,
  /// not only the adder — the rules allow a write that moves nothing else.
  Future<void> setIngredients({
    required String householdId,
    required String mealId,
    required List<MealIngredient> ingredients,
  });

  /// Deletes a meal and clears every slot that used it, across the weeks given.
  Future<void> deleteMeal({
    required String householdId,
    required String mealId,
    required List<CalendarDate> weeksToClear,
  });

  /// Fills or clears one slot. An empty [mealId] clears it.
  Future<void> setSlot({
    required String householdId,
    required CalendarDate monday,
    required String slotKey,
    required String mealId,
  });

  /// Writes several slots at once — what copying last week is.
  Future<void> setSlots({
    required String householdId,
    required CalendarDate monday,
    required Map<String, String> slots,
  });

  static const mealLimit = 500;
}
