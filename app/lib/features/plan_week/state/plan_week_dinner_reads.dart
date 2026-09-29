import 'dart:async';

import '../../../shared/failure/app_failure.dart';
import '../../lunch_box/model/lunch_week.dart';
import '../../meal_planning/data/meal_repository.dart';
import '../../meal_planning/model/meal.dart';
import '../../meal_planning/model/week_plan.dart';

/// The two reads dinners are planned from (lunch-box ADR-0011): the meal
/// library and the week's meal plan, followed live so a dinner somebody fills
/// while the review is open is not planned over. Kept apart from the
/// controller so that file stays about the steps (`ENG-05`).
final class PlanWeekDinnerReads {
  PlanWeekDinnerReads({
    required MealRepository mealRepository,
    required this.householdId,
    required this.week,
  }) : _meals = mealRepository;

  final MealRepository _meals;
  final String householdId;
  final LunchWeek week;

  StreamSubscription<List<Meal>>? _librarySubscription;
  StreamSubscription<WeekPlan>? _weekSubscription;

  /// Null until the library has answered.
  List<Meal>? library;

  /// Null until the week's plan has answered.
  WeekPlan? mealPlan;

  bool get hasAnswered => library != null && mealPlan != null;

  /// Starts both reads. A read that fails leaves an empty library or week —
  /// dinners are planned from nothing rather than not at all — and says why
  /// through [onFailure] (`ENG-10`).
  void start({
    required void Function() onChange,
    required void Function(AppFailure failure) onFailure,
  }) {
    _librarySubscription = _meals
        .watchMeals(householdId)
        .listen(
          (meals) {
            library = meals;
            onChange();
          },
          onError: (Object error) {
            library = const [];
            onFailure(_asFailure(error));
          },
        );
    _weekSubscription = _meals
        .watchWeek(householdId, week.monday)
        .listen(
          (plan) {
            mealPlan = plan;
            onChange();
          },
          onError: (Object error) {
            mealPlan = WeekPlan.empty(week.monday);
            onFailure(_asFailure(error));
          },
        );
  }

  static AppFailure _asFailure(Object error) =>
      error is AppFailure ? error : UnknownFailure(error);

  void close() {
    unawaited(_librarySubscription?.cancel());
    unawaited(_weekSubscription?.cancel());
  }
}
