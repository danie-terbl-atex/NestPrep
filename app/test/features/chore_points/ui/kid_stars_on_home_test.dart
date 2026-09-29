import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/chore_points/model/kid_chore_note.dart';
import 'package:nestprep/features/chore_points/model/reward_request.dart';
import 'package:nestprep/features/chore_points/state/kid_points_controller.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/kid_accounts/state/kid_home_controller.dart';
import 'package:nestprep/features/kid_accounts/ui/kid_home_screen.dart';
import 'package:nestprep/shared/copy/points_copy.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_chore_points.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/kid_home_fixture.dart';
import '../../../support/pump_screen.dart';

/// A child's stars on their own device (todos ADR-0003): the count, what each
/// job is worth and where its stars are, a celebration when they land, and a
/// shelf of treats to ask for.
void main() {
  setUpAll(tz_data.initializeTimeZones);

  late KidHomeFixture fixture;

  setUp(() => fixture = KidHomeFixture());
  tearDown(() => fixture.close());

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) => pumpScreen(
    tester,
    const KidHomeScreen(),
    providers: [
      ChangeNotifierProvider<KidHomeController>.value(
        value: fixture.controller,
      ),
      ChangeNotifierProvider<KidPointsController>.value(value: fixture.stars),
    ],
    brightness: brightness,
    textScale: scale,
  );

  /// Scrolls [finder] fully on screen and lets the list settle, so a tap
  /// lands on it and not beside it.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  final today = KidHomeFixture.today;
  const kid = Fixtures.kidMemberId;

  testWidgets('shows the stars, the streak and what each job is worth', (
    tester,
  ) async {
    await pump(tester);
    await tester.runAsync(() async {
      await fixture.arrive(
        tasks: [
          KidHomeFixture.chore('bed', 'Make your bed', points: 5),
          KidHomeFixture.chore('room', 'Tidy your room', points: 10),
          KidHomeFixture.chore('teeth', 'Brush teeth'),
        ],
        completions: [KidHomeFixture.done('room')],
      );
      await fixture.starsArrive(
        claims: [
          PointsFixtures.claim('room', today, memberId: kid, points: 10),
        ],
      );
      fixture.points.emitBalance(
        PointsFixtures.balance(kid, 12, streak: 3, lastDay: today),
      );
      await pumpEventQueue();
    });
    await tester.pumpAndSettle();

    expect(find.text('12'), findsOneWidget);
    expect(find.text(PointsCopy.kidStreak(3)), findsOneWidget);
    expect(find.text('+5 stars'), findsOneWidget);
    final waiting = find.text(PointsCopy.kidNote(const WaitingForGrownUp(10))!);
    await reveal(tester, waiting);
    expect(waiting, findsOneWidget);
  });

  testWidgets('stars that land while the child looks are celebrated', (
    tester,
  ) async {
    await pump(tester);
    await tester.runAsync(() async {
      await fixture.arrive();
      await fixture.starsArrive(stars: 5);
    });
    await tester.pumpAndSettle();
    expect(find.text(PointsCopy.kidJustEarned(5)), findsNothing);

    await tester.runAsync(() async {
      fixture.points.emitBalance(PointsFixtures.balance(kid, 10));
      await pumpEventQueue();
    });
    await tester.pump();
    // Part-way through the flight, the burst is on screen and the words are
    // already there.
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text(PointsCopy.kidJustEarned(5)), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsWidgets);
    await tester.pumpAndSettle();
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('a treat within reach is asked for after a yes', (tester) async {
    await pump(tester);
    await tester.runAsync(() async {
      await fixture.arrive();
      await fixture.starsArrive(
        stars: 12,
        rewards: [PointsFixtures.reward('ice-cream', 'Ice cream', 10)],
      );
    });
    await tester.pumpAndSettle();

    await reveal(tester, find.text(PointsCopy.kidGetIt));
    await tester.tap(find.text(PointsCopy.kidGetIt));
    await tester.pumpAndSettle();
    expect(find.text(PointsCopy.kidAskConfirm('Ice cream', 10)), findsOne);

    await tester.tap(find.text(PointsCopy.kidAskYes));
    await tester.pumpAndSettle();
    expect(fixture.rewards.requested.single, (
      rewardId: 'ice-cream',
      memberId: kid,
      requestedBy: kid,
    ));
  });

  testWidgets('"not yet" asks for nothing', (tester) async {
    await pump(tester);
    await tester.runAsync(() async {
      await fixture.arrive();
      await fixture.starsArrive(
        stars: 12,
        rewards: [PointsFixtures.reward('ice-cream', 'Ice cream', 10)],
      );
    });
    await tester.pumpAndSettle();
    await reveal(tester, find.text(PointsCopy.kidGetIt));
    await tester.tap(find.text(PointsCopy.kidGetIt));
    await tester.pumpAndSettle();
    await tester.tap(find.text(PointsCopy.kidAskNotYet));
    await tester.pumpAndSettle();
    expect(fixture.rewards.requested, isEmpty);
  });

  testWidgets('a treat out of reach says how far, and offers no button', (
    tester,
  ) async {
    await pump(tester);
    await tester.runAsync(() async {
      await fixture.arrive();
      await fixture.starsArrive(
        stars: 3,
        rewards: [PointsFixtures.reward('movie', 'Movie night', 30)],
      );
    });
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(PointsCopy.kidMoreToGo(27)), 200);
    expect(find.text(PointsCopy.kidGetIt), findsNothing);
  });

  testWidgets('what the child asked for says where it stands', (tester) async {
    await pump(tester);
    await tester.runAsync(() async {
      await fixture.arrive();
      await fixture.starsArrive(
        stars: 2,
        rewards: [PointsFixtures.reward('ice-cream', 'Ice cream', 10)],
        requests: [
          PointsFixtures.request('a', memberId: kid),
          PointsFixtures.request(
            'b',
            memberId: kid,
            title: 'Movie night',
            status: RequestStatus.refused,
            refusal: RequestRefusal.notEnoughPoints,
          ),
        ],
      );
    });
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(PointsCopy.kidRequestRefused(RequestRefusal.notEnoughPoints)),
      200,
    );
    expect(find.text(PointsCopy.kidRequestWaiting), findsOneWidget);
    // Asked for and waiting: the shelf says "asked" rather than a button.
    expect(find.text(PointsCopy.kidAsked), findsOneWidget);
  });

  testWidgets('an empty shelf says who fills it', (tester) async {
    await pump(tester);
    await tester.runAsync(() async {
      await fixture.arrive();
      await fixture.starsArrive();
    });
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(PointsCopy.kidShelfEmpty), 200);
    expect(find.text(PointsCopy.kidNoStarsYet), findsOneWidget);
  });

  testWidgets('a grant that only looks shows the shelf without the button', (
    tester,
  ) async {
    await pump(tester);
    await tester.runAsync(() async {
      await fixture.arrive();
      fixture.households.emitMember(
        Fixtures.kid.copyWith(
          access: AccessDefaults.kid.withLevel(
            HouseholdArea.todos,
            AccessLevel.view,
          ),
        ),
      );
      await fixture.starsArrive(
        stars: 20,
        rewards: [PointsFixtures.reward('ice-cream', 'Ice cream', 10)],
      );
    });
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(PointsCopy.kidEnoughStars), 200);
    expect(find.text(PointsCopy.kidGetIt), findsNothing);
  });

  testWidgets('a grant that hides jobs hides the stars too', (tester) async {
    await pump(tester);
    await tester.runAsync(() async {
      await fixture.arrive();
      fixture.households.emitMember(
        Fixtures.kid.copyWith(
          access: AccessDefaults.kid.withLevel(
            HouseholdArea.todos,
            AccessLevel.none,
          ),
        ),
      );
      await pumpEventQueue();
    });
    await tester.pumpAndSettle();
    expect(find.text(PointsCopy.kidShelfTitle), findsNothing);
    expect(fixture.stars.points, isNull);
  });

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    await tester.runAsync(() async {
      await fixture.arrive(
        tasks: [
          KidHomeFixture.chore('room', 'Tidy your room properly', points: 20),
        ],
        completions: [KidHomeFixture.done('room')],
      );
      await fixture.starsArrive(
        stars: 1234,
        claims: [
          PointsFixtures.claim('room', today, memberId: kid, points: 20),
        ],
        rewards: [
          PointsFixtures.reward('late', 'Stay up late on Saturday', 9999),
          PointsFixtures.reward('ice-cream', 'Ice cream', 10),
        ],
        requests: [PointsFixtures.request('a', memberId: kid)],
      );
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text(PointsCopy.kidAskedTitle), 300);
    expect(tester.takeException(), isNull);
  });
}
