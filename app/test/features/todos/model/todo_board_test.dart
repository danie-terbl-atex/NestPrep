import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/model/task_completion.dart';
import 'package:nestprep/features/todos/model/task_occurrence.dart';
import 'package:nestprep/features/todos/model/todo_board.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

void main() {
  final today = CalendarDate.parse('2026-09-18');
  final now = DateTime.utc(2026, 9, 18, 9);
  const parent = 'm-parent';
  const mia = 'm-mia';
  const leo = 'm-leo';

  TaskOccurrence occurrence(
    String id, {
    List<String> assignees = const [],
    CalendarDate? on,
    int points = 0,
    DateTime? doneAt,
    bool isDone = false,
  }) {
    final date = on ?? today;
    return TaskOccurrence(
      task: Task(
        id: id,
        title: id,
        dueDate: date,
        assigneeIds: assignees,
        createdBy: parent,
        points: points,
      ),
      date: date,
      assigneeIds: assignees,
      completion: isDone || doneAt != null
          ? TaskCompletion(
              id: TaskCompletion.idFor(id, date),
              taskId: id,
              occurrenceDate: date,
              completedBy: parent,
              completedFor: parent,
              completedAt: doneAt,
            )
          : null,
    );
  }

  TodoBoard board(List<TaskOccurrence> occurrences) => TodoBoard.from(
    occurrences: occurrences,
    routines: const [],
    memberId: parent,
    today: today,
    now: now,
    kidIds: const [mia, leo],
  );

  test('a task with a kid among its assignees is a chore', () {
    final result = board([
      occurrence('bins'),
      occurrence('car', assignees: [parent]),
      occurrence('bed', assignees: [mia]),
      occurrence('walk', assignees: [parent, leo]),
    ]);

    expect(result.chores.map((kid) => kid.kidId), [mia, leo]);
    expect(result.chores.first.chores.map((o) => o.task.id), ['bed']);
    expect(result.chores.last.chores.map((o) => o.task.id), ['walk']);
    expect(
      result.mine.map((o) => o.task.id),
      containsAll(['bins', 'car', 'walk']),
      reason: 'Mine is still everything for me',
    );
  });

  test('Everyone leaves out only the chores that are for kids alone', () {
    final result = board([
      occurrence('bins'),
      occurrence('car', assignees: [parent]),
      occurrence('bed', assignees: [mia]),
      occurrence('bath', assignees: [mia, leo]),
      occurrence('walk', assignees: [parent, leo]),
    ]);

    expect(result.everyone.map((o) => o.task.id), ['bins', 'car', 'walk']);
    expect(result.everyoneFor(parent).map((o) => o.task.id), [
      'bins',
      'car',
      'walk',
    ]);
  });

  test('a kid section is overdue, then open today, then done today', () {
    final result = board([
      occurrence('done', assignees: [mia], isDone: true),
      occurrence('open', assignees: [mia]),
      occurrence('slipped', assignees: [mia], on: today.addDays(-2)),
      occurrence('later', assignees: [mia], on: today.addDays(3)),
    ]);

    expect(result.chores.first.chores.map((o) => o.task.id), [
      'slipped',
      'open',
      'done',
    ]);
  });

  test('a shared chore counts once, and stars are what was done today', () {
    final result = board([
      occurrence('dishes', assignees: [mia, leo]),
      occurrence('bed', assignees: [mia], points: 3, isDone: true),
      occurrence('room', assignees: [mia], points: 2),
    ]);

    expect(result.openChoreCount, 2);
    expect(result.chores.first.starsToday, 3);
    expect(result.chores.first.doneCount, 1);
    expect(result.chores.last.chores.single.task.id, 'dishes');
  });

  test('just done is the last day of mine, newest and pending first', () {
    final result = board([
      occurrence('old', doneAt: now.subtract(const Duration(hours: 30))),
      occurrence('hour', doneAt: now.subtract(const Duration(hours: 1))),
      occurrence('minute', doneAt: now.subtract(const Duration(minutes: 1))),
      occurrence('pending', isDone: true),
      occurrence('theirs', assignees: [leo], doneAt: now),
    ]);

    expect(result.justDone.map((o) => o.task.id), [
      'pending',
      'minute',
      'hour',
    ]);
  });

  test('no kids is no chores, and every task is a to-do', () {
    final result = TodoBoard.from(
      occurrences: [
        occurrence('bed', assignees: [mia]),
      ],
      routines: const [],
      memberId: parent,
      today: today,
      now: now,
    );

    expect(result.hasKids, isFalse);
    expect(result.everyone, hasLength(1));
  });
}
