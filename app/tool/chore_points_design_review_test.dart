import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/chore_points/data/points_repository.dart';
import 'package:nestprep/features/chore_points/model/reward.dart';
import 'package:nestprep/features/chore_points/state/chore_points_controller.dart';
import 'package:nestprep/features/chore_points/ui/chore_points_screen.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_chore_points.dart';
import '../test/support/household_fixtures.dart';
import 'review_press.dart';

/// Not a test — the parent's half of stars and rewards for the screenshot
/// press (todos ADR-0003): a chore waiting for a look, a treat to hand over,
/// a child's stars and the shelf, in light and dark. The child's half is the
/// kid home, in `kid_design_review_test.dart`. Regenerate with
///
///     flutter test tool/chore_points_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  Future<void> stars(WidgetTester tester, Brightness brightness) async {
    final points = FakePointsRepository();
    final rewards = FakeRewardRepository();
    final controller = ChorePointsController(
      pointsRepository: points,
      rewardRepository: rewards,
      pointsDirectory: FakePointsDirectory(),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
    );
    addTearDown(() async {
      controller.dispose();
      await points.close();
      await rewards.close();
    });
    final today = CalendarDate.fromDateTime(DateTime.now());
    await captureScreen(
      tester,
      'stars-and-rewards-${brightness.name}',
      screen: const ChorePointsScreen(),
      providers: [
        Provider<PointsRepository>.value(value: points),
        ChangeNotifierProvider<ChorePointsController>.value(value: controller),
      ],
      brightness: brightness,
      emit: () async {
        points
          ..emitPending([
            PointsFixtures.claim(
              'room',
              today,
              memberId: Fixtures.kidMemberId,
              points: 10,
            ),
          ])
          ..emitBalances([
            PointsFixtures.balance(
              Fixtures.kidMemberId,
              18,
              streak: 4,
              lastDay: today,
            ),
          ]);
        rewards
          ..emitWaiting([
            PointsFixtures.request('r1', memberId: Fixtures.kidMemberId),
          ])
          ..emitRewards([
            PointsFixtures.reward('ice-cream', 'Ice cream', 15),
            PointsFixtures.reward(
              'movie',
              'Movie night',
              40,
              icon: RewardIcon.movie,
            ),
          ]);
        await tester.pumpAndSettle();
      },
    );
  }

  for (final brightness in Brightness.values) {
    testWidgets('stars and rewards — ${brightness.name}', (tester) async {
      await stars(tester, brightness);
    });
  }
}
