import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/todos/data/firestore_todo_repository.dart';
import 'package:nestprep/features/todos/model/task_completion.dart';
import 'package:nestprep/shared/recurrence/recurrence_rule.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import 'household_fixture.dart';

/// The todo repository against the real Firestore (foundation ADR-0010).
///
/// This is the file the recurrence-serialisation bug lived in. `saveTask` and
/// `saveRoutine` each have two paths: creating goes through the typed
/// collection's converter, updating hand-builds its map. They disagreed —
/// creating wrote the nested `RecurrenceRule` as an object, which Firestore
/// cannot store, so **every repeating task and routine failed to save** while
/// updating one to repeat worked. Nothing caught it because nothing on either
/// side of that converter was exercised.
///
/// So the create-with-a-rule path is the first thing here, and it is asserted by
/// reading the document back rather than by the write not throwing.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late TestHousehold home;
  late FirestoreTodoRepository todos;

  setUpAll(() async {
    home = await signInAndCreateAHousehold();
    todos = FirestoreTodoRepository(home.firestore);
  });

  setUp(() async => home = await home.freshHousehold());

  tearDownAll(() async => home.signOut());

  final everySecondTuesdayAndThursday = RecurrenceRule(
    frequency: RecurrenceFrequency.weekly,
    interval: 2,
    weekdays: const [2, 4],
    until: CalendarDate(2027, 3, 31),
  );

  group('creating a task that repeats', () {
    test('saves, and the rule survives the round trip', () async {
      // The bug. Before `explicit_to_json` this threw, because the nested rule
      // went into the document as an object.
      await todos.saveTask(
        householdId: home.id,
        title: 'Bins',
        dueDate: CalendarDate(2026, 9, 19),
        recurrence: everySecondTuesdayAndThursday,
        assigneeIds: [home.memberId],
        createdBy: home.memberId,
      );

      final tasks = await todos.watchTasks(home.id).first;
      expect(tasks, hasLength(1));

      final rule = tasks.single.recurrence;
      expect(rule, isNotNull, reason: 'the rule was stored and read back');
      expect(rule!.frequency, RecurrenceFrequency.weekly);
      expect(rule.interval, 2);
      expect(rule.weekdays, [2, 4]);
      expect(rule.until, CalendarDate(2027, 3, 31));
    });

    test('and a task with no rule at all still saves', () async {
      await todos.saveTask(
        householdId: home.id,
        title: 'One-off',
        dueDate: CalendarDate(2026, 9, 19),
        assigneeIds: const [],
        createdBy: home.memberId,
      );

      final tasks = await todos.watchTasks(home.id).first;
      expect(tasks.single.recurrence, isNull);
      expect(tasks.single.assigneeIds, isEmpty, reason: 'empty means anyone');
    });

    test(
      'a rule with no end date repeats for ever, and stores as null',
      () async {
        // `until: null` is a real value here, not a missing field — the editor
        // cannot put a null back with `copyWith`, which is why `withNoEnd` exists.
        await todos.saveTask(
          householdId: home.id,
          title: 'School run',
          dueDate: CalendarDate(2026, 9, 21),
          recurrence: const RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
          ),
          assigneeIds: const [],
          createdBy: home.memberId,
        );

        final rule = (await todos.watchTasks(home.id).first).single.recurrence;
        expect(rule!.until, isNull);
        expect(rule.interval, 1, reason: 'the default is written, not omitted');
      },
    );
  });

  group('creating a routine that repeats', () {
    test('saves, with its rule and its colour', () async {
      await todos.saveRoutine(
        householdId: home.id,
        name: 'Laundry Day',
        firstDate: CalendarDate(2026, 9, 19),
        recurrence: everySecondTuesdayAndThursday,
        defaultAssigneeIds: [home.memberId],
        color: MemberColor.teal,
        createdBy: home.memberId,
      );

      final routines = await todos.watchRoutines(home.id).first;
      expect(routines, hasLength(1));
      expect(routines.single.color, MemberColor.teal);
      expect(routines.single.recurrence?.weekdays, [2, 4]);
    });
  });

  group('the two write paths agree', () {
    test('a task created plain and then given a rule ends up the same as one '
        'created with it', () async {
      // The asymmetry that hid the bug: create goes through the converter,
      // update hand-builds its map. If they ever disagree again, these two
      // documents stop matching.
      await todos.saveTask(
        householdId: home.id,
        title: 'Created with a rule',
        dueDate: CalendarDate(2026, 9, 19),
        recurrence: everySecondTuesdayAndThursday,
        assigneeIds: const [],
        createdBy: home.memberId,
      );
      await todos.saveTask(
        householdId: home.id,
        title: 'Given one later',
        dueDate: CalendarDate(2026, 9, 19),
        assigneeIds: const [],
        createdBy: home.memberId,
      );

      final plain = (await todos.watchTasks(home.id).first).firstWhere(
        (task) => task.title == 'Given one later',
      );
      await todos.saveTask(
        householdId: home.id,
        taskId: plain.id,
        title: 'Given one later',
        dueDate: CalendarDate(2026, 9, 19),
        recurrence: everySecondTuesdayAndThursday,
        assigneeIds: const [],
        createdBy: home.memberId,
      );

      final all = await todos.watchTasks(home.id).first;
      final created = all.firstWhere((t) => t.title == 'Created with a rule');
      final updated = all.firstWhere((t) => t.title == 'Given one later');

      expect(updated.recurrence, created.recurrence);
    });
  });

  group('completing an occurrence', () {
    test('is idempotent, because the document id is derived from it', () async {
      // `BE-06`: ticking twice is the same write, not two records.
      await todos.saveTask(
        householdId: home.id,
        title: 'Bins',
        dueDate: CalendarDate(2026, 9, 19),
        recurrence: everySecondTuesdayAndThursday,
        assigneeIds: const [],
        createdBy: home.memberId,
      );
      final taskId = (await todos.watchTasks(home.id).first).single.id;
      final day = CalendarDate(2026, 9, 22);

      for (var i = 0; i < 2; i++) {
        await todos.complete(
          householdId: home.id,
          taskId: taskId,
          occurrenceDate: day,
          completedBy: home.memberId,
          completedFor: home.memberId,
        );
      }

      final done = await todos
          .watchCompletions(home.id, from: day, to: day)
          .first;
      expect(done, hasLength(1));
      expect(done.single.id, TaskCompletion.idFor(taskId, day));
    });

    test('only the occurrence ticked is done, not the whole task', () async {
      await todos.saveTask(
        householdId: home.id,
        title: 'Bins',
        dueDate: CalendarDate(2026, 9, 22),
        recurrence: everySecondTuesdayAndThursday,
        assigneeIds: const [],
        createdBy: home.memberId,
      );
      final taskId = (await todos.watchTasks(home.id).first).single.id;
      final ticked = CalendarDate(2026, 9, 22);
      final later = CalendarDate(2026, 10, 6);

      await todos.complete(
        householdId: home.id,
        taskId: taskId,
        occurrenceDate: ticked,
        completedBy: home.memberId,
        completedFor: home.memberId,
      );

      final window = await todos
          .watchCompletions(home.id, from: ticked, to: later)
          .first;
      expect(window.map((done) => done.occurrenceDate), [ticked]);
    });

    test('unticking removes it and can be done twice', () async {
      await todos.saveTask(
        householdId: home.id,
        title: 'Bins',
        dueDate: CalendarDate(2026, 9, 22),
        assigneeIds: const [],
        createdBy: home.memberId,
      );
      final taskId = (await todos.watchTasks(home.id).first).single.id;
      final day = CalendarDate(2026, 9, 22);

      await todos.complete(
        householdId: home.id,
        taskId: taskId,
        occurrenceDate: day,
        completedBy: home.memberId,
        completedFor: home.memberId,
      );
      // Twice, because a delete of something already gone must not throw at a
      // person who tapped twice.
      await todos.uncomplete(
        householdId: home.id,
        taskId: taskId,
        occurrenceDate: day,
      );
      await todos.uncomplete(
        householdId: home.id,
        taskId: taskId,
        occurrenceDate: day,
      );

      final done = await todos
          .watchCompletions(home.id, from: day, to: day)
          .first;
      expect(done, isEmpty);
    });
  });
}
