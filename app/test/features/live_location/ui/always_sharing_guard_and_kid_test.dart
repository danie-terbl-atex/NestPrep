import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/accounts/model/kid_identity.dart';
import 'package:nestprep/features/household/data/household_repository.dart';
import 'package:nestprep/features/live_location/data/live_location_repository.dart';
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

    testWidgets('leaves a premium household sharing', (tester) async {
      engine.running = const EngineStatusForTest();
      await always.refresh();
      await pumpScreen(
        tester,
        const AlwaysSharingGuard(child: SizedBox.shrink()),
        providers: [
          ChangeNotifierProvider<AlwaysSharing>.value(value: always),
          Provider<PlacesRepository>.value(value: places),
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
    });
  });

  group('a kid phone', () {
    late FakeHouseholdRepository households;

    setUp(() => households = FakeHouseholdRepository());

    Future<void> pump(WidgetTester tester, {double scale = 1}) => pumpScreen(
      tester,
      const Scaffold(body: KidLocationSheet(kid: _kid)),
      providers: [
        ChangeNotifierProvider<AlwaysSharing>.value(value: always),
        Provider<HouseholdRepository>.value(value: households),
        Provider<EntitlementRepository>.value(
          value: FakeEntitlementRepository(initial: Entitlement.free),
        ),
        Provider<LiveLocationRepository>.value(value: repository),
        Provider<PlacesRepository>.value(value: places),
        Provider<LocationReporter>.value(value: reporter),
      ],
      textScale: scale,
    );

    testWidgets('loads, then offers the windows', (tester) async {
      await pump(tester);
      expect(find.text(LocationCopy.oneHour), findsNothing);
      households.emitHousehold(Fixtures.household());
      repository.emitLocations([]);
      await tester.pumpAndSettle();
      await tester.tap(find.text(LocationCopy.oneHour));
      await tester.pumpAndSettle();
      expect(reporter.started.single.memberId, Fixtures.kidMemberId);
      expect(
        find.text(LocationCopy.always),
        findsNothing,
        reason: 'not premium',
      );
    });

    testWidgets('an open window can be stopped from the kid phone', (
      tester,
    ) async {
      await pump(tester);
      households.emitHousehold(Fixtures.household());
      repository.emitLocations([
        MemberLocation(
          id: Fixtures.kidMemberId,
          point: const Coordinates(latitude: -26.2, longitude: 28.0),
          accuracyMetres: 10,
          reportedAt: DateTime.now(),
          sharingUntil: DateTime.now().add(const Duration(hours: 1)),
        ),
      ]);
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
  });
}
