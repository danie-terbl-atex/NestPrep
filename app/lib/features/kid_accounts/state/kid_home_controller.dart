import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../../shared/time/household_clock.dart';
import '../../accounts/model/kid_identity.dart';
import '../../household/data/household_repository.dart';
import '../../household/model/household_permissions.dart';
import '../../household/model/member.dart';
import '../../meal_planning/data/meal_repository.dart';
import '../../todos/data/todo_repository.dart';
import '../../todos/model/task_occurrence.dart';
import '../model/kid_areas.dart';
import '../model/kid_day.dart';
import 'kid_area_reads.dart';

/// The kid's home (accounts ADR-0003): live reads, each one the rules let
/// this kid device make, joined into one [KidDay].
///
/// Two reads are always open — the household, whose zone decides what "today"
/// is (foundation ADR-0007), and the kid's own profile, whose grant decides
/// which of the others open at all (accounts ADR-0004). A parent who changes
/// the grant changes the profile, and the area reads close and reopen to
/// match, so the device never asks for what it may no longer see.
///
/// A refused read has two meanings. Refused on the household or the profile,
/// a parent has signed this device out — shown as that, in the kid's words,
/// never as an error. Refused on an area, the grant narrowed a moment before
/// the profile said so; the area is shown closed until it does.
final class KidHomeController extends ChangeNotifier with ActionFailureHolder {
  KidHomeController({
    required HouseholdRepository householdRepository,
    required TodoRepository todoRepository,
    required MealRepository mealRepository,
    required this.identity,
    HouseholdClock Function(String timeZone)? clockFor,
  }) : _households = householdRepository,
       _todos = todoRepository,
       _meals = mealRepository,
       _clockFor = clockFor ?? HouseholdClock.new {
    _subscribe();
  }

  final HouseholdRepository _households;
  final TodoRepository _todos;
  final MealRepository _meals;
  final HouseholdClock Function(String timeZone) _clockFor;
  final KidIdentity identity;

  final _subscriptions = <StreamSubscription<Object?>>[];
  late KidAreaReads _reads = _newReads();
  HouseholdClock? _clock;
  Member? _member;

  AsyncState<KidDay> _day = const AsyncLoading();

  AsyncState<KidDay> get day => _day;

  String get _householdId => identity.householdId;
  String get _memberId => identity.memberId;

  /// Ticks a job off, or back on — always as this kid and for this kid, which
  /// is the only completion the rules accept from a kid device.
  Future<void> toggle(TaskOccurrence chore) => runAction(() async {
    if (chore.isDone) {
      await _todos.uncomplete(
        householdId: _householdId,
        taskId: chore.task.id,
        occurrenceDate: chore.date,
      );
      return;
    }
    await _todos.complete(
      householdId: _householdId,
      taskId: chore.task.id,
      occurrenceDate: chore.date,
      completedBy: _memberId,
      completedFor: _memberId,
    );
  });

  Future<void> retry() async {
    await _cancel();
    _reads = _newReads();
    _clock = null;
    _member = null;
    _day = const AsyncLoading();
    notifyListeners();
    _subscribe();
  }

  KidAreaReads _newReads() => KidAreaReads(
    todoRepository: _todos,
    mealRepository: _meals,
    identity: identity,
    onChange: _publish,
    onFailure: _fail,
  );

  /// The two reads that are always open: a refusal on either means a parent
  /// signed this device out.
  void _subscribe() {
    _listen(_households.watchHousehold(_householdId), (household) {
      if (household == null) return _disconnect();
      if (_clock != null) return;
      final clock = _clockFor(household.timeZone);
      _clock = clock;
      _reads.start(clock.today);
      _publish();
    });
    _listen(_households.watchMember(_householdId, _memberId), (member) {
      if (member == null) return _disconnect();
      _member = member;
      _reads.want(KidAreas.of(HouseholdPermissions.kidDevice(member)));
      _publish();
    });
  }

  void _listen<T>(Stream<T> stream, void Function(T value) onValue) {
    _subscriptions.add(
      stream.listen(
        onValue,
        onError: (Object error) {
          final failure = error is AppFailure ? error : UnknownFailure(error);
          if (failure is PermissionDeniedFailure ||
              failure is SessionExpiredFailure) {
            return _disconnect();
          }
          _fail(failure);
        },
      ),
    );
  }

  void _publish() {
    final (clock, member) = (_clock, _member);
    if (clock == null || member == null) return;
    final day = _reads.dayFor(member, clock.today);
    if (day == null) return;
    _day = AsyncData(day);
    notifyListeners();
  }

  void _fail(AppFailure failure) {
    // An area refused after the session itself ended is the same sign-out.
    if (failure is SessionExpiredFailure) return _disconnect();
    _day = AsyncFailure(failure);
    notifyListeners();
  }

  void _disconnect() {
    _day = const AsyncFailure(
      KidSignInFailure(KidSignInProblem.deviceDisconnected),
    );
    notifyListeners();
    unawaited(_cancel());
  }

  Future<void> _cancel() async {
    final subscriptions = [..._subscriptions];
    _subscriptions.clear();
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    await _reads.close();
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
