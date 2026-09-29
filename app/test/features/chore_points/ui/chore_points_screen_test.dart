import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/chore_points/data/points_directory.dart';
import 'package:nestprep/features/chore_points/data/points_repository.dart';
import 'package:nestprep/features/chore_points/model/point_entry.dart';
import 'package:nestprep/features/chore_points/model/reward.dart';
import 'package:nestprep/features/chore_points/state/chore_points_controller.dart';
import 'package:nestprep/features/chore_points/ui/chore_points_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/points_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_chore_points.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// A parent's stars and rewards (todos ADR-0003), in all four states: what is
/// waiting and the two answers to it, each child's stars and their history,
/// and the shelf — whose add button is there on a household with nothing yet.
void main() {
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
      members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
    );
  });

  tearDown(() async {
    controller.dispose();
    await points.close();
    await rewards.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) => pumpScreen(
    tester,
    const ChorePointsScreen(),
    providers: [
      Provider<PointsRepository>.value(value: points),
      ChangeNotifierProvider<ChorePointsController>.value(value: controller),
    ],
    brightness: brightness,
    textScale: scale,
  );

  Future<void> arrive(
    WidgetTester tester, {
    bool waiting = true,
    List<Reward>? shelf,
  }) async {
    final today = CalendarDate.fromDateTime(DateTime.now());
    points
      ..emitPending([
        if (waiting)
          PointsFixtures.claim('room', today, memberId: kid, points: 10),
      ])
      ..emitBalances([PointsFixtures.balance(kid, 12)]);
    rewards
      ..emitWaiting([if (waiting) PointsFixtures.request('r1', memberId: kid)])
      ..emitRewards(
        shelf ?? [PointsFixtures.reward('ice-cream', 'Ice cream', 10)],
      );
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('holds the layout while it loads', (tester) async {
    await pump(tester);
    await tester.pump();
    expect(find.byKey(const ValueKey('loading')), findsOneWidget);
    expect(find.text(PointsCopy.screenTitle), findsOneWidget);
  });

  testWidgets('an error offers a retry, in words', (tester) async {
    await pump(tester);
    points.failPendingWith(const UnavailableFailure());
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.failure(const UnavailableFailure())), findsOne);
    expect(find.text(AppCopy.retry), findsOneWidget);
  });

  testWidgets('a chore waiting for a look is approved, once', (tester) async {
    await pump(tester);
    await arrive(tester);
    expect(find.text(PointsCopy.waitingTitle(2)), findsOneWidget);
    expect(find.text('Tidy your room'), findsOneWidget);

    await tester.tap(find.text(PointsCopy.reviewApprove));
    await tester.pumpAndSettle();
    expect(directory.reviews.single.decision, ChoreReview.approve);
  });

  testWidgets('a chore is sent back, and a reward handed over', (tester) async {
    await pump(tester);
    await arrive(tester);
    await tester.tap(find.text(PointsCopy.reviewSendBack));
    await reveal(tester, find.text(PointsCopy.settleGiven));
    await tester.tap(find.text(PointsCopy.settleGiven));
    await tester.pumpAndSettle();
    expect(directory.reviews.single.decision, ChoreReview.sendBack);
    expect(directory.settlements.single.decision, RewardSettlement.fulfil);
  });

  testWidgets('a refusal reaches the banner in words', (tester) async {
    await pump(tester);
    await arrive(tester);
    directory.failWith = const PointsFailure(PointsProblem.notFamily);
    await tester.tap(find.text(PointsCopy.reviewApprove));
    await tester.pumpAndSettle();
    expect(find.text(PointsCopy.problem(PointsProblem.notFamily)), findsOne);
  });

  testWidgets('nothing waiting, no rewards — each section says so in place, '
      'and the shelf can still be filled', (tester) async {
    await pump(tester);
    await arrive(tester, waiting: false, shelf: const []);
    expect(find.text(PointsCopy.waitingNone), findsOneWidget);
    await reveal(tester, find.text(PointsCopy.rewardsEmpty));

    await tester.tap(find.bySemanticsLabel(PointsCopy.rewardAdd));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Movie night');
    await tester.tap(find.text(PointsCopy.starsCount(50)));
    await tester.tap(
      find.bySemanticsLabel(PointsCopy.iconName(RewardIcon.movie)),
    );
    await tester.pump();
    await tester.ensureVisible(find.text(AppCopy.householdSave));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.householdSave));
    await tester.pumpAndSettle();

    expect(rewards.saved.single, (
      rewardId: null,
      title: 'Movie night',
      cost: 50,
      icon: RewardIcon.movie,
    ));
  });

  testWidgets('a cost that is not a whole number from 1 to 10 000 cannot be '
      'saved', (tester) async {
    await pump(tester);
    await arrive(tester, waiting: false, shelf: const []);
    await reveal(tester, find.text(PointsCopy.rewardsEmpty));
    await tester.tap(find.bySemanticsLabel(PointsCopy.rewardAdd));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Pony');
    await tester.enterText(find.byType(TextField).last, '0');
    await tester.pump();
    expect(find.text(PointsCopy.rewardCostInvalid), findsOneWidget);
    await tester.tap(find.text(AppCopy.householdSave));
    await tester.pumpAndSettle();
    expect(rewards.saved, isEmpty);
  });

  testWidgets('a reward is edited and removed from the shelf', (tester) async {
    await pump(tester);
    await arrive(tester, waiting: false);
    await reveal(tester, find.text('Ice cream'));
    await tester.tap(find.text('Ice cream'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(AppCopy.householdRemove));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.householdRemove));
    await tester.pumpAndSettle();
    expect(rewards.deleted, ['ice-cream']);
  });

  testWidgets('a child’s history shows where their stars came from', (
    tester,
  ) async {
    await pump(tester);
    await arrive(tester, waiting: false);
    await reveal(tester, find.text(PointsCopy.history));
    await tester.tap(find.text(PointsCopy.history));
    // The sheet's placeholder pulses until the lines arrive, so this waits
    // for the sheet to open rather than for the screen to settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    points.emitEntries(const [
      PointEntry(
        id: 'e1',
        memberId: kid,
        delta: 5,
        kind: EntryKind.chore,
        sourceId: 's',
        title: 'Make your bed',
      ),
      PointEntry(
        id: 'e2',
        memberId: kid,
        delta: -10,
        kind: EntryKind.reward,
        sourceId: 'r',
        title: 'Ice cream',
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('+5'), findsOneWidget);
    expect(find.text(PointsCopy.delta(-10)), findsOneWidget);
    expect(find.text(PointsCopy.entryKind(EntryKind.reward)), findsOneWidget);
  });

  testWidgets('a parent spends a child’s stars for them', (tester) async {
    await pump(tester);
    await arrive(tester, waiting: false);
    await reveal(tester, find.text(PointsCopy.spendFor));
    await tester.tap(find.text(PointsCopy.spendFor));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ice cream').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(PointsCopy.spendForYes));
    await tester.pumpAndSettle();
    expect(rewards.requested.single, (
      rewardId: 'ice-cream',
      memberId: kid,
      requestedBy: Fixtures.samMemberId,
    ));
  });

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pump(tester, brightness: Brightness.dark, scale: 2);
    await arrive(
      tester,
      shelf: [
        PointsFixtures.reward('late', 'Stay up late on a Saturday night', 9999),
      ],
    );
    expect(tester.takeException(), isNull);
    await reveal(tester, find.text(PointsCopy.rewardsTitle));
    expect(tester.takeException(), isNull);
  });
}
