import 'dart:async';

import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/todos/data/todo_repository.dart';
import 'package:nestprep/features/todos/model/routine.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/model/task_completion.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/recurrence/recurrence_rule.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// The three todo reads, driven by hand.
final class FakeTodoRepository implements TodoRepository {
  final _tasks = StreamController<List<Task>>.broadcast();
  final _routines = StreamController<List<Routine>>.broadcast();
  final _completions = StreamController<List<TaskCompletion>>.broadcast();

  AppFailure? failWritesWith;

  CalendarDate? completionsFrom;
  CalendarDate? completionsTo;

  final completed =
      <({String taskId, CalendarDate date, String by, String forMember})>[];
  final uncompleted = <({String taskId, CalendarDate date})>[];
  final savedTasks =
      <
        ({
          String? taskId,
          String title,
          CalendarDate dueDate,
          RecurrenceRule? recurrence,
          List<String> assigneeIds,
          String? routineId,
          int points,
          bool needsApproval,
        })
      >[];
  final deletedTasks = <String>[];
  final savedRoutines =
      <
        ({
          String? routineId,
          String name,
          CalendarDate firstDate,
          RecurrenceRule? recurrence,
          List<String> defaultAssigneeIds,
          MemberColor color,
        })
      >[];
  final deletedRoutines = <String>[];

  void emitTasks(List<Task> tasks) => _tasks.add(tasks);
  void emitRoutines(List<Routine> routines) => _routines.add(routines);
  void emitCompletions(List<TaskCompletion> completions) =>
      _completions.add(completions);
  void failTasksWith(Object error) => _tasks.addError(error);

  Future<void> close() async {
    await _tasks.close();
    await _routines.close();
    await _completions.close();
  }

  /// What the last `watchTasks` and `watchCompletions` were narrowed to.
  String? tasksAssignedTo;
  String? completionsFor;
  var routinesWatched = 0;

  @override
  Stream<List<Task>> watchTasks(String householdId, {String? assignedTo}) {
    tasksAssignedTo = assignedTo;
    return _tasks.stream;
  }

  @override
  Stream<List<Routine>> watchRoutines(String householdId) {
    routinesWatched += 1;
    return _routines.stream;
  }

  @override
  Stream<List<TaskCompletion>> watchCompletions(
    String householdId, {
    required CalendarDate from,
    required CalendarDate to,
    String? completedFor,
  }) {
    completionsFor = completedFor;
    completionsFrom = from;
    completionsTo = to;
    return _completions.stream;
  }

  /// Whose tasks and completions a kid's read asked for (accounts ADR-0003).
  String? tasksForMemberId;
  String? completionsForMemberId;

  /// How many times a kid's own tasks were asked for — a grant that did not
  /// change must not reopen them (accounts ADR-0004).
  var tasksForWatched = 0;

  @override
  Stream<List<Task>> watchTasksFor(String householdId, String memberId) {
    tasksForMemberId = memberId;
    tasksForWatched++;
    return _tasks.stream;
  }

  @override
  Stream<List<TaskCompletion>> watchCompletionsFor(
    String householdId,
    String memberId, {
    required CalendarDate from,
    required CalendarDate to,
  }) {
    completionsForMemberId = memberId;
    completionsFrom = from;
    completionsTo = to;
    return _completions.stream;
  }

  @override
  Future<void> saveTask({
    required String householdId,
    String? taskId,
    required String title,
    String? note,
    required CalendarDate dueDate,
    RecurrenceRule? recurrence,
    required List<String> assigneeIds,
    required String createdBy,
    String? routineId,
    int points = 0,
    bool needsApproval = false,
  }) async {
    _refuseIfAsked();
    savedTasks.add((
      taskId: taskId,
      title: title,
      dueDate: dueDate,
      recurrence: recurrence,
      assigneeIds: assigneeIds,
      routineId: routineId,
      points: points,
      needsApproval: needsApproval,
    ));
  }

  @override
  Future<void> deleteTask({
    required String householdId,
    required String taskId,
  }) async {
    _refuseIfAsked();
    deletedTasks.add(taskId);
  }

  @override
  Future<void> complete({
    required String householdId,
    required String taskId,
    required CalendarDate occurrenceDate,
    required String completedBy,
    required String completedFor,
  }) async {
    _refuseIfAsked();
    completed.add((
      taskId: taskId,
      date: occurrenceDate,
      by: completedBy,
      forMember: completedFor,
    ));
  }

  @override
  Future<void> uncomplete({
    required String householdId,
    required String taskId,
    required CalendarDate occurrenceDate,
  }) async {
    _refuseIfAsked();
    uncompleted.add((taskId: taskId, date: occurrenceDate));
  }

  @override
  Future<void> saveRoutine({
    required String householdId,
    String? routineId,
    required String name,
    required CalendarDate firstDate,
    RecurrenceRule? recurrence,
    required List<String> defaultAssigneeIds,
    required MemberColor color,
    required String createdBy,
  }) async {
    _refuseIfAsked();
    savedRoutines.add((
      routineId: routineId,
      name: name,
      firstDate: firstDate,
      recurrence: recurrence,
      defaultAssigneeIds: defaultAssigneeIds,
      color: color,
    ));
  }

  @override
  Future<void> deleteRoutine({
    required String householdId,
    required String routineId,
  }) async {
    _refuseIfAsked();
    deletedRoutines.add(routineId);
  }

  void _refuseIfAsked() {
    final failure = failWritesWith;
    if (failure != null) throw failure;
  }
}
