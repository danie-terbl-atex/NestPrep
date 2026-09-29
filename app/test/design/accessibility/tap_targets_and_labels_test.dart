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
import 'package:nestprep/features/kid_accounts/model/kid_device.dart';
import 'package:nestprep/features/kid_accounts/state/kid_code_controller.dart';
import 'package:nestprep/features/kid_accounts/state/kid_home_controller.dart';
import 'package:nestprep/features/kid_accounts/state/kid_sign_in_controller.dart';
import 'package:nestprep/features/kid_accounts/ui/kid_code_screen.dart';
import 'package:nestprep/features/kid_accounts/ui/kid_home_screen.dart';
import 'package:nestprep/features/kid_accounts/ui/kid_sign_in_screen.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/features/live_location/model/member_location.dart';
import 'package:nestprep/features/live_location/state/live_location_controller.dart';
import 'package:nestprep/features/live_location/ui/live_location_screen.dart';
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

import '../../support/accessibility_audit.dart';
import '../../support/fake_auth.dart';
import '../../support/fake_calendar_repository.dart';
import '../../support/fake_calendar_sync.dart';
import '../../support/fake_documents.dart';
import '../../support/fake_grocery_repository.dart';
import '../../support/fake_kid_sign_in.dart';
import '../../support/fake_live_location.dart';
import '../../support/fake_meal_repository.dart';
import '../../support/fake_todo_repository.dart';
import '../../support/household_fixtures.dart';
import '../../support/kid_home_fixture.dart';
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

  testWidgets('the week', (tester) async {
    phone(tester);
    final repository = FakeCalendarRepository();
    addTearDown(repository.close);
    final controller = CalendarController(
      calendarRepository: repository,
      calendarSyncRepository: FakeCalendarSyncRepository(),
      householdClock: HouseholdClock('Africa/Johannesburg', now: () => now),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      householdMembers: const [],
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

  testWidgets('where everybody is', (tester) async {
    phone(tester);
    final repository = FakeLiveLocationRepository();
    final reporter = FakeLocationReporter();
    addTearDown(repository.close);
    addTearDown(reporter.close);
    final controller = LiveLocationController(
      liveLocationRepository: repository,
      locationReporter: reporter,
      householdId: Fixtures.householdId,
      viewerMemberId: Fixtures.samMemberId,
      members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
      now: () => now,
    );

    await pumpScreen(
      tester,
      const LiveLocationScreen(),
      providers: [
        ChangeNotifierProvider<LiveLocationController>.value(value: controller),
      ],
    );
    repository.emitLocations([
      MemberLocation(
        id: Fixtures.thandiMemberId,
        point: const Coordinates(latitude: -26.2041, longitude: 28.0473),
        accuracyMetres: 12,
        reportedAt: now,
        sharingUntil: now.add(const Duration(hours: 1)),
      ),
    ]);

    await expectAccessible(tester, 'where everybody is');
    // Disposed here rather than in a teardown: this controller recounts the
    // ages on screen every thirty seconds, and a timer still pending when the
    // body ends fails the test before any teardown runs.
    controller.dispose();
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

  // Kid sign-in (accounts ADR-0003). The kid's own screens are held to the
  // same floor as everybody else's — a child's thumb is not more accurate.
  testWidgets('a kid\u2019s way in', (tester) async {
    phone(tester);
    final auth = FakeAuthGateway();
    addTearDown(auth.close);
    final controller = KidCodeController(
      kidSignInDirectory: FakeKidSignInDirectory(),
      authGateway: auth,
    );
    addTearDown(controller.dispose);

    await pumpScreen(
      tester,
      const KidCodeScreen(),
      providers: [
        ChangeNotifierProvider<KidCodeController>.value(value: controller),
      ],
    );
    controller.setCode('ABC234');

    await expectAccessible(tester, 'a kid\u2019s way in');
  });

  testWidgets('a kid\u2019s home', (tester) async {
    phone(tester);
    final fixture = KidHomeFixture();
    addTearDown(fixture.close);

    await pumpScreen(
      tester,
      const KidHomeScreen(),
      providers: [
        ChangeNotifierProvider<KidHomeController>.value(
          value: fixture.controller,
        ),
      ],
    );
    await tester.runAsync(
      () =>
          fixture.arrive(tasks: [KidHomeFixture.chore('bed', 'Make your bed')]),
    );

    await expectAccessible(tester, 'a kid\u2019s home');
  });

  testWidgets('kids\u2019 sign-in, for a parent', (tester) async {
    phone(tester);
    final devices = FakeKidDeviceRepository();
    addTearDown(devices.close);
    final controller = KidSignInController(
      kidSignInDirectory: FakeKidSignInDirectory(),
      kidDeviceRepository: devices,
      householdId: Fixtures.householdId,
      members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
    );
    addTearDown(controller.dispose);

    await pumpScreen(
      tester,
      const KidSignInScreen(),
      providers: [
        ChangeNotifierProvider<KidSignInController>.value(value: controller),
      ],
    );
    devices.emit([
      KidDevice(
        id: 'kid_tablet',
        memberId: Fixtures.kidMemberId,
        label: 'Tablet',
        pairedBy: Fixtures.samUid,
        pairedAt: now,
      ),
    ]);

    await expectAccessible(tester, 'kids\u2019 sign-in');
  });
}
