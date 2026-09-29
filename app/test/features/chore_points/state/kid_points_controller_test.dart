import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/accounts/model/kid_identity.dart';
import 'package:nestprep/features/chore_points/model/kid_points.dart';
import 'package:nestprep/features/chore_points/state/kid_points_controller.dart';
import 'package:nestprep/features/kid_accounts/model/kid_areas.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/fake_chore_points.dart';
import '../../../support/household_fixtures.dart';

/// A child's stars on their own device (todos ADR-0003): they follow the
/// grant, celebrate a rise and nothing else, and ask as the child only.
void main() {
  final today = CalendarDate(2026, 9, 29);
  const kid = Fixtures.kidMemberId;
  const jobs = KidAreas(chores: true, canTick: true, food: true);
  const looksOnly = KidAreas(chores: true, canTick: false, food: true);

  late FakePointsRepository points;
  late FakeRewardRepository rewards;
  late KidPointsController controller;

  setUp(() {
    points = FakePointsRepository();
    rewards = FakeRewardRepository();
    controller = KidPointsController(
      pointsRepository: points,
      rewardRepository: rewards,
      identity: const KidIdentity(
        householdId: Fixtures.householdId,
        memberId: kid,
      ),
    );
  });

  tearDown(() async {
    controller.dispose();
    await points.close();
    await rewards.close();
  });

  Future<void> arrive({int stars = 0}) async {
    await pumpEventQueue();
    points
      ..emitBalance(PointsFixtures.balance(kid, stars))
      ..emitClaims(const []);
    rewards
      ..emitRewards([PointsFixtures.reward('ice-cream', 'Ice cream', 10)])
      ..emitMine(const []);
    await pumpEventQueue();
  }

  KidPoints loaded() => switch (controller.points) {
    AsyncData(:final value) => value,
    final other => fail('expected stars, got $other'),
  };

  test('shows nothing until the home knows today and the grant', () async {
    expect(controller.points, isNull);
    controller.follow(jobs, null);
    await pumpEventQueue();
    expect(controller.points, isNull);
    controller.follow(KidAreas.nothing, today);
    await pumpEventQueue();
    expect(controller.points, isNull);
  });

  test('opens its reads for this child, from the overdue horizon', () async {
    controller.follow(jobs, today);
    await pumpEventQueue();
    expect(controller.points, isA<AsyncLoading<KidPoints>>());
    await arrive(stars: 4);
    expect(loaded().stars, 4);
    expect(points.balanceFor, kid);
    expect(points.claimsFrom, today.addDays(-7));
  });

  test('celebrates a rise, and neither the first count nor spending', () async {
    controller.follow(jobs, today);
    await arrive(stars: 5);
    expect(loaded().celebration, isNull);

    points.emitBalance(PointsFixtures.balance(kid, 8));
    await pumpEventQueue();
    expect(loaded().celebration?.gained, 3);
    final first = loaded().celebration?.sequence;

    points.emitBalance(PointsFixtures.balance(kid, 11));
    await pumpEventQueue();
    expect(loaded().celebration?.sequence, isNot(first));

    points.emitBalance(PointsFixtures.balance(kid, 1));
    await pumpEventQueue();
    expect(loaded().celebration?.gained, 3, reason: 'spending is no party');
  });

  test('`view` shows the stars but cannot spend them', () async {
    controller.follow(looksOnly, today);
    await arrive(stars: 50);
    expect(loaded().canSpend, isFalse);
  });

  test('asks for a reward as this child, for this child', () async {
    controller.follow(jobs, today);
    await arrive(stars: 50);
    await controller.ask(PointsFixtures.reward('ice-cream', 'Ice cream', 10));
    expect(rewards.requested.single, (
      rewardId: 'ice-cream',
      memberId: kid,
      requestedBy: kid,
    ));
    expect(controller.isAsking(loaded().rewards.single), isFalse);
  });

  test('keeps a refused request for the banner', () async {
    controller.follow(jobs, today);
    await arrive(stars: 50);
    rewards.failWritesWith = const PermissionDeniedFailure();
    await controller.ask(PointsFixtures.reward('ice-cream', 'Ice cream', 10));
    expect(controller.actionFailure, isA<PermissionDeniedFailure>());
  });

  test(
    'a read the rules refuse hides the stars; any other shows a retry',
    () async {
      controller.follow(jobs, today);
      await pumpEventQueue();
      points.failBalanceWith(const PermissionDeniedFailure());
      await pumpEventQueue();
      expect(controller.points, isNull);

      await controller.retry();
      await pumpEventQueue();
      controller.follow(jobs, today.addDays(1));
      await pumpEventQueue();
      points.failBalanceWith(const UnavailableFailure());
      await pumpEventQueue();
      expect(controller.points, isA<AsyncFailure<KidPoints>>());
    },
  );

  test('a grant narrowed to nothing closes the stars', () async {
    controller.follow(jobs, today);
    await arrive(stars: 5);
    controller.follow(KidAreas.nothing, today);
    await pumpEventQueue();
    expect(controller.points, isNull);
  });
}
