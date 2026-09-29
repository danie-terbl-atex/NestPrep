import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../design/tokens/nest_member_palette.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/recurrence/recurrence_rule.dart';
import '../../../shared/state/action_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/time/household_clock.dart';
import '../data/todo_repository.dart';
import '../model/occurrence_selector.dart';
import '../model/routine.dart';
import '../model/task.dart';
import '../model/task_completion.dart';
import '../model/task_occurrence.dart';
import '../model/todo_board.dart';

/// The todos screen's controller: three live reads become one board. The
/// completions read is windowed, so the window has to be decided before the
/// listener opens — it is the overdue horizon behind today and a fortnight
/// ahead, which is as far as either view looks.
final class TodoController extends ChangeNotifier with ActionFailureHolder {
  TodoController({
    required TodoRepository todoRepository,
    required HouseholdClock householdClock,
    required this.householdId,
    required this.memberId,
    required this.isAdmin,
    this.isOwnOnly = false,
    this.canEdit = true,
  }) : _repository = todoRepository,
       _clock = householdClock {
    _subscribe();
  }

  /// How far ahead the household view looks. Everything else is behind today.
  static const lookaheadDays = 14;

  final TodoRepository _repository;
  final HouseholdClock _clock;
  final String householdId;
  final String memberId;
  final bool isAdmin;

  /// A kid, helper or carer who may see only their own to-dos: the reads ask
  /// for exactly those, and there are no routines, which schedule everybody
  /// (household ADR-0003).
  final bool isOwnOnly;

  /// Whether this person may add and change tasks, rather than only tick
  /// their own. The rules decide; this only hides what they would refuse.
  final bool canEdit;

  /// Ticking off is what `own` is for; `view` only looks.
  bool get canTick => canEdit || isOwnOnly;

  StreamSubscription<List<Task>>? _taskSubscription;
  StreamSubscription<List<Routine>>? _routineSubscription;
  StreamSubscription<List<TaskCompletion>>? _completionSubscription;

  List<Task>? _tasks;
  List<Routine>? _routines;
  List<TaskCompletion>? _completions;

  AsyncState<TodoBoard> _board = const AsyncLoading();
  String? _memberFilter;

  AsyncState<TodoBoard> get board => _board;

  /// Which member the household view is filtered to, or null for everyone.
  String? get memberFilter => _memberFilter;

  CalendarDate get today => _clock.today;
  CalendarDate get windowStart => today.addDays(-overdueWindowDays);
  CalendarDate get windowEnd => today.addDays(lookaheadDays);

  void filterBy(String? memberId) {
    if (_memberFilter == memberId) return;
    _memberFilter = memberId;
    notifyListeners();
  }

  Future<void> retry() async {
    await _cancel();
    _tasks = null;
    _routines = null;
    _completions = null;
    _board = const AsyncLoading();
    notifyListeners();
    _subscribe();
  }

  /// Ticks an occurrence off. [forMemberId] differs from the acting member only
  /// when an admin completes on behalf of somebody, which the rules also check
  /// (household ADR-0001).
  Future<void> setDone(
    TaskOccurrence occurrence, {
    required bool isDone,
    String? forMemberId,
  }) => runAction(() async {
    if (!isDone) {
      await _repository.uncomplete(
        householdId: householdId,
        taskId: occurrence.task.id,
        occurrenceDate: occurrence.date,
      );
      return;
    }
    await _repository.complete(
      householdId: householdId,
      taskId: occurrence.task.id,
      occurrenceDate: occurrence.date,
      completedBy: memberId,
      completedFor: forMemberId ?? memberId,
    );
  });

  Future<void> saveTask({
    String? taskId,
    required String title,
    String? note,
    required CalendarDate dueDate,
    RecurrenceRule? recurrence,
    required List<String> assigneeIds,
    String? routineId,
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return Future.value();
    return runAction(
      () => _repository.saveTask(
        householdId: householdId,
        taskId: taskId,
        title: trimmed,
        note: note?.trim().isEmpty ?? true ? null : note?.trim(),
        dueDate: dueDate,
        recurrence: recurrence,
        assigneeIds: assigneeIds,
        createdBy: memberId,
        routineId: routineId,
      ),
    );
  }

  Future<void> deleteTask(String taskId) => runAction(
    () => _repository.deleteTask(householdId: householdId, taskId: taskId),
  );

  Future<void> saveRoutine({
    String? routineId,
    required String name,
    required CalendarDate firstDate,
    RecurrenceRule? recurrence,
    required List<String> defaultAssigneeIds,
    required MemberColor color,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return Future.value();
    return runAction(
      () => _repository.saveRoutine(
        householdId: householdId,
        routineId: routineId,
        name: trimmed,
        firstDate: firstDate,
        recurrence: recurrence,
        defaultAssigneeIds: defaultAssigneeIds,
        color: color,
        createdBy: memberId,
      ),
    );
  }

  Future<void> deleteRoutine(String routineId) => runAction(
    () => _repository.deleteRoutine(
      householdId: householdId,
      routineId: routineId,
    ),
  );

  void _subscribe() {
    final onlyMine = isOwnOnly ? memberId : null;
    _taskSubscription = _repository
        .watchTasks(householdId, assignedTo: onlyMine)
        .listen((tasks) {
          _tasks = tasks;
          _publish();
        }, onError: _onError);
    // `own` reads the routines too, so a chore of theirs follows its
    // routine's schedule (accounts ADR-0004).
    _routineSubscription = _repository.watchRoutines(householdId).listen((
      routines,
    ) {
      _routines = routines;
      _publish();
    }, onError: _onError);
    _completionSubscription = _repository
        .watchCompletions(
          householdId,
          from: windowStart,
          to: windowEnd,
          completedFor: onlyMine,
        )
        .listen((completions) {
          _completions = completions;
          _publish();
        }, onError: _onError);
  }

  void _publish() {
    final tasks = _tasks;
    final routines = _routines;
    final completions = _completions;
    if (tasks == null || routines == null || completions == null) return;
    _board = AsyncData(
      TodoBoard.from(
        occurrences: selectOccurrences(
          tasks: tasks,
          routines: routines,
          completions: completions,
          from: windowStart,
          to: windowEnd,
        ),
        routines: routines,
        memberId: memberId,
        today: today,
      ),
    );
    notifyListeners();
  }

  void _onError(Object error) {
    _board = AsyncFailure(error is AppFailure ? error : UnknownFailure(error));
    notifyListeners();
  }

  Future<void> _cancel() async {
    await _taskSubscription?.cancel();
    await _routineSubscription?.cancel();
    await _completionSubscription?.cancel();
    _taskSubscription = null;
    _routineSubscription = null;
    _completionSubscription = null;
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
