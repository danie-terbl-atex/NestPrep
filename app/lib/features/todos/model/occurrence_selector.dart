import '../../../shared/recurrence/recurrence_expansion.dart';
import '../../../shared/time/calendar_date.dart';
import 'routine.dart';
import 'task.dart';
import 'task_completion.dart';
import 'task_occurrence.dart';

/// Joins the three things a todo view needs — the tasks, the schedules their
/// routines impose, and what has already been done — into the rows a screen
/// renders (todos ADR-0001, foundation ADR-0005).
///
/// Pure, and the only place that join happens, so both views and the routine
/// page agree about what "done" and "overdue" mean.
List<TaskOccurrence> selectOccurrences({
  required List<Task> tasks,
  required List<Routine> routines,
  required List<TaskCompletion> completions,
  required CalendarDate from,
  required CalendarDate to,
}) {
  final routinesById = {for (final routine in routines) routine.id: routine};
  final completionsByKey = {
    for (final completion in completions)
      TaskCompletion.idFor(completion.taskId, completion.occurrenceDate):
          completion,
  };

  final occurrences = <TaskOccurrence>[];
  for (final task in tasks) {
    final routine = task.routineId == null
        ? null
        : routinesById[task.routineId];
    final schedule = scheduleFor(task, routine);
    final days = expandOccurrences(
      firstDate: schedule.firstDate,
      rule: schedule.rule,
      windowStart: from,
      windowEnd: to,
    );
    for (final day in days) {
      occurrences.add(
        TaskOccurrence(
          task: task,
          date: day,
          assigneeIds: schedule.assigneeIds,
          routine: routine,
          completion: completionsByKey[TaskCompletion.idFor(task.id, day)],
        ),
      );
    }
  }

  occurrences.sort(_byDateThenTitle);
  return occurrences;
}

/// What a person is being asked to do today: today's occurrences plus the ones
/// they have let slip — but only recently, so an abandoned weekly task does not
/// bury the list (todos ADR-0001).
///
/// `from` for the caller's window should be `today.addDays(-overdueWindowDays)`.
List<TaskOccurrence> mineToday({
  required List<TaskOccurrence> occurrences,
  required String memberId,
  required CalendarDate today,
}) => [
  for (final occurrence in occurrences)
    if (occurrence.isFor(memberId) &&
        !occurrence.isDone &&
        !occurrence.date.isAfter(today))
      occurrence,
];

/// How far back an unfinished occurrence keeps asking (todos ADR-0001).
const overdueWindowDays = 7;

int _byDateThenTitle(TaskOccurrence a, TaskOccurrence b) {
  final byDate = a.date.compareTo(b.date);
  if (byDate != 0) return byDate;
  final byTitle = a.task.title.toLowerCase().compareTo(
    b.task.title.toLowerCase(),
  );
  return byTitle != 0 ? byTitle : a.task.id.compareTo(b.task.id);
}
