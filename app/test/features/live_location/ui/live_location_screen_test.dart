import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/features/live_location/model/member_location.dart';
import 'package:nestprep/features/live_location/state/live_location_controller.dart';
import 'package:nestprep/features/live_location/ui/live_location_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_live_location.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

final _now = DateTime.utc(2026, 9, 18, 14);
const _somewhere = Coordinates(latitude: -26.2041, longitude: 28.0473);

MemberLocation _location(
  String memberId, {
  Duration reportedAgo = Duration.zero,
  Duration sharingFor = const Duration(hours: 1),
}) => MemberLocation(
  id: memberId,
  point: _somewhere,
  accuracyMetres: 12,
  reportedAt: _now.subtract(reportedAgo),
  sharingUntil: _now.add(sharingFor),
);

void main() {
  late FakeLiveLocationRepository repository;
  late FakeLocationReporter reporter;
  late LiveLocationController controller;

  setUp(() {
    repository = FakeLiveLocationRepository();
    reporter = FakeLocationReporter();
    controller = LiveLocationController(
      liveLocationRepository: repository,
      locationReporter: reporter,
      householdId: Fixtures.householdId,
      viewerMemberId: Fixtures.samMemberId,
      members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
      now: () => _now,
    );
  });

  tearDown(() async {
    controller.dispose();
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
    ],
    brightness: brightness,
    textScale: scale,
  );

  group('the four states', () {
    testWidgets('holds the layout while it loads', (tester) async {
      await pump(tester);
      await tester.pump();

      expect(find.byKey(const ValueKey('loading')), findsOneWidget);
      expect(find.text(AppCopy.locationTitle), findsOneWidget);
    });

    testWidgets('a household of one says so, and keeps the way to share', (
      tester,
    ) async {
      // Its own controller, created and disposed inside the test, because a
      // ticker started in the body is a pending timer the binding counts.
      final solo = LiveLocationController(
        liveLocationRepository: repository,
        locationReporter: reporter,
        householdId: Fixtures.householdId,
        viewerMemberId: Fixtures.samMemberId,
        members: [Fixtures.sam],
        now: () => _now,
      );
      await pumpScreen(
        tester,
        const LiveLocationScreen(),
        providers: [
          ChangeNotifierProvider<LiveLocationController>.value(value: solo),
        ],
      );
      repository.emitLocations([]);
      await tester.pumpAndSettle();

      expect(find.text(AppCopy.locationAloneTitle), findsOneWidget);
      expect(
        find.text(AppCopy.locationOneHour),
        findsOneWidget,
        reason: 'the empty state must not take away the control that fills it',
      );
      solo.dispose();
    });

    testWidgets('a refused read shows copy and a way to try again', (
      tester,
    ) async {
      await pump(tester);
      repository.failLocationsWith(const PermissionDeniedFailure());
      await tester.pumpAndSettle();

      expect(
        find.text(AppCopy.failure(const PermissionDeniedFailure())),
        findsOneWidget,
      );
      expect(find.text(AppCopy.retry), findsOneWidget);
    });

    testWidgets('the household is listed, sharing first', (tester) async {
      await pump(tester);
      repository.emitLocations([_location(Fixtures.thandiMemberId)]);
      await tester.pumpAndSettle();

      expect(find.text(Fixtures.thandi.displayName), findsOneWidget);
      expect(find.text(Fixtures.kid.displayName), findsOneWidget);
      expect(
        find.text(Fixtures.sam.displayName),
        findsNothing,
        reason: 'the viewer is the card at the top, not a row',
      );
    });
  });

  group('what a row says', () {
    testWidgets('a fresh position is here now, with how sure the phone was', (
      tester,
    ) async {
      await pump(tester);
      repository.emitLocations([_location(Fixtures.thandiMemberId)]);
      await tester.pumpAndSettle();

      expect(find.textContaining(AppCopy.locationHereNow), findsOneWidget);
      expect(find.textContaining(AppCopy.withinMetres(12)), findsOneWidget);
    });

    testWidgets('an old position says how old, never that it is here', (
      tester,
    ) async {
      await pump(tester);
      repository.emitLocations([
        _location(
          Fixtures.thandiMemberId,
          reportedAgo: const Duration(minutes: 24),
        ),
      ]);
      await tester.pumpAndSettle();

      expect(find.textContaining('24 minutes ago'), findsOneWidget);
      expect(find.textContaining(AppCopy.locationHereNow), findsNothing);
    });

    testWidgets('somebody not sharing is shown saying so', (tester) async {
      await pump(tester);
      repository.emitLocations([]);
      await tester.pumpAndSettle();

      expect(find.textContaining(AppCopy.locationNotSharing), findsOneWidget);
    });

    testWidgets('a profile nobody has claimed says that instead', (
      tester,
    ) async {
      await pump(tester);
      repository.emitLocations([]);
      await tester.pumpAndSettle();

      expect(find.textContaining(AppCopy.householdUnclaimed), findsOneWidget);
    });
  });

  group('the one control', () {
    testWidgets('starts a share for the window that was tapped', (
      tester,
    ) async {
      await pump(tester);
      repository.emitLocations([]);
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppCopy.locationFourHours));
      await tester.pumpAndSettle();

      expect(reporter.started.single.until, _now.add(const Duration(hours: 4)));
      expect(reporter.started.single.memberId, Fixtures.samMemberId);
    });

    testWidgets('while sharing it says until when, and offers one way out', (
      tester,
    ) async {
      await pump(tester);
      repository.emitLocations([_location(Fixtures.samMemberId)]);
      await tester.pumpAndSettle();

      // 14:00 UTC is 16:00 where this household lives.
      expect(
        find.text('${AppCopy.locationSharingUntil} 17:00'),
        findsOneWidget,
      );
      expect(find.text(AppCopy.locationStop), findsOneWidget);
      expect(find.text(AppCopy.locationOneHour), findsNothing);

      await tester.tap(find.text(AppCopy.locationStop));
      await tester.pumpAndSettle();

      expect(reporter.stopped.single.memberId, Fixtures.samMemberId);
    });

    testWidgets('a refusal on this phone is shown in words', (tester) async {
      await pump(tester);
      repository.emitLocations([]);
      await tester.pumpAndSettle();
      reporter.refuseStartWith = const LocationFailure(
        LocationProblem.switchedOff,
      );

      await tester.tap(find.text(AppCopy.locationOneHour));
      await tester.pumpAndSettle();

      expect(
        find.text(
          AppCopy.failure(const LocationFailure(LocationProblem.switchedOff)),
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    repository.emitLocations([
      _location(Fixtures.thandiMemberId),
      _location(Fixtures.samMemberId, reportedAgo: const Duration(minutes: 40)),
    ]);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
