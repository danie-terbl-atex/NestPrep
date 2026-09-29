import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../data/lunch_choices_repository.dart';
import '../model/lunch_board.dart';
import '../model/lunch_choice_suggestions.dart';
import '../model/lunch_choices.dart';
import '../model/lunch_item.dart';
import '../model/lunch_pick.dart';
import '../model/lunch_plan.dart';
import '../model/lunch_safety.dart';
import '../model/lunch_slot.dart';
import '../model/lunch_week.dart';

/// A parent's side of kid picks (lunch-box ADR-0008): every child's options
/// for the week the lunch board is on — one read of its own — and the writes
/// that approve them. Every option is checked against the child's rules here
/// so the parent hears why; the rules refuse an unsafe one regardless.
final class LunchChoicesController extends ChangeNotifier
    with ActionFailureHolder {
  LunchChoicesController({
    required LunchChoicesRepository choicesRepository,
    required this.householdId,
    required this.memberId,
  }) : _repository = choicesRepository;

  final LunchChoicesRepository _repository;
  final String householdId;
  final String memberId;

  StreamSubscription<List<LunchChoices>>? _subscription;
  LunchWeek? _week;
  AsyncState<LunchBoard> _board = const AsyncLoading();
  List<LunchChoices>? _choices;
  AppFailure? _readFailure;
  bool _isSuggesting = false;

  /// Child id → their options this week; a child with none is absent.
  AsyncState<Map<String, LunchChoices>> _state = const AsyncLoading();

  AsyncState<Map<String, LunchChoices>> get choices => _state;

  bool get isSuggesting => _isSuggesting;

  /// One child's options this week, or none.
  LunchChoices choicesFor(String childId, LunchWeek week) => switch (_state) {
    AsyncData(:final value) =>
      value[childId] ?? LunchChoices.none(childId: childId, week: week),
    _ => LunchChoices.none(childId: childId, week: week),
  };

  void followBoard(AsyncState<LunchBoard> board, LunchWeek week) {
    if (week != _week) {
      _week = week;
      _choices = null;
      _state = const AsyncLoading();
      _listen(week);
    }
    if (identical(board, _board)) return;
    _board = board;
    _publish();
  }

  /// Approves [items] as one slot's options — two or three of them.
  Future<void> setOptions({
    required LunchChildWeek childWeek,
    required int isoWeekday,
    required LunchSlot slot,
    required List<LunchItem> items,
  }) async {
    if (items.length < LunchChoices.fewestOptions ||
        items.length > LunchChoices.mostOptions) {
      recordFailure(
        const LunchPlanningFailure(LunchPlanningProblem.wrongNumberOfOptions),
      );
      return;
    }
    final picks = [for (final item in items) LunchPick.of(item)];
    if (!_areSafe(childWeek, picks)) return;
    await _write(childWeek.childId, isoWeekday, {
      LunchPlan.slotKey(isoWeekday, slot): picks,
    });
  }

  Future<void> clearOptions({
    required String childId,
    required int isoWeekday,
    required LunchSlot slot,
  }) =>
      _write(childId, isoWeekday, {LunchPlan.slotKey(isoWeekday, slot): null});

  /// Offers the child's top three for every empty compartment from today
  /// on, a day per write so each stays small for the rules.
  Future<void> suggestWeek(LunchChildWeek childWeek) async {
    final board = _board;
    final week = _week;
    if (_isSuggesting || board is! AsyncData<LunchBoard> || week == null) {
      return;
    }
    final byDay = LunchChoiceSuggestions.forWeek(
      board: board.value,
      childWeek: childWeek,
      choices: choicesFor(childWeek.childId, week),
      today: board.value.today,
    );
    _isSuggesting = true;
    notifyListeners();
    try {
      for (final MapEntry(key: weekday, value: day) in byDay.entries) {
        await _write(childWeek.childId, weekday, day);
        if (actionFailure != null) break;
      }
    } finally {
      _isSuggesting = false;
      notifyListeners();
    }
  }

  bool _areSafe(LunchChildWeek childWeek, List<LunchPick> picks) {
    final isSafe = picks.every(
      (pick) => LunchSafety.isSafe(
        allergens: pick.knownAllergens,
        rules: childWeek.child.foodRules,
      ),
    );
    if (!isSafe) {
      recordFailure(const LunchFailure(LunchProblem.unsafeForChild));
    }
    return isSafe;
  }

  Future<void> _write(
    String childId,
    int isoWeekday,
    Map<String, List<LunchPick>?> options,
  ) {
    final week = _week;
    if (week == null) return Future.value();
    return runAction(() async {
      try {
        await _repository.setOptions(
          householdId: householdId,
          childId: childId,
          week: week,
          isoWeekday: isoWeekday,
          options: options,
          by: memberId,
        );
      } on PermissionDeniedFailure {
        throw const LunchPlanningFailure(LunchPlanningProblem.optionNotSafe);
      }
    });
  }

  Future<void> retry() async {
    final week = _week;
    _readFailure = null;
    _choices = null;
    _state = const AsyncLoading();
    notifyListeners();
    if (week != null) _listen(week);
  }

  void _listen(LunchWeek week) {
    unawaited(_subscription?.cancel());
    _subscription = _repository.watchWeek(householdId, week).listen((choices) {
      if (week != _week) return;
      _choices = choices;
      _publish();
    }, onError: _onError);
  }

  void _publish() {
    final failure = _readFailure;
    final board = _board;
    final choices = _choices;
    if (failure != null) {
      _state = AsyncFailure(failure);
    } else if (board is AsyncFailure<LunchBoard>) {
      _state = AsyncFailure(board.failure);
    } else if (choices != null && board is AsyncData<LunchBoard>) {
      _state = AsyncData({for (final entry in choices) entry.childId: entry});
    }
    notifyListeners();
  }

  void _onError(Object error) {
    _readFailure = error is AppFailure ? error : UnknownFailure(error);
    _publish();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
