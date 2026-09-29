import 'dart:async';

import 'package:nestprep/features/meal_planning/data/meal_repository.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/meal_planning/model/meal_ingredient.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/text/normalised_name.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// The library and the week, driven by hand. The week stream is recreated when
/// the window moves, so a test can check the reopen.
final class FakeMealRepository implements MealRepository {
  final _meals = StreamController<List<Meal>>.broadcast();
  StreamController<WeekPlan> _week = StreamController<WeekPlan>.broadcast();

  AppFailure? failWritesWith;

  /// What `readWeek` answers with, keyed by that week's Monday.
  final storedWeeks = <String, WeekPlan>{};

  /// The library `addMeal` deduplicates against.
  final knownMeals = <Meal>[];

  final watchedWeeks = <String>[];
  final addedMeals = <String>[];
  final renamedMeals = <({String mealId, String name})>[];
  final ingredientWrites =
      <({String mealId, List<MealIngredient> ingredients})>[];
  final deletedMeals = <({String mealId, List<String> weeks})>[];
  final writtenSlots = <({String monday, Map<String, String> slots})>[];

  void emitMeals(List<Meal> meals) => _meals.add(meals);
  void emitWeek(WeekPlan plan) => _week.add(plan);
  void failMealsWith(Object error) => _meals.addError(error);

  Future<void> close() async {
    await _meals.close();
    await _week.close();
  }

  @override
  Stream<List<Meal>> watchMeals(String householdId) => _meals.stream;

  @override
  Stream<WeekPlan> watchWeek(String householdId, CalendarDate monday) {
    watchedWeeks.add(monday.iso);
    if (_week.hasListener) {
      _week = StreamController<WeekPlan>.broadcast();
    }
    return _week.stream;
  }

  @override
  Future<WeekPlan> readWeek(String householdId, CalendarDate monday) async {
    _refuseIfAsked();
    return storedWeeks[monday.iso] ?? WeekPlan.empty(monday);
  }

  @override
  Future<String> addMeal({
    required String householdId,
    required String name,
    required String addedBy,
  }) async {
    _refuseIfAsked();
    addedMeals.add(name);
    final key = normalisedName(name);
    final existing = knownMeals
        .where((meal) => meal.nameKey == key)
        .firstOrNull;
    if (existing != null) return existing.id;
    final meal = Meal.named(
      id: 'meal-${knownMeals.length}',
      name: name,
      addedBy: addedBy,
    );
    knownMeals.add(meal);
    return meal.id;
  }

  @override
  Future<void> renameMeal({
    required String householdId,
    required String mealId,
    required String name,
  }) async {
    _refuseIfAsked();
    renamedMeals.add((mealId: mealId, name: name));
  }

  @override
  Future<void> setIngredients({
    required String householdId,
    required String mealId,
    required List<MealIngredient> ingredients,
  }) async {
    _refuseIfAsked();
    ingredientWrites.add((mealId: mealId, ingredients: ingredients));
  }

  @override
  Future<void> deleteMeal({
    required String householdId,
    required String mealId,
    required List<CalendarDate> weeksToClear,
  }) async {
    _refuseIfAsked();
    deletedMeals.add((
      mealId: mealId,
      weeks: [for (final week in weeksToClear) week.iso],
    ));
  }

  @override
  Future<void> setSlot({
    required String householdId,
    required CalendarDate monday,
    required String slotKey,
    required String mealId,
  }) => setSlots(
    householdId: householdId,
    monday: monday,
    slots: {slotKey: mealId},
  );

  @override
  Future<void> setSlots({
    required String householdId,
    required CalendarDate monday,
    required Map<String, String> slots,
  }) async {
    _refuseIfAsked();
    writtenSlots.add((monday: monday.iso, slots: slots));
  }

  void _refuseIfAsked() {
    final failure = failWritesWith;
    if (failure != null) throw failure;
  }
}
