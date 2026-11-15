import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/accounts/model/kid_identity.dart';
import 'package:nestprep/features/household/data/household_repository.dart';
import 'package:nestprep/features/live_location/data/live_location_repository.dart';
import 'package:nestprep/features/live_location/data/location_engine.dart';
import 'package:nestprep/features/live_location/data/location_reporter.dart';
import 'package:nestprep/features/live_location/data/places_repository.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/features/live_location/model/member_location.dart';
import 'package:nestprep/features/live_location/state/always_sharing.dart';
import 'package:nestprep/features/live_location/ui/always_sharing_guard.dart';
import 'package:nestprep/features/live_location/ui/kid_location_sheet.dart';
import 'package:nestprep/features/subscriptions/data/entitlement_repository.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/state/household_entitlement.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_household.dart';
import '../../../support/fake_live_location.dart';
import '../../../support/fake_subscriptions.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

const _kid = KidIdentity(
  householdId: Fixtures.householdId,
  memberId: Fixtures.kidMemberId,
);

void main() {
  late FakeLocationEngine engine;
  late FakeLiveLocationRepository repository;
  late FakeLocationReporter reporter;
  late FakePlacesRepository places;
  late AlwaysSharing always;

  setUp(() {
    engine = FakeLocationEngine();
    repository = FakeLiveLocationRepository();
    reporter = FakeLocationReporter();
    places = FakePlacesRepository();
    always = AlwaysSharing(
      engine: engine,
      liveLocationRepository: repository,
      locationReporter: reporter,
      observeLifecycle: false,
    );
  });

  tearDown(() async {
    always.dispose();
    await engine.close();
    await repository.close();
    await reporter.close();
    await places.close();
  });

  group('the guard', () {
    testWidgets('stops always-sharing once, when premium is known to be over', (
      tester,
    ) async {
      engine.running = const EngineStatusForTest();
      await always.refresh();
      final entitlements = FakeEntitlementRepository(initial: Entitlement.free);
      await pumpScreen(
        tester,
        const AlwaysSharingGuard(child: SizedBox.shrink()),
        providers: [
          ChangeNotifierProvider<AlwaysSharing>.value(value: always),
          Provider<PlacesRepository>.value(value: places),
          ChangeNotifierProvider<HouseholdEntitlement>(
            lazy: false,
            create: (_) => HouseholdEntitlement(
              entitlementRepository: entitlements,
              householdId: Fixtures.householdId,
            ),
          ),
        ],
      );
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(engine.stops, 1);
      expect(
        always.isSharingFor(Fixtures.householdId, Fixtures.samMemberId),
        isFalse,
      );
    });

    testWidgets('stops a timed share too, and takes the pin down', (
      tester,
    ) async {
      reporter.reporting = (
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
      );
      final entitlements = FakeEntitlementRepository(
        initial: Entitlement(
          premiumUntil: DateTime.now().add(const Duration(days: 9)),
        ),
      );
      await pumpScreen(
        tester,
        const AlwaysSharingGuard(child: SizedBox.shrink()),
        providers: [
          ChangeNotifierProvider<AlwaysSharing>.value(value: always),
          Provider<PlacesRepository>.value(value: places),
          Provider<LocationReporter>.value(value: reporter),
          ChangeNotifierProvider<HouseholdEntitlement>(
            lazy: false,
            create: (_) => HouseholdEntitlement(
              entitlementRepository: entitlements,
              householdId: Fixtures.householdId,
            ),
          ),
        ],
      );
      await tester.pumpAndSettle();
      expect(reporter.stopped, isEmpty);

      entitlements.emit(Entitlement.free);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(reporter.stopped.single, (
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
      ));
    });

    testWidgets('leaves a window in another household alone', (tester) async {
      reporter.reporting = (
        householdId: 'h-other',
        memberId: Fixtures.samMemberId,
      );
      await pumpScreen(
        tester,
        const AlwaysSharingGuard(child: SizedBox.shrink()),
        providers: [
          ChangeNotifierProvider<AlwaysSharing>.value(value: always),
          Provider<PlacesRepository>.value(value: places),
          Provider<LocationReporter>.value(value: reporter),
        ],
      );
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(reporter.stopped, isEmpty);
    });

    testWidgets('leaves a premium household sharing', (tester) async {
      engine.running = const EngineStatusForTest();
      await always.refresh();
      reporter.reporting = (
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
      );
      await pumpScreen(
        tester,
        const AlwaysSharingGuard(child: SizedBox.shrink()),
        providers: [
          ChangeNotifierProvider<AlwaysSharing>.value(value: always),
          Provider<PlacesRepository>.value(value: places),
          Provider<LocationReporter>.value(value: reporter),
          ChangeNotifierProvider<HouseholdEntitlement>(
            lazy: false,
            create: (_) => HouseholdEntitlement(
              entitlementRepository: FakeEntitlementRepository(
                initial: Entitlement(
                  premiumUntil: DateTime.now().add(const Duration(days: 9)),
                ),
              ),
              householdId: Fixtures.householdId,
            ),
          ),
        ],
      );
      await tester.pumpAndSettle();
      expect(engine.stops, 0);
      expect(reporter.stopped, isEmpty);
    });
  });

  group('a kid phone', () {
    late FakeHouseholdRepository households;
    late FakeEntitlementRepository entitlements;

    setUp(() {
      households = FakeHouseholdRepository();
      entitlements = FakeEntitlementRepository(
        initial: Entitlement(
          premiumUntil: DateTime.now().add(const Duration(days: 9)),
        ),
      );
    });

    Future<void> pump(
      WidgetTester tester, {
      double scale = 1,
      Brightness brightness = Brightness.light,
    }) => pumpScreen(
      tester,
      const Scaffold(body: KidLocationSheet(kid: _kid)),
      providers: [
        ChangeNotifierProvider<AlwaysSharing>.value(value: always),
        Provider<HouseholdRepository>.value(value: households),
        Provider<EntitlementRepository>.value(value: entitlements),
        Provider<LiveLocationRepository>.value(value: repository),
        Provider<PlacesRepository>.value(value: places),
        Provider<LocationReporter>.value(value: reporter),
      ],
      textScale: scale,
      brightness: brightness,
    );

    MemberLocation kidWindow() => MemberLocation(
      id: Fixtures.kidMemberId,
      point: const Coordinates(latitude: -26.2, longitude: 28.0),
      accuracyMetres: 10,
      reportedAt: DateTime.now(),
      sharingUntil: DateTime.now().add(const Duration(hours: 1)),
    );

    testWidgets('loads, then offers the windows and always', (tester) async {
      await pump(tester);
      expect(find.text(LocationCopy.oneHour), findsNothing);
      households.emitHousehold(Fixtures.household());
      repository.emitLocations([]);
      await tester.pumpAndSettle();
      expect(find.text(LocationCopy.always), findsOneWidget);
      expect(find.text(LocationCopy.kidLockedTitle), findsNothing);
      await tester.tap(find.text(LocationCopy.oneHour));
      await tester.pumpAndSettle();
      expect(reporter.started.single.memberId, Fixtures.kidMemberId);
    });

    testWidgets('in a free household it is locked: who to ask, nothing to '
        'buy, nothing to start', (tester) async {
      entitlements.emit(Entitlement.free);
      await pump(tester);
      households.emitHousehold(Fixtures.household());
      repository.emitLocations([]);
      await tester.pumpAndSettle();

      expect(find.text(LocationCopy.kidLockedTitle), findsOneWidget);
      expect(find.text(LocationCopy.kidLockedBody), findsOneWidget);
      expect(
        find.bySemanticsLabel(SubscriptionCopy.lockedHint),
        findsOneWidget,
      );
      expect(find.text(SubscriptionCopy.seePremium), findsNothing);
      expect(find.byType(NestButton), findsNothing);
      expect(find.byType(NestChip), findsNothing);
      expect(find.text(LocationCopy.always), findsNothing);
      expect(reporter.started, isEmpty);
      expect(reporter.stopped, isEmpty);
      expect(engine.started, isEmpty);
    });

    testWidgets('premium ending stops the kid phone’s window and removes '
        'its pin', (tester) async {
      await pump(tester);
      households.emitHousehold(Fixtures.household());
      repository.emitLocations([kidWindow()]);
      await tester.pumpAndSettle();
      expect(find.text(LocationCopy.stop), findsOneWidget);
      expect(reporter.stopped, isEmpty);

      entitlements.emit(Entitlement.free);
      await tester.pumpAndSettle();
      repository.emitLocations([kidWindow()]);
      await tester.pumpAndSettle();

      expect(find.text(LocationCopy.kidLockedTitle), findsOneWidget);
      expect(reporter.stopped.single, (
        householdId: Fixtures.householdId,
        memberId: Fixtures.kidMemberId,
      ));
    });

    testWidgets('and stops it sharing always', (tester) async {
      engine.running = const EngineStatus(
        running: true,
        householdId: Fixtures.householdId,
        memberId: Fixtures.kidMemberId,
      );
      await always.refresh();
      entitlements.emit(Entitlement.free);
      await pump(tester);
      households.emitHousehold(Fixtures.household());
      repository.emitLocations([]);
      await tester.pumpAndSettle();

      expect(engine.stops, 1);
      expect(
        always.isSharingFor(Fixtures.householdId, Fixtures.kidMemberId),
        isFalse,
      );
      expect(find.text(LocationCopy.pause), findsNothing);
    });

    testWidgets('an entitlement that cannot be read locks, and stops '
        'nothing', (tester) async {
      entitlements = FakeEntitlementRepository();
      await pump(tester);
      households.emitHousehold(Fixtures.household());
      repository.emitLocations([kidWindow()]);
      entitlements.fail(const UnavailableFailure());
      await tester.pumpAndSettle();

      expect(find.text(LocationCopy.kidLockedTitle), findsOneWidget);
      expect(reporter.stopped, isEmpty);
    });

    testWidgets('an open window can be stopped from the kid phone', (
      tester,
    ) async {
      await pump(tester);
      households.emitHousehold(Fixtures.household());
      repository.emitLocations([kidWindow()]);
      await tester.pumpAndSettle();
      await tester.tap(find.text(LocationCopy.stop));
      await tester.pumpAndSettle();
      expect(reporter.stopped.single.memberId, Fixtures.kidMemberId);
    });

    testWidgets('holds at 200% text', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await pump(tester, scale: 2);
      households.emitHousehold(Fixtures.household());
      repository.emitLocations([]);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('locked holds in dark at 200% text on a 360-wide phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      entitlements.emit(Entitlement.free);
      await pump(tester, scale: 2, brightness: Brightness.dark);
      households.emitHousehold(Fixtures.household());
      repository.emitLocations([]);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(LocationCopy.kidLockedTitle), findsOneWidget);
    });
  });
}
