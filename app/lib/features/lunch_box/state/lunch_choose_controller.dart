import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../data/lunch_choices_repository.dart';
import '../data/lunch_repository.dart';
import '../model/lunch_choice_day.dart';
import '../model/lunch_choices.dart';
import '../model/lunch_pick.dart';
import '../model/lunch_plan.dart';
import '../model/lunch_slot.dart';
import '../model/lunch_week.dart';

/// A child choosing their own box (lunch-box ADR-0008) — on their own
/// device, or on a parent's phone handed over. Two reads, each exactly one
/// document the kid's `own` grant opens: their plan for the week and their
/// options for it.
///
/// It is told what today is — by [follow], or by [todays] when it is given
/// one — because a kid device learns its household's zone from the
/// household, and a parent's phone has it from the household clock.
final class LunchChooseController extends ChangeNotifier
    with ActionFailureHolder {
  LunchChooseController({
    required LunchRepository lunchRepository,
    required this._choicesRepository,
    required this.householdId,
    required this.childId,
    Stream<CalendarDate>? todays,
  }) : _plans = lunchRepository {
    if (todays != null) {
      _todaySubscription = todays.listen(
        (today) => follow(today: today),
        onError: _onError,
      );
    }
  }

  final LunchRepository _plans;
  final LunchChoicesRepository _choicesRepository;
  final String householdId;
  final String childId;

  final _subscriptions = <StreamSubscription<Object?>>[];
  StreamSubscription<CalendarDate>? _todaySubscription;
  CalendarDate? _today;
  LunchWeek? _week;
  LunchPlan? _plan;
  LunchChoices? _choices;
  AppFailure? _readFailure;
  int _celebrations = 0;

  AsyncState<List<LunchChoiceDay>> _days = const AsyncLoading();

  /// The days from today on with something to choose, or none.
  AsyncState<List<LunchChoiceDay>> get days => _days;

  LunchWeek? get week => _week;

  /// Goes up each time a choice finishes a whole day — what the star burst
  /// plays on.
  int get celebrations => _celebrations;

  /// What today is, and whether there is anything to show at all. [week]
  /// defaults to the week being planned on [today].
  void follow({
    required CalendarDate? today,
    bool show = true,
    LunchWeek? week,
  }) {
    if (today == null || !show) {
      if (_week == null && _days is AsyncData) return;
      _close();
      _week = null;
      _days = const AsyncData([]);
      notifyListeners();
      return;
    }
    _today = today;
    final wanted = week ?? LunchWeek.planningFor(today);
    if (wanted == _week) return _publish();
    _week = wanted;
    _open(wanted);
  }

  /// [pick] goes in [slot] on [isoWeekday], if it is one of that slot's
  /// options — the rules refuse anything else.
  Future<void> choose({
    required int isoWeekday,
    required LunchSlot slot,
    required LunchPick pick,
  }) async {
    final week = _week;
    final choices = _choices;
    if (week == null || choices == null) return;
    final options = choices.optionsAt(isoWeekday, slot);
    if (!options.any((option) => option.itemId == pick.itemId)) return;
    final day = _dayOf(isoWeekday);
    final finishesDay =
        day != null &&
        day.slots.every((entry) => entry.isChosen || entry.slot == slot);
    // The choice shows the moment it is made — the phone's own copy answers
    // first — so the celebration does not wait for the server either.
    if (finishesDay) {
      _celebrations++;
      notifyListeners();
    }
    await runAction(() async {
      try {
        await _choicesRepository.choose(
          householdId: householdId,
          childId: childId,
          week: week,
          isoWeekday: isoWeekday,
          slot: slot,
          pick: options.firstWhere((option) => option.itemId == pick.itemId),
        );
      } on PermissionDeniedFailure {
        throw const LunchPlanningFailure(LunchPlanningProblem.notAnOption);
      }
    });
  }

  Future<void> retry() async {
    final week = _week;
    if (week == null) return;
    _open(week);
  }

  LunchChoiceDay? _dayOf(int isoWeekday) => switch (_days) {
    AsyncData(:final value) =>
      value.where((day) => day.date.weekday == isoWeekday).firstOrNull,
    _ => null,
  };

  void _open(LunchWeek week) {
    _close();
    _plan = null;
    _choices = null;
    _readFailure = null;
    _days = const AsyncLoading();
    notifyListeners();
    _subscriptions
      ..add(
        _plans.watchPlan(householdId, childId: childId, week: week).listen((
          plan,
        ) {
          if (week != _week) return;
          _plan = plan;
          _publish();
        }, onError: _onError),
      )
      ..add(
        _choicesRepository
            .watchChoices(householdId, childId: childId, week: week)
            .listen((choices) {
              if (week != _week) return;
              _choices = choices;
              _publish();
            }, onError: _onError),
      );
  }

  void _publish() {
    final (plan, choices, week, today) = (_plan, _choices, _week, _today);
    final failure = _readFailure;
    if (failure != null) {
      _days = AsyncFailure(failure);
    } else if (plan != null &&
        choices != null &&
        week != null &&
        today != null) {
      _days = AsyncData(
        LunchChoiceDay.ahead(
          choices: choices,
          plan: plan,
          week: week,
          today: today,
        ),
      );
    }
    notifyListeners();
  }

  void _onError(Object error) {
    _readFailure = error is AppFailure ? error : UnknownFailure(error);
    _publish();
  }

  void _close() {
    final subscriptions = [..._subscriptions];
    _subscriptions.clear();
    for (final subscription in subscriptions) {
      unawaited(subscription.cancel());
    }
  }

  @override
  void dispose() {
    unawaited(_todaySubscription?.cancel());
    _close();
    super.dispose();
  }
}
