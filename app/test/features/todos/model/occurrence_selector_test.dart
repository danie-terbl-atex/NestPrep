import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/todos/model/occurrence_selector.dart';
import 'package:nestprep/features/todos/model/routine.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/model/task_completion.dart';
import 'package:nestprep/shared/recurrence/recurrence_rule.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/household_fixtures.dart';

CalendarDate date(String iso) => CalendarDate.parse(iso);

Task task({
  String id = 't1',
  String title = 'Bins',
  String due = '2026-09-19',
  RecurrenceRule? recurrence,
  List<String> assigneeIds = const [],
  String? routineId,
}) => Task(
  id: id,
  title: title,
  dueDate: date(due),
  recurrence: recurrence,
  assigneeIds: assigneeIds,
  createdBy: Fixtures.samMemberId,
  routineId: routineId,
);

Routine routine({
  String id = 'r1',
  String name = 'Laundry Day Tasks',
  String first = '2026-09-19',
  RecurrenceRule? recurrence,
  List<String> defaults = const [],
}) => Routine(
  id: id,
  name: name,
  firstDate: date(first),
  recurrence: recurrence,
  defaultAssigneeIds: defaults,
  createdBy: Fixtures.samMemberId,
);

TaskCompletion done(String taskId, String iso, {String? forMember}) =>
    TaskCompletion(
      id: TaskCompletion.idFor(taskId, date(iso)),
      taskId: taskId,
      occurrenceDate: date(iso),
      completedBy: Fixtures.samMemberId,
      completedFor: forMember ?? Fixtures.samMemberId,
    );

void main() {
  group('a task on its own', () {
    test('appears once, on its due date', () {
      final occurrences = selectOccurrences(
        tasks: [task()],
        routines: [],
        completions: [],
        from: date('2026-09-14'),
        to: date('2026-09-25'),
      );
      expect(occurrences.map((o) => o.date.iso), ['2026-09-19']);
    });

    test('repeats where it says it does', () {
      final occurrences = selectOccurrences(
        tasks: [
          task(
            recurrence: const RecurrenceRule(
              frequency: RecurrenceFrequency.weekly,
            ),
          ),
        ],
        routines: [],
        completions: [],
        from: date('2026-09-14'),
        to: date('2026-10-05'),
      );
      expect(occurrences.map((o) => o.date.iso), [
        '2026-09-19',
        '2026-09-26',
        '2026-10-03',
      ]);
    });
  });

  group('completions', () {
    test('mark the occurrence they name and no other', () {
      final occurrences = selectOccurrences(
        tasks: [
          task(
            recurrence: const RecurrenceRule(
              frequency: RecurrenceFrequency.weekly,
            ),
          ),
        ],
        routines: [],
        completions: [done('t1', '2026-09-19')],
        from: date('2026-09-14'),
        to: date('2026-10-05'),
      );
      expect(
        {for (final o in occurrences) o.date.iso: o.isDone},
        {'2026-09-19': true, '2026-09-26': false, '2026-10-03': false},
      );
    });

    test('carry who it was for when an admin did it on their behalf', () {
      final occurrences = selectOccurrences(
        tasks: [
          task(assigneeIds: [Fixtures.kidMemberId]),
        ],
        routines: [],
        completions: [
          done('t1', '2026-09-19', forMember: Fixtures.kidMemberId),
        ],
        from: date('2026-09-14'),
        to: date('2026-09-25'),
      );
      final completion = occurrences.single.completion!;
      expect(completion.completedBy, Fixtures.samMemberId);
      expect(completion.completedFor, Fixtures.kidMemberId);
      expect(completion.wasOnBehalfOfSomebodyElse, isTrue);
    });
  });

  group('a task in a routine', () {
    test('follows the routine"s schedule, not its own', () {
      final occurrences = selectOccurrences(
        tasks: [
          task(
            due: '2026-01-01',
            recurrence: const RecurrenceRule(
              frequency: RecurrenceFrequency.daily,
            ),
            routineId: 'r1',
          ),
        ],
        routines: [
          routine(
            recurrence: const RecurrenceRule(
              frequency: RecurrenceFrequency.weekly,
            ),
          ),
        ],
        completions: [],
        from: date('2026-09-14'),
        to: date('2026-10-05'),
      );
      expect(occurrences.map((o) => o.date.iso), [
        '2026-09-19',
        '2026-09-26',
        '2026-10-03',
      ]);
    });

    test('takes the routine"s people unless it names its own', () {
      final routines = [
        routine(defaults: [Fixtures.thandiMemberId]),
      ];
      final inherited = selectOccurrences(
        tasks: [task(routineId: 'r1')],
        routines: routines,
        completions: [],
        from: date('2026-09-14'),
        to: date('2026-09-25'),
      );
      expect(inherited.single.assigneeIds, [Fixtures.thandiMemberId]);

      final overridden = selectOccurrences(
        tasks: [
          task(routineId: 'r1', assigneeIds: [Fixtures.kidMemberId]),
        ],
        routines: routines,
        completions: [],
        from: date('2026-09-14'),
        to: date('2026-09-25'),
      );
      expect(overridden.single.assigneeIds, [Fixtures.kidMemberId]);
    });

    test('falls back to its own schedule when the routine is gone', () {
      final occurrences = selectOccurrences(
        tasks: [task(routineId: 'deleted')],
        routines: [],
        completions: [],
        from: date('2026-09-14'),
        to: date('2026-09-25'),
      );
      expect(occurrences.single.date.iso, '2026-09-19');
      expect(occurrences.single.routine, isNull);
    });
  });

  group('order', () {
    test('is by day, then by title, so the list does not shuffle', () {
      final occurrences = selectOccurrences(
        tasks: [
          task(id: 'b', title: 'Washing'),
          task(id: 'a'),
          task(id: 'c', title: 'Aardvark', due: '2026-09-20'),
        ],
        routines: [],
        completions: [],
        from: date('2026-09-14'),
        to: date('2026-09-25'),
      );
      expect(occurrences.map((o) => o.task.title), [
        'Bins',
        'Washing',
        'Aardvark',
      ]);
    });
  });

  group('mine today', () {
    final today = date('2026-09-19');

    List<String> mine(
      List<Task> tasks, {
      List<TaskCompletion> completions = const [],
    }) {
      final occurrences = selectOccurrences(
        tasks: tasks,
        routines: [],
        completions: completions,
        from: today.addDays(-overdueWindowDays),
        to: today.addDays(14),
      );
      return mineToday(
        occurrences: occurrences,
        memberId: Fixtures.thandiMemberId,
        today: today,
      ).map((o) => '${o.task.title} ${o.date.iso}').toList();
    }

    test('takes what is mine and what is for anyone', () {
      expect(
        mine([
          task(id: 'a', title: 'Mine', assigneeIds: [Fixtures.thandiMemberId]),
          task(id: 'b', title: 'Anyone'),
          task(id: 'c', title: 'Theirs', assigneeIds: [Fixtures.kidMemberId]),
        ]),
        ['Anyone 2026-09-19', 'Mine 2026-09-19'],
      );
    });

    test('leaves out what is already done', () {
      expect(
        mine(
          [task(id: 'a')],
          completions: [done('a', '2026-09-19')],
        ),
        isEmpty,
      );
    });

    test('leaves out what is not due yet', () {
      expect(mine([task(id: 'a', title: 'Later', due: '2026-09-25')]), isEmpty);
    });

    test('keeps what slipped, and stops asking after a week', () {
      expect(mine([task(id: 'a', title: 'Slipped', due: '2026-09-15')]), [
        'Slipped 2026-09-15',
      ]);
      // Eight days ago is outside the window the caller reads at all.
      expect(
        mine([task(id: 'a', title: 'Ancient', due: '2026-09-11')]),
        isEmpty,
      );
    });

    test('asks once per missed week, not once per day', () {
      final occurrences = mine([
        task(
          id: 'a',
          title: 'Weekly',
          due: '2026-09-12',
          recurrence: const RecurrenceRule(
            frequency: RecurrenceFrequency.weekly,
          ),
        ),
      ]);
      // A week ago and today — two missed Saturdays, not eight missed days.
      expect(occurrences, ['Weekly 2026-09-12', 'Weekly 2026-09-19']);
    });

    test('a daily task that slipped asks once for every day it slipped', () {
      final occurrences = mine([
        task(
          id: 'a',
          title: 'Daily',
          due: '2026-09-17',
          recurrence: const RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
          ),
        ),
      ]);
      expect(occurrences, [
        'Daily 2026-09-17',
        'Daily 2026-09-18',
        'Daily 2026-09-19',
      ]);
    });
  });
}
