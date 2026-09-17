import '../../../shared/recurrence/recurrence_rule.dart';
import '../../../shared/time/calendar_date.dart';
import 'routine.dart';
import 'task.dart';
import 'task_completion.dart';

/// One task on one day, with whether it has been done. This is what every todo
/// view is a list of — the task itself is never rendered directly, because a
/// repeating task is not one thing on a screen (foundation ADR-0005).
class TaskOccurrence {
  const TaskOccurrence({
    required this.task,
    required this.date,
    required this.assigneeIds,
    this.routine,
    this.completion,
  });

  final Task task;
  final CalendarDate date;

  /// Who this occurrence is for, after a routine's defaults have been applied.
  /// Empty means anyone.
  final List<String> assigneeIds;

  final Routine? routine;
  final TaskCompletion? completion;

  bool get isDone => completion != null;

  bool get isForAnyone => assigneeIds.isEmpty;

  bool isFor(String memberId) => isForAnyone || assigneeIds.contains(memberId);

  bool isOverdue(CalendarDate today) => !isDone && date.isBefore(today);

  /// The stable identity of this row across rebuilds: the same task on the same
  /// day is the same row (`FE-11`).
  String get key => TaskCompletion.idFor(task.id, date);
}

/// What a task's schedule actually is, once its routine has had its say
/// (todos ADR-0001). A task in a routine follows the routine's rule and its
/// first date; it keeps its own assignees only if it named any.
({CalendarDate firstDate, RecurrenceRule? rule, List<String> assigneeIds})
scheduleFor(Task task, Routine? routine) {
  if (routine == null) {
    return (
      firstDate: task.dueDate,
      rule: task.recurrence,
      assigneeIds: task.assigneeIds,
    );
  }
  return (
    firstDate: routine.firstDate,
    rule: routine.recurrence,
    assigneeIds: task.assigneeIds.isEmpty
        ? routine.defaultAssigneeIds
        : task.assigneeIds,
  );
}
