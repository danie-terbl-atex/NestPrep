import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/time/household_clock.dart';
import '../data/meal_repository.dart';
import '../model/meal.dart';
import '../model/meal_ingredient.dart';
import '../model/meal_week.dart';
import '../model/week_plan.dart';

/// The meal plan's controller: the household's library and the week being
/// looked at. Moving a week reopens the week's listener and nothing else.
final class MealPlanController extends ChangeNotifier with ActionFailureHolder {
  MealPlanController({
    required MealRepository mealRepository,
    required HouseholdClock householdClock,
    required this.householdId,
    required this.memberId,
    CalendarDate? initialWeekStart,
  }) : _repository = mealRepository,
       _clock = householdClock {
    _weekStart = initialWeekStart ?? _clock.today.weekStart;
    _subscribeToMeals();
    _subscribeToWeek();
  }

  final MealRepository _repository;
  final HouseholdClock _clock;
  final String householdId;
  final String memberId;

  StreamSubscription<List<Meal>>? _mealSubscription;
  StreamSubscription<WeekPlan>? _weekSubscription;

  List<Meal>? _meals;
  WeekPlan? _plan;

  late CalendarDate _weekStart;
  AsyncState<MealWeek> _week = const AsyncLoading();
  bool _isCopying = false;

  AsyncState<MealWeek> get week => _week;
  CalendarDate get weekStart => _weekStart;
  CalendarDate get today => _clock.today;

  /// True while last week is being copied forward — the button cannot be
  /// pressed twice (`FE-10`).
  bool get isCopying => _isCopying;

  void goToWeek(CalendarDate weekStart) {
    final monday = weekStart.weekStart;
    if (monday == _weekStart) return;
    _weekStart = monday;
    _plan = null;
    _week = const AsyncLoading();
    notifyListeners();
    unawaited(_resubscribeToWeek());
  }

  void goToPreviousWeek() => goToWeek(_weekStart.addDays(-7));
  void goToNextWeek() => goToWeek(_weekStart.addDays(7));

  Future<void> retry() async {
    await _cancel();
    _meals = null;
    _plan = null;
    _week = const AsyncLoading();
    notifyListeners();
    _subscribeToMeals();
    _subscribeToWeek();
  }

  /// Fills a slot with a meal already in the library.
  Future<void> setSlot(String slotKey, String mealId) => runAction(
    () => _repository.setSlot(
      householdId: householdId,
      monday: _weekStart,
      slotKey: slotKey,
      mealId: mealId,
    ),
  );

  Future<void> clearSlot(String slotKey) => setSlot(slotKey, '');

  /// Fills a slot with a name somebody typed, adding it to the library if the
  /// household has not typed it before (meal-planning ADR-0001).
  Future<void> setSlotByName(String slotKey, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return Future.value();
    return runAction(() async {
      final mealId = await _repository.addMeal(
        householdId: householdId,
        name: trimmed,
        addedBy: memberId,
      );
      await _repository.setSlot(
        householdId: householdId,
        monday: _weekStart,
        slotKey: slotKey,
        mealId: mealId,
      );
    });
  }

  /// Copies last week forward. Only the empty slots move, unless [overwrite].
  Future<void> copyLastWeek({bool overwrite = false}) async {
    if (_isCopying) return;
    _isCopying = true;
    notifyListeners();
    try {
      await runAction(() async {
        final previous = await _repository.readWeek(
          householdId,
          _weekStart.addDays(-7),
        );
        final plan = _plan ?? WeekPlan.empty(_weekStart);
        final slots = plan.slotsCopiedFrom(previous, overwrite: overwrite);
        if (slots.isEmpty) return;
        await _repository.setSlots(
          householdId: householdId,
          monday: _weekStart,
          slots: slots,
        );
      });
    } finally {
      _isCopying = false;
      notifyListeners();
    }
  }

  Future<void> renameMeal(String mealId, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return Future.value();
    return runAction(
      () => _repository.renameMeal(
        householdId: householdId,
        mealId: mealId,
        name: trimmed,
      ),
    );
  }

  /// Replaces what a meal needs (meal-planning ADR-0002). Lines with no name
  /// are dropped; the rest are written as typed.
  Future<void> setIngredients(String mealId, List<MealIngredient> lines) =>
      runAction(
        () => _repository.setIngredients(
          householdId: householdId,
          mealId: mealId,
          ingredients: [
            for (final line in lines.take(MealIngredient.lineLimit))
              if (line.name.trim().isNotEmpty) line,
          ],
        ),
      );

  /// Deletes a meal and clears the slots that used it, in the weeks either side
  /// of the one showing — which is as far as a plan is ever looked at.
  Future<void> deleteMeal(String mealId) => runAction(
    () => _repository.deleteMeal(
      householdId: householdId,
      mealId: mealId,
      weeksToClear: [_weekStart.addDays(-7), _weekStart, _weekStart.addDays(7)],
    ),
  );

  void _subscribeToMeals() {
    _mealSubscription = _repository.watchMeals(householdId).listen((meals) {
      _meals = meals;
      _publish();
    }, onError: _onError);
  }

  void _subscribeToWeek() {
    _weekSubscription = _repository.watchWeek(householdId, _weekStart).listen((
      plan,
    ) {
      _plan = plan;
      _publish();
    }, onError: _onError);
  }

  Future<void> _resubscribeToWeek() async {
    await _weekSubscription?.cancel();
    _weekSubscription = null;
    _subscribeToWeek();
  }

  void _publish() {
    final meals = _meals;
    final plan = _plan;
    if (meals == null || plan == null) return;
    _week = AsyncData(
      MealWeek.from(
        weekStart: _weekStart,
        today: today,
        plan: plan,
        meals: meals,
      ),
    );
    notifyListeners();
  }

  void _onError(Object error) {
    _week = AsyncFailure(error is AppFailure ? error : UnknownFailure(error));
    notifyListeners();
  }

  Future<void> _cancel() async {
    await _mealSubscription?.cancel();
    await _weekSubscription?.cancel();
    _mealSubscription = null;
    _weekSubscription = null;
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
