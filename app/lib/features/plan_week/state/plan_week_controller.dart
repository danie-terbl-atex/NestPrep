import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/model/lunch_fill_bias.dart';
import '../../lunch_box/model/lunch_item.dart';
import '../../lunch_box/model/lunch_item_draft.dart';
import '../../lunch_box/model/lunch_safety.dart';
import '../../lunch_box/model/lunch_week.dart';
import '../../meal_planning/data/meal_repository.dart';
import '../../meal_planning/model/meal.dart';
import '../../meal_planning/model/week_plan.dart';
import '../data/plan_week_groceries.dart';
import '../data/week_planner.dart';
import '../model/plan_week_options.dart';
import '../model/planned_week.dart';
import '../model/planned_week_builder.dart';
import 'plan_week_dinner_reads.dart';
import 'plan_week_saver.dart';

/// Where *Plan my week* is (lunch-box ADR-0011).
enum PlanWeekStep { choosing, planning, review, saving, done }

/// *Plan my week*: choose, ask, look it over, use it. It follows the lunch
/// board for the children, their rules and the library, and — when dinners
/// can be planned — the meal library and the week's dinners, so the plan is
/// built and checked against what the phone holds now.
///
/// When the model cannot help — AI off, the month spent, no answer, no
/// connection — the week is planned by the app's own auto-fill and a dinner
/// rotation instead, and the review says so.
final class PlanWeekController extends ChangeNotifier {
  PlanWeekController({
    required this._planner,
    required this._saver,
    required this._groceries,
    required MealRepository mealRepository,
    required this.householdId,
    required this.week,
    required this.mayPlanDinners,
  }) : _dinnerReads = PlanWeekDinnerReads(
         mealRepository: mealRepository,
         householdId: householdId,
         week: week,
       ) {
    if (mayPlanDinners) {
      _dinnerReads.start(onChange: notifyListeners, onFailure: _readFailed);
    }
  }

  final WeekPlanner _planner;
  final PlanWeekSaver _saver;
  final PlanWeekGroceries _groceries;
  final PlanWeekDinnerReads _dinnerReads;
  final String householdId;
  final LunchWeek week;

  /// The `meals` grant at edit: only then are dinners offered.
  final bool mayPlanDinners;

  AsyncState<LunchBoard> _board = const AsyncLoading();
  PlanWeekStep _step = PlanWeekStep.choosing;
  PlanWeekOptions? _options;
  PlannedWeek? _planned;
  PlanWeekSaved? _saved;
  AppFailure? _failure;
  int? _groceriesAdded;
  bool _isAddingGroceries = false;

  AsyncState<LunchBoard> get board => _board;
  PlanWeekStep get step => _step;
  PlannedWeek? get planned => _planned;
  PlanWeekSaved? get saved => _saved;
  AppFailure? get failure => _failure;
  int? get groceriesAdded => _groceriesAdded;
  bool get isAddingGroceries => _isAddingGroceries;
  List<Meal> get mealLibrary => _dinnerReads.library ?? const [];
  WeekPlan? get _dinners => _dinnerReads.mealPlan;

  /// Every child chosen and dinners in, until somebody says otherwise.
  PlanWeekOptions get options =>
      _options ??
      PlanWeekOptions(
        childIds: switch (_board) {
          AsyncData(:final value) => {
            for (final child in value.children) child.childId,
          },
          _ => const {},
        },
        includeDinners: mayPlanDinners,
        useWhatsInTheHouse: false,
        budget: PlanBudget.none,
      );

  /// The board, and the meals when dinners can be planned, have answered.
  bool get isReady =>
      _board is AsyncData<LunchBoard> &&
      (!mayPlanDinners || _dinnerReads.hasAnswered);

  void followBoard(AsyncState<LunchBoard> board) {
    if (identical(board, _board)) return;
    _board = board;
    notifyListeners();
  }

  void setOptions(PlanWeekOptions options) {
    _options = options;
    notifyListeners();
  }

  void dismissFailure() {
    if (_failure == null) return;
    _failure = null;
    notifyListeners();
  }

  /// Asks for the week; falls back to the app's own plan when AI cannot help.
  /// [pantryBias] is the pantry's preference when planning from it
  /// (lunch-box ADR-0006) — for the gaps the model leaves, and a plan
  /// without AI.
  Future<void> plan({LunchFillBias? pantryBias}) async {
    final board = _board;
    final chosen = options;
    if (board is! AsyncData<LunchBoard> || _step == PlanWeekStep.planning) {
      return;
    }
    if (!chosen.hasSomethingToPlan) {
      _failure = const PlanWeekFailure(PlanWeekProblem.nothingToPlan);
      notifyListeners();
      return;
    }
    _step = PlanWeekStep.planning;
    _failure = null;
    notifyListeners();
    try {
      final reply = await _planner.plan(
        householdId: householdId,
        week: week,
        options: chosen,
      );
      _show(
        PlannedWeekBuilder.fromReply(
          board: _latestBoard ?? board.value,
          options: chosen,
          reply: reply,
          meals: mealLibrary,
          mealPlan: _dinners,
          bias: chosen.useWhatsInTheHouse ? pantryBias : null,
        ),
      );
    } on AppFailure catch (failure) {
      final reason = _fallbackFor(failure);
      if (reason == null) {
        _step = PlanWeekStep.choosing;
        _failure = failure;
        notifyListeners();
        return;
      }
      _show(
        PlannedWeekBuilder.fallback(
          board: _latestBoard ?? board.value,
          options: chosen,
          meals: mealLibrary,
          mealPlan: _dinners,
          reason: reason,
          mayPlanDinners: mayPlanDinners,
          bias: chosen.useWhatsInTheHouse ? pantryBias : null,
        ),
      );
    }
  }

  void swapLunch(String childId, String slotKey, LunchItem? item) {
    final planned = _planned;
    if (planned == null || _step != PlanWeekStep.review) return;
    _planned = planned.withLunch(
      childId,
      slotKey,
      item == null ? null : PlannedPick(item, PickOrigin.swapped),
    );
    notifyListeners();
  }

  /// Adds a new item to the library and swaps it in — unless it is not safe
  /// for the child, when it is only added (the picker's own rule, lunch-box
  /// ADR-0001).
  Future<void> addAndSwap(
    String childId,
    String slotKey,
    LunchItemDraft draft,
  ) async {
    try {
      final item = await _saver.addToLibrary(draft);
      final rules = _latestBoard?.childWeek(childId)?.child.foodRules;
      if (rules == null) return;
      if (!LunchSafety.isSafe(allergens: item.knownAllergens, rules: rules)) {
        _failure = const LunchFailure(LunchProblem.unsafeForChild);
        notifyListeners();
        return;
      }
      swapLunch(childId, slotKey, item);
    } on AppFailure catch (failure) {
      _failure = failure;
      notifyListeners();
    }
  }

  void setDinner(int day, PlannedDinner? dinner) {
    final planned = _planned;
    if (planned == null || _step != PlanWeekStep.review) return;
    _planned = planned.withDinner(day, dinner);
    notifyListeners();
  }

  /// Writes the plan, under the ordinary rules.
  Future<void> use() async {
    final planned = _planned;
    final board = _latestBoard;
    if (planned == null || board == null || _step != PlanWeekStep.review) {
      return;
    }
    _step = PlanWeekStep.saving;
    _failure = null;
    notifyListeners();
    try {
      _saved = await _saver.save(planned, board: board, mealPlan: _dinners);
      _step = PlanWeekStep.done;
    } on AppFailure catch (failure) {
      _step = PlanWeekStep.review;
      _failure = failure;
    }
    notifyListeners();
  }

  /// The new dinners' ingredients onto the grocery list.
  /// [note] is the reason the list shows beside each line.
  Future<void> addIdeasToGroceries({required String note}) async {
    final planned = _planned;
    if (planned == null || _isAddingGroceries) return;
    _isAddingGroceries = true;
    _failure = null;
    notifyListeners();
    try {
      _groceriesAdded = await _groceries.add(
        planned.ideaIngredients,
        week: week,
        note: note,
      );
    } on AppFailure catch (failure) {
      _failure = failure;
    } finally {
      _isAddingGroceries = false;
      notifyListeners();
    }
  }

  void startOver() {
    _step = PlanWeekStep.choosing;
    _planned = null;
    _saved = null;
    _failure = null;
    _groceriesAdded = null;
    notifyListeners();
  }

  LunchBoard? get _latestBoard => switch (_board) {
    AsyncData(:final value) => value,
    _ => null,
  };

  void _show(PlannedWeek planned) {
    _planned = planned;
    _step = PlanWeekStep.review;
    notifyListeners();
  }

  /// The failures a plan without AI answers; anything else is said as it is.
  static PlanFallbackReason? _fallbackFor(AppFailure failure) =>
      switch (failure) {
        AiFailure(problem: AiProblem.aiSwitchedOff) ||
        PlanWeekFailure(
          problem: PlanWeekProblem.planWeekOff,
        ) => PlanFallbackReason.aiOff,
        AiFailure(problem: AiProblem.aiLimitReached) =>
          PlanFallbackReason.aiLimitReached,
        AiFailure() => PlanFallbackReason.aiUnavailable,
        UnavailableFailure() => PlanFallbackReason.offline,
        _ => null,
      };

  void _readFailed(AppFailure failure) {
    _failure = failure;
    notifyListeners();
  }

  @override
  void dispose() {
    _dinnerReads.close();
    super.dispose();
  }
}
