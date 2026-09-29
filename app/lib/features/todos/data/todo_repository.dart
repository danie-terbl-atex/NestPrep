import '../../../design/tokens/nest_member_palette.dart';
import '../../../shared/recurrence/recurrence_rule.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/routine.dart';
import '../model/task.dart';
import '../model/task_completion.dart';

/// What the todos feature needs from Firestore.
///
/// Tasks and routines are read whole — one household has tens of them, not
/// thousands, and a recurring task has to be read whatever window is showing
/// (foundation ADR-0005). Completions are the one read that grows without
/// bound, so that one is windowed (`BE-08`).
abstract interface class TodoRepository {
  /// Every task, or — with [assignedTo] — only the ones that name that
  /// member. A kid, helper or carer whose to-dos are `own` may read nothing
  /// else, and a rule is not a filter, so the query has to ask for exactly
  /// that (household ADR-0003).
  Stream<List<Task>> watchTasks(String householdId, {String? assignedTo});

  Stream<List<Routine>> watchRoutines(String householdId);

  /// What has been done between two days, inclusive — for one member only,
  /// with [completedFor], for the same reason as `watchTasks`.
  Stream<List<TaskCompletion>> watchCompletions(
    String householdId, {
    required CalendarDate from,
    required CalendarDate to,
    String? completedFor,
  });

  /// The tasks that name one member — the only task read a kid device may
  /// make, because the rules let it see nothing else (accounts ADR-0003).
  Stream<List<Task>> watchTasksFor(String householdId, String memberId);

  /// What has been done *for* one member between two days, inclusive — a kid
  /// device's own ticks and the ones a parent made on its behalf.
  Stream<List<TaskCompletion>> watchCompletionsFor(
    String householdId,
    String memberId, {
    required CalendarDate from,
    required CalendarDate to,
  });

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
  });

  Future<void> deleteTask({
    required String householdId,
    required String taskId,
  });

  /// Marks one occurrence done. Writing the same occurrence twice is the same
  /// write, because the document id is derived from it (`BE-06`).
  Future<void> complete({
    required String householdId,
    required String taskId,
    required CalendarDate occurrenceDate,
    required String completedBy,
    required String completedFor,
  });

  Future<void> uncomplete({
    required String householdId,
    required String taskId,
    required CalendarDate occurrenceDate,
  });

  Future<void> saveRoutine({
    required String householdId,
    String? routineId,
    required String name,
    required CalendarDate firstDate,
    RecurrenceRule? recurrence,
    required List<String> defaultAssigneeIds,
    required MemberColor color,
    required String createdBy,
  });

  Future<void> deleteRoutine({
    required String householdId,
    required String routineId,
  });

  /// A household's tasks are few; this cap exists so a bug cannot make the read
  /// unbounded (`BE-08`).
  static const taskLimit = 500;
}
