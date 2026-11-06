import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/state/todo_controller.dart';
import 'package:nestprep/features/todos/ui/chore_picture_field.dart';
import 'package:nestprep/features/todos/ui/todo_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/chore_picture_copy.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_todo_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// Pictures on the to-dos tab (todos ADR-0005): the sheet suggests from the
/// title and never sets one itself; a parent picks, changes or removes it;
/// and the row wears it — or nothing, for an id this build does not ship.
void main() {
  setUpAll(tz_data.initializeTimeZones);

  final now = DateTime.utc(2026, 11, 5, 7);
  final today = CalendarDate(2026, 11, 5);

  late FakeTodoRepository repository;
  late TodoController controller;

  setUp(() {
    repository = FakeTodoRepository();
    controller = TodoController(
      todoRepository: repository,
      householdClock: HouseholdClock('Africa/Johannesburg', now: () => now),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      isAdmin: true,
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  Task task(String id, String title, {String? picture}) => Task(
    id: id,
    title: title,
    dueDate: today,
    assigneeIds: const [Fixtures.samMemberId],
    createdBy: Fixtures.samMemberId,
    picture: picture,
  );

  Future<void> pump(
    WidgetTester tester, {
    List<Task> tasks = const [],
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      TodoScreen(onSelectTab: (_) {}),
      providers: [
        ChangeNotifierProvider<TodoController>.value(value: controller),
      ],
      brightness: brightness,
      textScale: textScale,
    );
    repository
      ..emitTasks(tasks)
      ..emitRoutines(const [])
      ..emitCompletions(const []);
    await tester.pumpAndSettle();
  }

  Finder suggestion(String id) =>
      find.byKey(ValueKey('chore-picture-suggestion-$id'));
  Finder worn(String id) => find.byKey(ValueKey('chore-picture-$id'));

  Future<void> typeTitle(WidgetTester tester, String title) async {
    await tester.enterText(find.byType(TextField).first, title);
    await tester.pump();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openNewTask(WidgetTester tester) async {
    await tester.tap(find.text(AppCopy.todosAddTask));
    await tester.pumpAndSettle();
  }

  testWidgets('suggests from the title as it is typed, and sets nothing', (
    tester,
  ) async {
    await pump(tester);
    await openNewTask(tester);
    expect(find.text(ChorePictureCopy.choosePicture), findsOneWidget);

    await typeTitle(tester, 'Brush teeth');
    expect(suggestion('brush-teeth'), findsOneWidget);
    expect(find.text(ChorePictureCopy.morePictures), findsOneWidget);

    await typeTitle(tester, 'Make your bed');
    expect(suggestion('brush-teeth'), findsNothing);
    expect(suggestion('make-bed'), findsOneWidget);

    await typeTitle(tester, 'Xyzzy plugh');
    expect(suggestion('make-bed'), findsNothing);
    expect(find.text(ChorePictureCopy.choosePicture), findsOneWidget);

    await typeTitle(tester, 'Brush teeth');
    await tapVisible(tester, find.text(AppCopy.householdSave));
    expect(repository.savedTasks.single.picture, isNull);
  });

  testWidgets('one tap on a suggestion wears it, and Save writes it', (
    tester,
  ) async {
    await pump(tester);
    await openNewTask(tester);
    await typeTitle(tester, 'Brush teeth');
    await tapVisible(tester, suggestion('brush-teeth'));

    expect(suggestion('brush-teeth'), findsNothing);
    expect(find.bySemanticsLabel(ChorePictureCopy.remove), findsOneWidget);

    await tapVisible(tester, find.text(AppCopy.householdSave));
    expect(repository.savedTasks.single.picture, 'brush-teeth');
  });

  testWidgets('the picker changes it, and the cross takes it off', (
    tester,
  ) async {
    await pump(tester);
    await openNewTask(tester);
    await typeTitle(tester, 'Brush teeth');
    await tapVisible(tester, find.text(ChorePictureCopy.morePictures));
    expect(find.text(ChorePictureCopy.pickerTitle), findsOneWidget);

    final makeBed = find.byKey(const ValueKey('chore-picture-option-make-bed'));
    await tester.scrollUntilVisible(
      makeBed,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(makeBed);
    await tester.pumpAndSettle();
    await tester.tap(makeBed);
    await tester.pumpAndSettle();
    expect(find.text(ChorePictureCopy.pickerTitle), findsNothing);
    expect(find.text('Make bed'), findsOneWidget);

    await tapVisible(tester, find.bySemanticsLabel(ChorePictureCopy.remove));
    expect(suggestion('brush-teeth'), findsOneWidget);

    await tapVisible(tester, find.text(AppCopy.householdSave));
    expect(repository.savedTasks.single.picture, isNull);
  });

  testWidgets('an edit keeps the picture it had, even one it cannot draw', (
    tester,
  ) async {
    await pump(
      tester,
      tasks: [
        task('teeth', 'Brush teeth', picture: 'brush-teeth'),
        task('newer', 'Newer chore', picture: 'from-a-newer-build'),
      ],
    );

    await tester.longPress(find.text('Brush teeth'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(ChorePictureCopy.remove), findsOneWidget);
    await tapVisible(tester, find.text(AppCopy.householdSave));

    await tester.longPress(find.text('Newer chore'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(AppCopy.householdSave));

    expect(
      [for (final saved in repository.savedTasks) saved.picture],
      ['brush-teeth', 'from-a-newer-build'],
    );
  });

  testWidgets('the row wears its picture, and only a picture it ships', (
    tester,
  ) async {
    await pump(
      tester,
      tasks: [
        task('teeth', 'Brush teeth', picture: 'brush-teeth'),
        task('newer', 'Newer chore', picture: 'from-a-newer-build'),
        task('plain', 'Call Gran'),
      ],
    );
    expect(worn('brush-teeth'), findsOneWidget);
    expect(worn('from-a-newer-build'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the field fits dark, 200% text, 360 wide', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    String? picture;

    await tester.pumpWidget(
      MaterialApp(
        theme: nestThemeData(NestTheme.dark()),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              padding: const EdgeInsets.all(NestSpace.gutter),
              child: ChorePictureField(
                title: 'Feed the dog and water the plants',
                picture: picture,
                onChanged: (id) => setState(() => picture = id),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(suggestion('feed-dog'), findsOneWidget);
    expect(suggestion('water-plants'), findsOneWidget);

    await tapVisible(tester, suggestion('feed-dog'));
    expect(picture, 'feed-dog');
    expect(tester.takeException(), isNull);
    expect(find.text('Feed the dog'), findsOneWidget);
  });
}
