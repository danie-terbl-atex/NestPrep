import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/state/todo_controller.dart';
import 'package:nestprep/features/todos/ui/todo_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_todo_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

final _nowUtc = DateTime.utc(2026, 9, 18, 9);

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

  setUp(() {
    repository = FakeTodoRepository();
    controller = TodoController(
      todoRepository: repository,
      householdClock: HouseholdClock('Africa/Johannesburg', now: () => _nowUtc),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      isAdmin: true,
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) => pumpScreen(
    tester,
    TodoScreen(onSelectTab: (_) {}),
    providers: [
      ChangeNotifierProvider<TodoController>.value(value: controller),
    ],
    brightness: brightness,
    textScale: scale,
  );

  Future<void> emit(WidgetTester tester, {List<Task> tasks = const []}) async {
    repository.emitTasks(tasks);
    repository.emitRoutines([]);
    repository.emitCompletions([]);
    await tester.pumpAndSettle();
  }

  testWidgets('holds the layout while it loads', (tester) async {
    await pump(tester);
    await tester.pump();
    expect(find.text(AppCopy.todosTitle), findsOneWidget);
    expect(find.text(AppCopy.todosMineEmptyTitle), findsNothing);
  });

  testWidgets('says what to do next when there is nothing for me', (
    tester,
  ) async {
    await pump(tester);
    await emit(tester);
    expect(find.text(AppCopy.todosMineEmptyTitle), findsOneWidget);
  });

  testWidgets('shows human copy and a retry when the read fails', (
    tester,
  ) async {
    await pump(tester);
    repository.failTasksWith(const UnavailableFailure());
    await tester.pumpAndSettle();

    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    expect(find.text(AppCopy.retry), findsOneWidget);
  });

  testWidgets('lists what is mine today', (tester) async {
    await pump(tester);
    await emit(tester, tasks: [task()]);
    expect(find.text('Bins'), findsOneWidget);
    expect(find.text(AppCopy.todosToday), findsOneWidget);
  });

  testWidgets('separates what has slipped from what is due today', (
    tester,
  ) async {
    await pump(tester);
    await emit(
      tester,
      tasks: [
        task(id: 'a', title: 'Slipped', due: '2026-09-15'),
        task(id: 'b'),
      ],
    );
    expect(find.text(AppCopy.todosOverdue), findsWidgets);
    expect(find.text('Slipped'), findsOneWidget);
    expect(find.text('Bins'), findsOneWidget);
  });

  testWidgets('tapping a task ticks it off', (tester) async {
    await pump(tester);
    await emit(tester, tasks: [task()]);

    await tester.tap(find.text('Bins'));
    await tester.pumpAndSettle();

    expect(repository.completed.single.taskId, 't1');
    expect(repository.completed.single.date.iso, '2026-09-18');
  });

  testWidgets('the household view shows everybody"s, mine shows only mine', (
    tester,
  ) async {
    await pump(tester);
    await emit(
      tester,
      tasks: [
        task(id: 'a', title: 'Mine', assigneeIds: [Fixtures.samMemberId]),
        task(id: 'b', title: 'Theirs', assigneeIds: [Fixtures.kidMemberId]),
      ],
    );
    expect(find.text('Mine'), findsOneWidget);
    expect(find.text('Theirs'), findsNothing);

    await tester.tap(find.text(AppCopy.todosEveryone));
    await tester.pumpAndSettle();

    expect(find.text('Mine'), findsOneWidget);
    expect(find.text('Theirs'), findsOneWidget);
  });

  testWidgets('a refused write shows copy, never an error code', (
    tester,
  ) async {
    await pump(tester);
    await emit(tester, tasks: [task()]);

    repository.failWritesWith = const PermissionDeniedFailure();
    await tester.tap(find.text('Bins'));
    await tester.pumpAndSettle();

    expect(
      find.text(AppCopy.failure(const PermissionDeniedFailure())),
      findsOneWidget,
    );
    expect(find.textContaining('permission-denied'), findsNothing);
  });

  testWidgets('renders in dark and at 200% text without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    await emit(tester, tasks: [task(title: 'Take the bins out on Tuesday')]);

    expect(tester.takeException(), isNull);
    expect(find.text('Take the bins out on Tuesday'), findsOneWidget);
  });
}
