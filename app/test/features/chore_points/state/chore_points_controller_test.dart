import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/chore_points/data/points_directory.dart';
import 'package:nestprep/features/chore_points/model/point_claim.dart';
import 'package:nestprep/features/chore_points/model/points_board.dart';
import 'package:nestprep/features/chore_points/model/reward.dart';
import 'package:nestprep/features/chore_points/state/chore_points_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/fake_chore_points.dart';
import '../../../support/household_fixtures.dart';

/// The parent's stars screen (todos ADR-0003): four reads become one board,
/// and each decision is asked of the server once.
void main() {
  final today = CalendarDate(2026, 9, 29);
  const kid = Fixtures.kidMemberId;

  late FakePointsRepository points;
  late FakeRewardRepository rewards;
  late FakePointsDirectory directory;
  late ChorePointsController controller;

  setUp(() {
    points = FakePointsRepository();
    rewards = FakeRewardRepository();
    directory = FakePointsDirectory();
    controller = ChorePointsController(
      pointsRepository: points,
      rewardRepository: rewards,
      pointsDirectory: directory,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      members: [Fixtures.sam, Fixtures.kid],
    );
  });

  tearDown(() async {
    controller.dispose();
    await points.close();
    await rewards.close();
  });

  final pending = PointsFixtures.claim('room', today, memberId: kid);

  Future<void> arrive() async {
    points
      ..emitPending([pending])
      ..emitBalances([PointsFixtures.balance(kid, 12)]);
    rewards
      ..emitWaiting([PointsFixtures.request('r1', memberId: kid)])
      ..emitRewards([PointsFixtures.reward('ice-cream', 'Ice cream', 10)]);
    await pumpEventQueue();
  }

  PointsBoard board() => switch (controller.board) {
    AsyncData(:final value) => value,
    final other => fail('expected a board, got $other'),
  };

  test('waits for all four reads, then shows one board', () async {
    expect(controller.board, isA<AsyncLoading<PointsBoard>>());
    points.emitPending(const []);
    await pumpEventQueue();
    expect(controller.board, isA<AsyncLoading<PointsBoard>>());
    await arrive();
    expect(board().pendingClaims.single.id, pending.id);
    expect(board().kids.single.id, kid);
    expect(board().balanceOf(kid).balance, 12);
  });

  test('a failed read is the board’s error, and retry starts again', () async {
    points.failPendingWith(const UnavailableFailure());
    await pumpEventQueue();
    expect(controller.board, isA<AsyncFailure<PointsBoard>>());
    await controller.retry();
    expect(controller.board, isA<AsyncLoading<PointsBoard>>());
    await arrive();
    expect(controller.board, isA<AsyncData<PointsBoard>>());
  });

  test('approving asks the server once, however often it is tapped', () async {
    await arrive();
    directory.hold = Completer<void>();
    final first = controller.review(pending, ChoreReview.approve);
    final second = controller.review(pending, ChoreReview.approve);
    expect(controller.isBusy(pending.id), isTrue);
    directory.hold!.complete();
    await Future.wait([first, second]);
    expect(directory.reviews, [
      (completionId: pending.id, decision: ChoreReview.approve),
    ]);
    expect(controller.isBusy(pending.id), isFalse);
  });

  test('a refusal is kept for the banner, in the points vocabulary', () async {
    await arrive();
    directory.failWith = const PointsFailure(PointsProblem.alreadySettled);
    await controller.review(pending, ChoreReview.sendBack);
    expect(
      controller.actionFailure,
      isA<PointsFailure>().having(
        (f) => f.problem,
        'problem',
        PointsProblem.alreadySettled,
      ),
    );
  });

  test('hands a reward over, or declines it', () async {
    await arrive();
    final request = board().waitingRequests.single;
    await controller.settle(request, RewardSettlement.fulfil);
    await controller.settle(request, RewardSettlement.decline);
    expect(directory.settlements.map((s) => s.decision), [
      RewardSettlement.fulfil,
      RewardSettlement.decline,
    ]);
  });

  test('saves a reward trimmed, and refuses one it cannot store', () async {
    await controller.saveReward(
      title: '  Ice cream  ',
      cost: 10,
      icon: RewardIcon.iceCream,
    );
    await controller.saveReward(title: '   ', cost: 10, icon: RewardIcon.gift);
    await controller.saveReward(title: 'Pony', cost: 0, icon: RewardIcon.gift);
    await controller.saveReward(
      title: 'Pony',
      cost: Reward.maxCost + 1,
      icon: RewardIcon.gift,
    );
    expect(rewards.saved, [
      (rewardId: null, title: 'Ice cream', cost: 10, icon: RewardIcon.iceCream),
    ]);
  });

  test('removes a reward', () async {
    await controller.deleteReward('ice-cream');
    expect(rewards.deleted, ['ice-cream']);
  });

  test('spends a child’s stars for them, as the parent', () async {
    await controller.spendFor(
      kid,
      PointsFixtures.reward('ice-cream', 'Ice cream', 10),
    );
    expect(rewards.requested.single, (
      rewardId: 'ice-cream',
      memberId: kid,
      requestedBy: Fixtures.samMemberId,
    ));
  });

  test('follows the household when a child is added', () async {
    await arrive();
    final another = Fixtures.kid.copyWith(id: 'm-mia', displayName: 'Mia');
    controller.followMembers([Fixtures.sam, Fixtures.kid, another]);
    expect(board().kids.map((k) => k.id), [kid, 'm-mia']);
  });

  test('a claim status this build does not know reads as withdrawn', () {
    final read = PointClaim.fromJson({
      'id': 'x',
      'memberId': kid,
      'taskId': 't',
      'occurrenceDate': '2026-09-29',
      'title': 'T',
      'points': 1,
      'status': 'somethingNew',
    });
    expect(read.status, ClaimStatus.withdrawn);
  });
}
