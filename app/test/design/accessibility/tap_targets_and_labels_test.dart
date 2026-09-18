import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/calendar/model/household_event.dart';
import 'package:nestprep/features/calendar/state/calendar_controller.dart';
import 'package:nestprep/features/calendar/ui/calendar_screen.dart';
import 'package:nestprep/features/documents/model/document_folder.dart';
import 'package:nestprep/features/documents/model/household_document.dart';
import 'package:nestprep/features/documents/state/document_library_controller.dart';
import 'package:nestprep/features/documents/ui/document_folder_screen.dart';
import 'package:nestprep/features/documents/ui/document_library_screen.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/state/grocery_list_controller.dart';
import 'package:nestprep/features/groceries/ui/grocery_list_screen.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/features/meal_planning/state/meal_plan_controller.dart';
import 'package:nestprep/features/meal_planning/ui/meal_plan_screen.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/state/todo_controller.dart';
import 'package:nestprep/features/todos/ui/todo_screen.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../support/fake_calendar_repository.dart';
import '../../support/fake_documents.dart';
import '../../support/fake_grocery_repository.dart';
import '../../support/fake_meal_repository.dart';
import '../../support/fake_todo_repository.dart';
import '../../support/household_fixtures.dart';
import '../../support/pump_screen.dart';

/// `FE-13`, the two halves of it that nothing checked: **every control has an
/// accessible label**, and **every touch target is at least 44×44**.
///
/// Contrast, text scaling and reduce-motion each already have a test. These two
/// did not, and they are the ones that fail silently — an unlabelled button is
/// announced as "button" and nothing else, and a small target is only a problem
/// for the people least able to report it.
///
/// It reads the semantics tree rather than the widgets, because that is what a
/// screen reader and the platform's own accessibility scanner read.
void main() {
  setUpAll(tz_data.initializeTimeZones);

  final today = CalendarDate.parse('2026-09-18');
  final now = DateTime.utc(2026, 9, 18, 6);

  /// Apple and Android both ask for 44; this app's own token is 48.
  const floor = 44.0;

  /// Nodes that are a control: something a person can act on.
  bool isAControl(SemanticsData data) =>
      data.hasAction(SemanticsAction.tap) ||
      data.flagsCollection.isButton ||
      data.flagsCollection.isTextField;

  /// Walks the semantics tree, keeping each node's rect in screen coordinates.
  void visit(
    SemanticsNode node,
    Matrix4 inherited,
    void Function(SemanticsData data, Rect onScreen) found,
  ) {
    final transform = inherited.multiplied(
      node.transform ?? Matrix4.identity(),
    );
    final data = node.getSemanticsData();
    found(data, MatrixUtils.transformRect(transform, node.rect));
    node.visitChildren((child) {
      visit(child, transform, found);
      return true;
    });
  }

  ({List<String> unlabelled, List<String> tooSmall}) auditOf(
    WidgetTester tester,
  ) {
    // Semantics rects are in the root coordinate space, which is *physical*
    // pixels. On a 3x device every target looks three times the size it is,
    // and a check against 44 passes whatever the layout says — this test did
    // exactly that until the mutation of a real button failed to fail it.
    final ratio = tester.view.devicePixelRatio;
    final unlabelled = <String>[];
    final tooSmall = <String>[];
    final root =
        // `rootPipelineOwner` is the documented replacement and has no
        // semantics owner in a widget test — this is the tree the test is
        // actually rendering.
        // ignore: deprecated_member_use
        tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;

    visit(root, Matrix4.identity(), (data, onScreen) {
      if (!isAControl(data)) return;
      // A node scrolled out of view has no size worth measuring.
      if (onScreen.isEmpty) return;

      final label = data.label.trim().isNotEmpty
          ? data.label.trim()
          : data.tooltip.trim();
      if (label.isEmpty) {
        unlabelled.add('a control at ${onScreen.topLeft} has no label');
        return;
      }
      final width = onScreen.width / ratio;
      final height = onScreen.height / ratio;
      if (width < floor || height < floor) {
        tooSmall.add(
          '"$label" is ${width.toStringAsFixed(0)}×${height.toStringAsFixed(0)}',
        );
      }
    });
    return (unlabelled: unlabelled, tooSmall: tooSmall);
  }

  Future<void> expectAccessible(WidgetTester tester, String screen) async {
    final handle = tester.ensureSemantics();
    await tester.pumpAndSettle();
    final audit = auditOf(tester);

    expect(
      audit.unlabelled,
      isEmpty,
      reason:
          '$screen: a screen reader announces these as "button" and '
          'nothing else (`FE-13`)',
    );
    expect(
      audit.tooSmall,
      isEmpty,
      reason:
          '$screen: below ${floor.toInt()}×${floor.toInt()}, and the '
          'people who miss are the least likely to report it (`FE-13`)',
    );
    handle.dispose();
  }

  /// The documents controller, with every device-side collaborator faked.
  DocumentLibraryController documentController(
    FakeDocumentRepository repository,
  ) => DocumentLibraryController(
    documentRepository: repository,
    documentStore: FakeDocumentStore(),
    documentDirectory: FakeDocumentDirectory(),
    documentPicker: FakeDocumentPicker(),
    documentOpener: FakeDocumentOpener(),
    householdId: Fixtures.householdId,
    memberId: Fixtures.samMemberId,
    viewerUid: Fixtures.samUid,
    isAdmin: true,
  );

  /// A phone, because a target's size depends on the space it is given.
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('the week', (tester) async {
    phone(tester);
    final repository = FakeCalendarRepository();
    addTearDown(repository.close);
    final controller = CalendarController(
      calendarRepository: repository,
      householdClock: HouseholdClock('Africa/Johannesburg', now: () => now),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
    addTearDown(controller.dispose);

    await pumpScreen(
      tester,
      CalendarScreen(onSelectTab: (_) {}),
      providers: [
        ChangeNotifierProvider<CalendarController>.value(value: controller),
      ],
    );
    repository.emitEvents([
      HouseholdEvent(
        id: 'e1',
        title: 'School run',
        date: today,
        startMinute: 450,
        endMinute: 510,
        createdBy: Fixtures.samMemberId,
      ),
    ]);
    repository.emitExceptions([]);

    await expectAccessible(tester, 'the week');
  });

  testWidgets('todos', (tester) async {
    phone(tester);
    final repository = FakeTodoRepository();
    addTearDown(repository.close);
    final controller = TodoController(
      todoRepository: repository,
      householdClock: HouseholdClock('Africa/Johannesburg', now: () => now),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      isAdmin: true,
    );
    addTearDown(controller.dispose);

    await pumpScreen(
      tester,
      TodoScreen(onSelectTab: (_) {}),
      providers: [
        ChangeNotifierProvider<TodoController>.value(value: controller),
      ],
    );
    repository.emitTasks([
      Task(
        id: 't1',
        title: 'Take the bins out',
        dueDate: today,
        createdBy: Fixtures.samMemberId,
      ),
    ]);
    repository.emitRoutines([]);
    repository.emitCompletions([]);

    await expectAccessible(tester, 'todos');
  });

  testWidgets('groceries', (tester) async {
    phone(tester);
    final repository = FakeGroceryRepository();
    addTearDown(repository.close);
    final controller = GroceryListController(
      groceryRepository: repository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      now: () => now,
    );
    addTearDown(controller.dispose);

    await pumpScreen(
      tester,
      GroceryListScreen(onSelectTab: (_) {}),
      providers: [
        ChangeNotifierProvider<GroceryListController>.value(value: controller),
      ],
    );
    repository.emitItems([
      GroceryItem(
        id: 'g1',
        name: 'Milk',
        addedBy: Fixtures.samMemberId,
        addedAt: now,
      ),
    ]);

    await expectAccessible(tester, 'groceries');
  });

  testWidgets('the document folders', (tester) async {
    phone(tester);
    final repository = FakeDocumentRepository();
    addTearDown(repository.close);
    final controller = documentController(repository);
    addTearDown(controller.dispose);

    await pumpScreen(
      tester,
      const DocumentLibraryScreen(),
      providers: [
        ChangeNotifierProvider<DocumentLibraryController>.value(
          value: controller,
        ),
      ],
    );
    repository.emitFolders([
      const DocumentFolder(
        id: 'f-school',
        name: 'School',
        createdBy: Fixtures.samMemberId,
      ),
    ]);
    repository.emitDocuments([]);

    await expectAccessible(tester, 'the document folders');
  });

  testWidgets('one document folder', (tester) async {
    phone(tester);
    final repository = FakeDocumentRepository();
    addTearDown(repository.close);
    final controller = documentController(repository);
    addTearDown(controller.dispose);

    await pumpScreen(
      tester,
      const DocumentFolderScreen(folderId: 'f-school'),
      providers: [
        ChangeNotifierProvider<DocumentLibraryController>.value(
          value: controller,
        ),
      ],
    );
    repository.emitFolders([
      const DocumentFolder(
        id: 'f-school',
        name: 'School',
        createdBy: Fixtures.samMemberId,
      ),
    ]);
    repository.emitDocuments([
      const HouseholdDocument(
        id: 'd1',
        folderId: 'f-school',
        name: 'Term letter',
        contentType: 'application/pdf',
        sizeBytes: 120000,
        uploadedBy: Fixtures.samMemberId,
      ),
    ]);

    await expectAccessible(tester, 'one document folder');
  });

  testWidgets('meals', (tester) async {
    phone(tester);
    final repository = FakeMealRepository();
    addTearDown(repository.close);
    final controller = MealPlanController(
      mealRepository: repository,
      householdClock: HouseholdClock('Africa/Johannesburg', now: () => now),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
    addTearDown(controller.dispose);

    await pumpScreen(
      tester,
      MealPlanScreen(onSelectTab: (_) {}),
      providers: [
        ChangeNotifierProvider<MealPlanController>.value(value: controller),
      ],
    );
    repository.emitMeals([]);
    repository.emitWeek(WeekPlan.empty(controller.weekStart));

    await expectAccessible(tester, 'meals');
  });
}
