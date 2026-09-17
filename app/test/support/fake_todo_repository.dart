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

  @override
  Stream<List<Task>> watchTasks(String householdId) => _tasks.stream;

  @override
  Stream<List<Routine>> watchRoutines(String householdId) => _routines.stream;

  @override
  Stream<List<TaskCompletion>> watchCompletions(
    String householdId, {
    required CalendarDate from,
    required CalendarDate to,
  }) {
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
  }) async {
    _refuseIfAsked();
    savedTasks.add((
      taskId: taskId,
      title: title,
      dueDate: dueDate,
      recurrence: recurrence,
      assigneeIds: assigneeIds,
      routineId: routineId,
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
