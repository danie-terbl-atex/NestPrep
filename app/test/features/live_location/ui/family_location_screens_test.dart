import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/features/live_location/model/family_place.dart';
import 'package:nestprep/features/live_location/model/member_location.dart';
import 'package:nestprep/features/live_location/model/trail.dart';
import 'package:nestprep/features/live_location/state/always_sharing.dart';
import 'package:nestprep/features/live_location/state/history_controller.dart';
import 'package:nestprep/features/live_location/state/live_location_controller.dart';
import 'package:nestprep/features/live_location/state/place_editor_controller.dart';
import 'package:nestprep/features/live_location/state/places_controller.dart';
import 'package:nestprep/features/live_location/ui/live_location_screen.dart';
import 'package:nestprep/features/live_location/ui/member_history_screen.dart';
import 'package:nestprep/features/live_location/ui/place_editor_screen.dart';
import 'package:nestprep/features/live_location/ui/places_screen.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/state/household_entitlement.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_live_location.dart';
import '../../../support/fake_subscriptions.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

const _school = FamilyPlace(
  id: 'school',
  name: 'Parkhurst Primary',
  centre: Coordinates(latitude: -26.13, longitude: 28.07),
  radiusMetres: 150,
  icon: PlaceIcon.school,
  alertOnArrive: true,
  alertOnLeave: false,
);

ChangeNotifierProvider<HouseholdEntitlement> _premium() =>
    ChangeNotifierProvider<HouseholdEntitlement>(
      lazy: false,
      create: (_) => HouseholdEntitlement(
        entitlementRepository: FakeEntitlementRepository(
          initial: Entitlement(
            premiumUntil: DateTime.now().add(const Duration(days: 30)),
          ),
        ),
        householdId: Fixtures.householdId,
      ),
    );

void darkAndLarge(WidgetTester tester) {
  tester.view.physicalSize = const Size(360 * 3, 800 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  late FakePlacesRepository places;

  setUp(() => places = FakePlacesRepository());
  tearDown(() => places.close());

  group('places', () {
    late PlacesController controller;

    setUp(
      () => controller = PlacesController(
        placesRepository: places,
        householdId: Fixtures.householdId,
      ),
    );
    tearDown(() => controller.dispose());

    Future<void> pump(
      WidgetTester tester, {
      Brightness brightness = Brightness.light,
      double scale = 1,
    }) => pumpScreen(
      tester,
      const PlacesScreen(),
      providers: [
        ChangeNotifierProvider<PlacesController>.value(value: controller),
      ],
      brightness: brightness,
      textScale: scale,
    );

    testWidgets('loads, then says there are none and offers one', (
      tester,
    ) async {
      await pump(tester);
      expect(find.byKey(const ValueKey('loading')), findsOneWidget);
      places.emitPlaces([]);
      await tester.pumpAndSettle();
      expect(find.text(LocationCopy.noPlacesTitle), findsOneWidget);
      expect(find.text(LocationCopy.addPlace), findsOneWidget);
    });

    testWidgets('lists them by name with how far around', (tester) async {
      await pump(tester);
      places.emitPlaces([_school]);
      await tester.pumpAndSettle();
      expect(find.text('Parkhurst Primary'), findsOneWidget);
      expect(find.text(LocationCopy.radius(150)), findsOneWidget);
    });

    testWidgets('a refused read says so with a retry', (tester) async {
      await pump(tester);
      places.emitPlacesError(const PermissionDeniedFailure());
      await tester.pumpAndSettle();
      expect(find.text(AppCopy.retry), findsOneWidget);
    });

    testWidgets('a helper who may only look cannot add one', (tester) async {
      await pumpScreen(
        tester,
        const PlacesScreen(),
        view: Fixtures.helperView(
          AccessGrant({HouseholdArea.location: AccessLevel.view}),
        ),
        providers: [
          ChangeNotifierProvider<PlacesController>.value(value: controller),
        ],
      );
      places.emitPlaces([_school]);
      await tester.pumpAndSettle();
      expect(find.text(LocationCopy.addPlace), findsNothing);
    });

    testWidgets('survives dark at 200% text on a 360-wide phone', (
      tester,
    ) async {
      darkAndLarge(tester);
      await pump(tester, brightness: Brightness.dark, scale: 2);
      places.emitPlaces([_school]);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('a place', () {
    testWidgets('cannot be saved without a name and a centre, then can', (
      tester,
    ) async {
      final editor = PlaceEditorController(
        placesRepository: places,
        locationSource: FakeLocationSource(),
        householdId: Fixtures.householdId,
      );
      addTearDown(editor.dispose);
      await pumpScreen(
        tester,
        const PlaceEditorScreen(),
        providers: [
          ChangeNotifierProvider<PlaceEditorController>.value(value: editor),
          _premium(),
        ],
      );
      expect(editor.canSave, isFalse);
      await tester.enterText(find.byType(TextField), 'Gran’s');
      editor.moveTo(const Coordinates(latitude: -26.2, longitude: 28.0));
      await tester.pumpAndSettle();
      expect(editor.canSave, isTrue);

      await tester.ensureVisible(find.text(LocationCopy.save));
      await tester.tap(find.text(LocationCopy.save));
      await tester.pumpAndSettle();
      expect(places.saved.single.name, 'Gran’s');
      expect(places.saved.single.alertOnArrive, isTrue);
    });

    testWidgets('survives dark at 200% text on a 360-wide phone', (
      tester,
    ) async {
      darkAndLarge(tester);
      final editor = PlaceEditorController(
        placesRepository: places,
        locationSource: FakeLocationSource(),
        householdId: Fixtures.householdId,
        place: _school,
      );
      addTearDown(editor.dispose);
      await pumpScreen(
        tester,
        const PlaceEditorScreen(),
        providers: [
          ChangeNotifierProvider<PlaceEditorController>.value(value: editor),
        ],
        brightness: Brightness.dark,
        textScale: 2,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text(LocationCopy.deletePlace),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('a member’s day', () {
    final now = DateTime.now().toUtc();

    Future<HistoryController> pump(
      WidgetTester tester,
      FakeTrailRepository trails, {
      Brightness brightness = Brightness.light,
      double scale = 1,
    }) async {
      final history = HistoryController(
        trailRepository: trails,
        placesRepository: places,
        householdId: Fixtures.householdId,
        memberId: Fixtures.kidMemberId,
        clock: HouseholdClock('Africa/Johannesburg'),
      );
      addTearDown(history.dispose);
      await pumpScreen(
        tester,
        MemberHistoryScreen(member: Fixtures.kid),
        providers: [
          ChangeNotifierProvider<HistoryController>.value(value: history),
        ],
        brightness: brightness,
        textScale: scale,
      );
      return history;
    }

    testWidgets('an empty day says nothing was recorded', (tester) async {
      await pump(tester, FakeTrailRepository());
      await tester.pumpAndSettle();
      expect(find.text(LocationCopy.emptyDayTitle), findsOneWidget);
      expect(find.text(LocationCopy.today), findsOneWidget);
    });

    testWidgets('a refused day says so with a retry', (tester) async {
      await pump(
        tester,
        FakeTrailRepository()..failWith = const PermissionDeniedFailure(),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppCopy.retry), findsOneWidget);
    });

    testWidgets('a day with a stop and an arrival lists both', (tester) async {
      final clock = HouseholdClock('Africa/Johannesburg');
      final trails = FakeTrailRepository()
        ..days[clock.today.iso] = TrailDay(
          points: [
            TrailPoint(
              at: now.subtract(const Duration(minutes: 30)),
              point: _school.centre,
              accuracyMetres: 10,
            ),
            TrailPoint(at: now, point: _school.centre, accuracyMetres: 10),
          ],
          events: [
            PlaceEvent(
              placeId: 'school',
              kind: PlaceEventKind.arrive,
              at: now.subtract(const Duration(minutes: 29)),
            ),
          ],
        );
      await pump(tester, trails);
      places.emitPlaces([_school]);
      await tester.pumpAndSettle();
      expect(find.text('Parkhurst Primary'), findsOneWidget);
      expect(
        find.text(LocationCopy.arrived('Parkhurst Primary')),
        findsOneWidget,
      );
    });

    testWidgets('survives dark at 200% text on a 360-wide phone', (
      tester,
    ) async {
      darkAndLarge(tester);
      await pump(
        tester,
        FakeTrailRepository(),
        brightness: Brightness.dark,
        scale: 2,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('always sharing from the map', () {
    late FakeLiveLocationRepository repository;
    late FakeLocationReporter reporter;
    late FakeLocationEngine engine;
    late AlwaysSharing always;
    late LiveLocationController controller;

    setUp(() {
      repository = FakeLiveLocationRepository();
      reporter = FakeLocationReporter();
      engine = FakeLocationEngine();
      always = AlwaysSharing(
        engine: engine,
        liveLocationRepository: repository,
        locationReporter: reporter,
        observeLifecycle: false,
      );
      controller = LiveLocationController(
        liveLocationRepository: repository,
        locationReporter: reporter,
        placesRepository: places,
        householdId: Fixtures.householdId,
        viewerMemberId: Fixtures.samMemberId,
        members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
      );
    });

    tearDown(() async {
      controller.dispose();
      always.dispose();
      await engine.close();
      await repository.close();
      await reporter.close();
    });

    Future<void> pump(
      WidgetTester tester, {
      Brightness brightness = Brightness.light,
      double scale = 1,
    }) => pumpScreen(
      tester,
      const LiveLocationScreen(),
      providers: [
        ChangeNotifierProvider<LiveLocationController>.value(value: controller),
        ChangeNotifierProvider<AlwaysSharing>.value(value: always),
        _premium(),
      ],
      brightness: brightness,
      textScale: scale,
    );

    testWidgets('the disclosure comes first, then the engine starts', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400 * 3, 1400 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await pump(tester);
      repository.emitLocations([]);
      await tester.pumpAndSettle();

      await tester.tap(find.text(LocationCopy.always));
      await tester.pumpAndSettle();
      expect(find.text(LocationCopy.disclosureTitle), findsOneWidget);
      expect(engine.started, isEmpty, reason: 'nothing before the disclosure');

      await tester.tap(find.text(LocationCopy.disclosureContinue));
      await tester.pumpAndSettle();
      expect(engine.started.single.memberId, Fixtures.samMemberId);
      expect(find.text(LocationCopy.alwaysOn), findsOneWidget);
    });

    testWidgets('not now starts nothing', (tester) async {
      tester.view.physicalSize = const Size(400 * 3, 1400 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await pump(tester);
      repository.emitLocations([]);
      await tester.pumpAndSettle();

      await tester.tap(find.text(LocationCopy.always));
      await tester.pumpAndSettle();
      await tester.tap(find.text(LocationCopy.disclosureNotNow));
      await tester.pumpAndSettle();
      expect(engine.started, isEmpty);
    });

    testWidgets('while sharing always, pause is one tap and removes the pin', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400 * 3, 1400 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      engine.running = const EngineStatusForTest();
      await always.refresh();
      await pump(tester);
      repository.emitLocations([
        MemberLocation(
          id: Fixtures.samMemberId,
          point: _school.centre,
          accuracyMetres: 10,
          reportedAt: DateTime.now(),
          sharingUntil: DateTime.now().add(const Duration(hours: 24)),
          mode: ShareMode.continuous,
          batteryPercent: 80,
          charging: false,
          motion: DeviceMotion.still,
        ),
      ]);
      await tester.pumpAndSettle();

      await tester.tap(find.text(LocationCopy.pause));
      await tester.pumpAndSettle();
      expect(engine.stops, 1);
      expect(repository.stopped.single.memberId, Fixtures.samMemberId);
    });

    testWidgets('survives dark at 200% text while sharing always', (
      tester,
    ) async {
      darkAndLarge(tester);
      engine.running = const EngineStatusForTest();
      await always.refresh();
      await pump(tester, brightness: Brightness.dark, scale: 2);
      repository.emitLocations([]);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
