import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/todos/model/occurrence_selector.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/model/task_completion.dart';
import 'package:nestprep/features/todos/model/todo_board.dart';
import 'package:nestprep/features/todos/state/todo_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_todo_repository.dart';
import '../../../support/household_fixtures.dart';

/// 22:30 UTC is already the 18th in Johannesburg — so "today" for this
/// household is the 18th even though UTC says the 17th.
final _nowUtc = DateTime.utc(2026, 9, 17, 22, 30);

Task task({
  String id = 't1',
  String title = 'Bins',
  String due = '2026-09-18',
  List<String> assigneeIds = const [],
}) => Task(
  id: id,
  title: title,
  dueDate: CalendarDate.parse(due),
  assigneeIds: assigneeIds,
  createdBy: Fixtures.samMemberId,
);

void main() {
  setUpAll(tz_data.initializeTimeZones);

  late FakeTodoRepository repository;
  late TodoController controller;

  TodoController build({bool isAdmin = true, String? memberId}) {
    return TodoController(
      todoRepository: repository,
      householdClock: HouseholdClock('Africa/Johannesburg', now: () => _nowUtc),
      householdId: Fixtures.householdId,
      memberId: memberId ?? Fixtures.samMemberId,
      isAdmin: isAdmin,
    );
  }

  setUp(() {
    repository = FakeTodoRepository();
    controller = build();
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  TodoBoard boardOf() {
    final state = controller.board;
    expect(state, isA<AsyncData<TodoBoard>>());
    return (state as AsyncData<TodoBoard>).value;
  }

  Future<void> emitAll({
    List<Task> tasks = const [],
    List<TaskCompletion> completions = const [],
  }) async {
    repository.emitTasks(tasks);
    repository.emitRoutines([]);
    repository.emitCompletions(completions);
    await pumpEventQueue();
  }

  test('reads today from the household"s clock, not the device"s', () {
    expect(controller.today.iso, '2026-09-18');
  });

  test(
    'windows the completions read to the overdue horizon and a fortnight ahead',
    () {
      expect(repository.completionsFrom?.iso, '2026-09-11');
      expect(repository.completionsTo?.iso, '2026-10-02');
    },
  );

  test('stays loading until all three reads have answered', () async {
    expect(controller.board, isA<AsyncLoading<TodoBoard>>());
    repository.emitTasks([task()]);
    await pumpEventQueue();
    expect(controller.board, isA<AsyncLoading<TodoBoard>>());
    repository.emitRoutines([]);
    await pumpEventQueue();
    expect(controller.board, isA<AsyncLoading<TodoBoard>>());
    repository.emitCompletions([]);
    await pumpEventQueue();
    expect(controller.board, isA<AsyncData<TodoBoard>>());
  });

  test('puts what is mine today in front of me', () async {
    await emitAll(
      tasks: [
        task(id: 'a', title: 'Mine', assigneeIds: [Fixtures.samMemberId]),
        task(id: 'b', title: 'Theirs', assigneeIds: [Fixtures.kidMemberId]),
      ],
    );
    expect(boardOf().mine.map((o) => o.task.title), ['Mine']);
    expect(boardOf().everyone.map((o) => o.task.title), ['Mine', 'Theirs']);
  });

  test('filters everyone"s by member, and back to everyone', () async {
    await emitAll(
      tasks: [
        task(id: 'a', title: 'Mine', assigneeIds: [Fixtures.samMemberId]),
        task(id: 'b', title: 'Theirs', assigneeIds: [Fixtures.kidMemberId]),
      ],
    );
    controller.filterBy(Fixtures.kidMemberId);
    expect(
      boardOf().everyoneFor(controller.memberFilter).map((o) => o.task.title),
      ['Theirs'],
    );
    controller.filterBy(null);
    expect(boardOf().everyoneFor(controller.memberFilter), hasLength(2));
  });

  test('completing records the actor and who it was for', () async {
    await emitAll(tasks: [task()]);
    await controller.setDone(boardOf().everyone.single, isDone: true);

    expect(repository.completed.single.by, Fixtures.samMemberId);
    expect(repository.completed.single.forMember, Fixtures.samMemberId);
    expect(repository.completed.single.date.iso, '2026-09-18');
  });

  test('an admin completing on somebody"s behalf records both', () async {
    await emitAll(
      tasks: [
        task(assigneeIds: [Fixtures.kidMemberId]),
      ],
    );
    await controller.setDone(
      boardOf().everyone.single,
      isDone: true,
      forMemberId: Fixtures.kidMemberId,
    );

    expect(repository.completed.single.by, Fixtures.samMemberId);
    expect(repository.completed.single.forMember, Fixtures.kidMemberId);
  });

  test('unticking removes the completion for that occurrence only', () async {
    await emitAll(tasks: [task()]);
    await controller.setDone(boardOf().everyone.single, isDone: false);

    expect(repository.uncompleted.single.taskId, 't1');
    expect(repository.uncompleted.single.date.iso, '2026-09-18');
    expect(repository.completed, isEmpty);
  });

  test('a task marked done stops asking, and everyone still sees it', () async {
    await emitAll(
      tasks: [task()],
      completions: [
        TaskCompletion(
          id: TaskCompletion.idFor('t1', CalendarDate.parse('2026-09-18')),
          taskId: 't1',
          occurrenceDate: CalendarDate.parse('2026-09-18'),
          completedBy: Fixtures.samMemberId,
          completedFor: Fixtures.samMemberId,
        ),
      ],
    );
    expect(boardOf().mine, isEmpty);
    expect(boardOf().everyone.single.isDone, isTrue);
  });

  test('refuses to save a task with no title', () async {
    await controller.saveTask(
      title: '   ',
      dueDate: controller.today,
      assigneeIds: const [],
    );
    expect(repository.savedTasks, isEmpty);
  });

  test('a refused write becomes copy, and clears', () async {
    await emitAll(tasks: [task()]);
    repository.failWritesWith = const PermissionDeniedFailure();
    await controller.setDone(boardOf().everyone.single, isDone: true);
    expect(controller.actionFailure, isA<PermissionDeniedFailure>());

    controller.dismissActionFailure();
    expect(controller.actionFailure, isNull);
  });

  test('a read that fails becomes a failure state with a way back', () async {
    repository.failTasksWith(const UnavailableFailure());
    await pumpEventQueue();
    expect(controller.board, isA<AsyncFailure<TodoBoard>>());

    await controller.retry();
    expect(controller.board, isA<AsyncLoading<TodoBoard>>());
  });

  test('the overdue horizon is the one the selector uses', () {
    expect(
      controller.windowStart.iso,
      controller.today.addDays(-overdueWindowDays).iso,
    );
  });
}
