import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/household_route.dart';
import 'package:nestprep/app/live_location_routes.dart';
import 'package:nestprep/features/live_location/data/live_location_repository.dart';
import 'package:nestprep/features/live_location/data/location_reporter.dart';
import 'package:nestprep/features/live_location/data/location_source.dart';
import 'package:nestprep/features/live_location/data/places_repository.dart';
import 'package:nestprep/features/live_location/data/trail_repository.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/features/live_location/model/member_location.dart';
import 'package:nestprep/features/live_location/ui/live_location_screen.dart';
import 'package:nestprep/features/live_location/ui/member_history_screen.dart';
import 'package:nestprep/features/live_location/ui/place_editor_screen.dart';
import 'package:nestprep/features/live_location/ui/places_screen.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_live_location.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

/// Where we are is Premium in full (subscriptions ADR-0008): every route of
/// it shows locked to a free household, and a locked route listens to
/// nothing and asks the phone for nothing.
void main() {
  late FakeLiveLocationRepository locations;
  late FakePlacesRepository places;
  late FakeLocationReporter reporter;
  late FakeLocationSource source;
  late FakeTrailRepository trails;

  setUp(() {
    locations = FakeLiveLocationRepository();
    places = FakePlacesRepository();
    reporter = FakeLocationReporter();
    source = FakeLocationSource();
    trails = FakeTrailRepository();
  });

  tearDown(() async {
    await locations.close();
    await places.close();
    await reporter.close();
    await source.close();
  });

  Future<SubscriptionHarness> pump(
    WidgetTester tester,
    String location, {
    Entitlement entitlement = Entitlement.free,
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    final harness = SubscriptionHarness(entitlement: entitlement);
    await pumpRouter(
      tester,
      router: GoRouter(initialLocation: location, routes: liveLocationRoutes()),
      providers: [
        ...harness.providers,
        Provider<LiveLocationRepository>.value(value: locations),
        Provider<PlacesRepository>.value(value: places),
        Provider<LocationReporter>.value(value: reporter),
        Provider<LocationSource>.value(value: source),
        Provider<TrailRepository>.value(value: trails),
      ],
      brightness: brightness,
      textScale: scale,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return harness;
  }

  final everyRoute = {
    'the map': HouseholdRoute.wherePathFor(Fixtures.householdId),
    'a member’s day': HouseholdRoute.historyPathFor(
      Fixtures.householdId,
      Fixtures.samMemberId,
    ),
    'the places': HouseholdRoute.placesPathFor(Fixtures.householdId),
    'a new place': HouseholdRoute.placePathFor(
      Fixtures.householdId,
      HouseholdRoute.newPlaceId,
    ),
    'a place by its link': HouseholdRoute.placePathFor(
      Fixtures.householdId,
      'school',
    ),
  };

  for (final MapEntry(key: name, value: location) in everyRoute.entries) {
    testWidgets('a free household sees $name locked, and nothing starts', (
      tester,
    ) async {
      await pump(tester, location);

      expect(
        find.text(SubscriptionCopy.headline(PremiumFeature.familyLocation)),
        findsOneWidget,
      );
      expect(find.text(SubscriptionCopy.seePremium), findsOneWidget);
      expect(find.byType(LiveLocationScreen), findsNothing);
      expect(find.byType(MemberHistoryScreen), findsNothing);
      expect(find.byType(PlacesScreen), findsNothing);
      expect(find.byType(PlaceEditorScreen), findsNothing);
      expect(locations.watched, 0);
      expect(places.watched, 0);
      expect(trails.asked, isEmpty);
      expect(reporter.started, isEmpty);
      expect(source.consentsAsked, 0);
    });
  }

  testWidgets('the lock opens the paywall on family location', (tester) async {
    final harness = await pump(
      tester,
      HouseholdRoute.wherePathFor(Fixtures.householdId),
    );
    expect(find.text(LocationCopy.title), findsOneWidget);

    await tester.tap(find.text(SubscriptionCopy.seePremium));
    await tester.pumpAndSettle();

    expect(
      harness.paywallOpens.opened.single.trigger,
      PremiumFeature.familyLocation,
    );
  });

  testWidgets('a lapsed household does not pick an open window back up', (
    tester,
  ) async {
    await pump(
      tester,
      HouseholdRoute.wherePathFor(Fixtures.householdId),
      entitlement: Entitlement(
        premiumUntil: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    );
    locations.emitLocations([
      MemberLocation(
        id: Fixtures.samMemberId,
        point: _somewhere,
        accuracyMetres: 10,
        reportedAt: DateTime.now(),
        sharingUntil: DateTime.now().add(const Duration(hours: 1)),
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text(SubscriptionCopy.seePremium), findsOneWidget);
    expect(reporter.started, isEmpty);
  });

  testWidgets('a Premium household gets the map', (tester) async {
    await pump(
      tester,
      HouseholdRoute.wherePathFor(Fixtures.householdId),
      entitlement: Entitlement(
        premiumUntil: DateTime.now().add(const Duration(days: 30)),
      ),
    );

    expect(find.byType(LiveLocationScreen), findsOneWidget);
    expect(find.text(SubscriptionCopy.seePremium), findsNothing);
    expect(locations.watched, 1);
  });

  testWidgets('locked survives dark at 200% text on a 360-wide phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(
      tester,
      HouseholdRoute.wherePathFor(Fixtures.householdId),
      brightness: Brightness.dark,
      scale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(find.text(SubscriptionCopy.seePremium), findsOneWidget);
  });
}

const _somewhere = Coordinates(latitude: -26.2041, longitude: 28.0473);
