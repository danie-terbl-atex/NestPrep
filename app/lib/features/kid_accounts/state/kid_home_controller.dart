import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../../shared/time/household_clock.dart';
import '../../accounts/model/kid_identity.dart';
import '../../household/data/household_repository.dart';
import '../../household/model/household.dart';
import '../../household/model/member.dart';
import '../../meal_planning/data/meal_repository.dart';
import '../../meal_planning/model/meal.dart';
import '../../meal_planning/model/week_plan.dart';
import '../../todos/data/todo_repository.dart';
import '../../todos/model/routine.dart';
import '../../todos/model/task.dart';
import '../../todos/model/task_completion.dart';
import '../../todos/model/task_occurrence.dart';
import '../model/kid_day.dart';

/// The kid's home (accounts ADR-0003): seven live reads, each one the rules let
/// a kid device make, joined into one [KidDay].
///
/// The household comes first because its zone decides what "today" is, and
/// the windowed reads cannot open until they know (foundation ADR-0007). A read
/// the rules refuse means a parent has signed this device out — it is shown as
/// that, in the kid's words, and never as an error.
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
  HouseholdClock? _clock;
  Member? _member;
  List<Task>? _tasks;
  List<Routine>? _routines;
  List<TaskCompletion>? _completions;
  WeekPlan? _plan;
  List<Meal>? _library;

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
    _clock = null;
    _member = null;
    _tasks = null;
    _routines = null;
    _completions = null;
    _plan = null;
    _library = null;
    _day = const AsyncLoading();
    notifyListeners();
    _subscribe();
  }

  void _subscribe() {
    _listen(_households.watchHousehold(_householdId), _onHousehold);
    _listen(_households.watchMember(_householdId, _memberId), (member) {
      if (member == null) return _disconnect();
      _member = member;
      _publish();
    });
  }

  void _onHousehold(Household? household) {
    if (household == null) return _disconnect();
    if (_clock != null) return;
    final clock = _clockFor(household.timeZone);
    _clock = clock;
    final today = clock.today;
    _listen(_todos.watchTasksFor(_householdId, _memberId), (tasks) {
      _tasks = tasks;
      _publish();
    });
    _listen(_todos.watchRoutines(_householdId), (routines) {
      _routines = routines;
      _publish();
    });
    _listen(
      _todos.watchCompletionsFor(
        _householdId,
        _memberId,
        from: KidDay.windowStartFor(today),
        to: today,
      ),
      (completions) {
        _completions = completions;
        _publish();
      },
    );
    _listen(_meals.watchWeek(_householdId, today.weekStart), (plan) {
      _plan = plan;
      _publish();
    });
    _listen(_meals.watchMeals(_householdId), (library) {
      _library = library;
      _publish();
    });
  }

  void _listen<T>(Stream<T> stream, void Function(T value) onValue) {
    _subscriptions.add(stream.listen(onValue, onError: _onError));
  }

  void _publish() {
    final (clock, member, tasks, routines, completions, plan, library) = (
      _clock,
      _member,
      _tasks,
      _routines,
      _completions,
      _plan,
      _library,
    );
    if (clock == null ||
        member == null ||
        tasks == null ||
        routines == null ||
        completions == null ||
        plan == null ||
        library == null) {
      return;
    }
    _day = AsyncData(
      KidDay.from(
        me: member,
        today: clock.today,
        tasks: tasks,
        routines: routines,
        completions: completions,
        plan: plan,
        library: library,
      ),
    );
    notifyListeners();
  }

  /// A refused read on a kid device has one cause worth naming: a parent took
  /// this device out of the household, or removed the profile it was.
  void _onError(Object error) {
    final failure = error is AppFailure ? error : UnknownFailure(error);
    if (failure is PermissionDeniedFailure ||
        failure is SessionExpiredFailure) {
      return _disconnect();
    }
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
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
