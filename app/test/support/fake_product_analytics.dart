import 'dart:async';

import 'package:nestprep/features/product_analytics/data/activity_recorder.dart';
import 'package:nestprep/features/product_analytics/data/beta_numbers_repository.dart';
import 'package:nestprep/features/product_analytics/model/weekly_numbers.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// Stands in for the `analyticsWeeks` listener and the reader-claim check, so
/// a test drives the numbers by hand and nothing pumps the SDK.
final class FakeBetaNumbersRepository implements BetaNumbersRepository {
  FakeBetaNumbersRepository({this.isReader = false});

  final _weeks = StreamController<List<WeeklyNumbers>>.broadcast();

  /// What `canRead` answers.
  bool isReader;

  /// Set to make `canRead` fail, the way an expired token does.
  Exception? failCanReadWith;

  void emitWeeks(List<WeeklyNumbers> weeks) => _weeks.add(weeks);
  void failWeeksWith(Object error) => _weeks.addError(error);

  Future<void> close() => _weeks.close();

  @override
  Stream<List<WeeklyNumbers>> watchRecentWeeks() => _weeks.stream;

  @override
  Future<bool> canRead() async {
    final failure = failCanReadWith;
    if (failure != null) throw failure;
    return isReader;
  }
}

/// Records every "this household was opened" the app sends.
final class FakeActivityRecorder implements ActivityRecorder {
  final recorded = <String>[];

  /// Set to make the next calls fail, the way an offline phone does.
  Exception? failWith;

  /// Set to hold every call open until the test completes it.
  Completer<void>? gate;

  @override
  Future<void> recordActivity(String householdId) async {
    recorded.add(householdId);
    final pending = gate;
    if (pending != null) await pending.future;
    final failure = failWith;
    if (failure != null) throw failure;
  }
}

/// A week of numbers, with only what a test cares about set.
WeeklyNumbers weekOf(
  String week,
  CalendarDate monday, {
  int activeFamilies = 0,
  int familiesSeen = 0,
  int lunchPlansCreated = 0,
  int familiesPlanningLunches = 0,
  int newFamilies = 0,
  int newFamiliesInvitingAnAdult = 0,
  bool isInviteCohortComplete = false,
  DateTime? computedAt,
}) => WeeklyNumbers(
  week: week,
  weekStart: monday,
  activeFamilies: activeFamilies,
  familiesSeen: familiesSeen,
  lunchPlansCreated: lunchPlansCreated,
  familiesPlanningLunches: familiesPlanningLunches,
  newFamilies: newFamilies,
  newFamiliesInvitingAnAdult: newFamiliesInvitingAnAdult,
  isInviteCohortComplete: isInviteCohortComplete,
  computedAt: computedAt,
);
