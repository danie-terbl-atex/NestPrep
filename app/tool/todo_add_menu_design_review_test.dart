import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/state/todo_controller.dart';
import 'package:nestprep/features/todos/ui/todo_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_todo_repository.dart';
import '../test/support/household_fixtures.dart';
import '../test/support/todo_add_menu.dart';
import 'review_press.dart';

/// Not a test — the To do screen's "+", closed and open, and the chore sheet it
/// opens, in light and dark (and open at 200 % text), into
/// `design-review/todo-add-menu/`. Regenerate with
///
///     flutter test tool/todo_add_menu_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  final nowUtc = DateTime.utc(2026, 11, 14, 7);
  final today = CalendarDate(2026, 11, 14);

  Task task(String id, String title, List<String> assignees) => Task(
    id: id,
    title: title,
    dueDate: today,
    assigneeIds: assignees,
    createdBy: Fixtures.samMemberId,
  );

  Future<void> capture(
    WidgetTester tester,
    String name, {
    Brightness brightness = Brightness.light,
    double textScale = 1,
    Future<void> Function()? act,
  }) async {
    final repository = FakeTodoRepository();
    addTearDown(repository.close);
    final controller = TodoController(
      todoRepository: repository,
      householdClock: HouseholdClock('Africa/Johannesburg', now: () => nowUtc),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      isAdmin: true,
      kidIds: const [Fixtures.kidMemberId],
    );
    addTearDown(controller.dispose);
    await captureScreen(
      tester,
      'todo-add-menu/$name',
      screen: TodoScreen(onSelectTab: (_) {}),
      providers: [
        ChangeNotifierProvider<TodoController>.value(value: controller),
      ],
      brightness: brightness,
      textScale: textScale,
      emit: () async {
        repository
          ..emitRoutines(const [])
          ..emitTasks([
            task('bins', 'Bins out', const []),
            task('shop', 'Shop for school shoes', const [Fixtures.samMemberId]),
          ])
          ..emitCompletions(const []);
      },
      act: act,
    );
  }

  for (final brightness in [Brightness.light, Brightness.dark]) {
    final b = brightness.name;
    testWidgets('closed — $b', (tester) async {
      await capture(tester, 'closed-$b', brightness: brightness);
    });

    testWidgets('open — $b', (tester) async {
      await capture(
        tester,
        'open-$b',
        brightness: brightness,
        act: () => tapAdd(tester),
      );
    });

    testWidgets('chore sheet — $b', (tester) async {
      await capture(
        tester,
        'chore-sheet-$b',
        brightness: brightness,
        act: () async {
          await addFromMenu(tester, AppCopy.todosAddChore);
          await tester.enterText(find.byType(TextField).first, 'Feed the fish');
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
        },
      );
    });
  }

  testWidgets('open — dark at 200% text', (tester) async {
    await capture(
      tester,
      'open-dark-200-percent-text',
      brightness: Brightness.dark,
      textScale: 2,
      act: () => tapAdd(tester),
    );
  });
}
