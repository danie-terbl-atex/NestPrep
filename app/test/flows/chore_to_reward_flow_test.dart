import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/chore_points/data/points_directory.dart';
import 'package:nestprep/features/chore_points/data/points_repository.dart';
import 'package:nestprep/features/chore_points/model/kid_chore_note.dart';
import 'package:nestprep/features/chore_points/model/point_claim.dart';
import 'package:nestprep/features/chore_points/model/reward_request.dart';
import 'package:nestprep/features/chore_points/state/chore_points_controller.dart';
import 'package:nestprep/features/chore_points/state/kid_points_controller.dart';
import 'package:nestprep/features/chore_points/ui/chore_points_screen.dart';
import 'package:nestprep/features/household/ui/member_picker.dart';
import 'package:nestprep/features/kid_accounts/state/kid_home_controller.dart';
import 'package:nestprep/features/kid_accounts/ui/kid_home_screen.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/state/todo_controller.dart';
import 'package:nestprep/features/todos/ui/todo_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/points_copy.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../support/fake_chore_points.dart';
import '../support/fake_todo_repository.dart';
import '../support/household_fixtures.dart';
import '../support/kid_home_fixture.dart';
import '../support/pump_screen.dart';

/// Todos phase 2's definition of done, driven through the screens (todos
/// ADR-0003): a parent puts stars on a chore that a parent checks; the child
/// ticks it; the parent says it looks good; the child sees the stars land and
/// spends them on a treat; the parent hands it over; the child sees it is
/// theirs.
///
/// The server's part — the triggers that write claims, balances and request
/// statuses — is played here by emitting what they write. That part is proved
/// against the real rules and the real Functions in
/// `functions/test/emulator/chore_points.test.ts`; this proves every screen
/// hands on what it collected, end to end.
void main() {
  setUpAll(tz_data.initializeTimeZones);

  const kid = Fixtures.kidMemberId;
  final today = KidHomeFixture.today;

  /// A sheet is taller than the viewport; everything tapped in one is brought
  /// on screen first (the vault lesson on taps below a sheet's fold).
  Future<void> tapInSheet(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> tapShown(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(target, 200);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('from a starred chore to a treat in the child’s hands', (
    tester,
  ) async {
    // A phone's proportions, tall enough that a sheet's controls are on it.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    // ---- the parent's phone: a chore worth five stars, checked first ----
    final parentTodos = FakeTodoRepository();
    final parentBoard = TodoController(
      todoRepository: parentTodos,
      householdClock: HouseholdClock(
        'Africa/Johannesburg',
        now: () => KidHomeFixture.nowUtc,
      ),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      isAdmin: true,
    );
    addTearDown(() async {
      parentBoard.dispose();
      await parentTodos.close();
    });
    await pumpScreen(
      tester,
      TodoScreen(onSelectTab: (_) {}),
      providers: [
        ChangeNotifierProvider<TodoController>.value(value: parentBoard),
      ],
    );
    parentTodos
      ..emitTasks(const [])
      ..emitRoutines(const [])
      ..emitCompletions(const []);
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppCopy.todosAddTask));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Tidy your room');
    await tapInSheet(
      tester,
      find.descendant(
        of: find.byType(MemberPicker),
        matching: find.text('Kid Parker'),
      ),
    );
    await tapInSheet(tester, find.text(PointsCopy.starsCount(5)));
    await tapInSheet(tester, find.text(PointsCopy.choreNeedsApproval));
    await tapInSheet(tester, find.text(AppCopy.householdSave));
    final saved = parentTodos.savedTasks.single;
    expect((saved.points, saved.needsApproval), (5, true));

    // ---- the child's tablet: the chore, worth five, ticked ----
    // Made outside the test's fake clock, as `setUp` makes it in the kid
    // home's own tests: its listeners must hear what `runAsync` emits.
    final child = (await tester.runAsync(() async => KidHomeFixture()))!;
    addTearDown(child.close);
    Future<void> showKid() => pumpScreen(
      tester,
      const KidHomeScreen(),
      providers: [
        ChangeNotifierProvider<KidHomeController>.value(
          value: child.controller,
        ),
        ChangeNotifierProvider<KidPointsController>.value(value: child.stars),
      ],
    );
    final chore = Task(
      id: 'room',
      title: saved.title,
      dueDate: saved.dueDate,
      assigneeIds: saved.assigneeIds,
      createdBy: Fixtures.samMemberId,
      points: saved.points,
      needsApproval: saved.needsApproval,
    );
    await showKid();
    await tester.runAsync(() async {
      await child.arrive(tasks: [chore]);
      await child.starsArrive(
        rewards: [PointsFixtures.reward('ice-cream', 'Ice cream', 5)],
      );
    });
    await tester.pumpAndSettle();
    expect(find.text(PointsCopy.kidNote(const Earns(5))!), findsOneWidget);
    await tester.tap(find.text('Tidy your room'));
    await tester.pumpAndSettle();
    expect(child.todos.completed.single.taskId, 'room');

    // The trigger waits for a parent: the tile says so.
    final pending = PointsFixtures.claim('room', today, memberId: kid);
    await tester.runAsync(() async {
      child.todos.emitCompletions([KidHomeFixture.done('room')]);
      child.points.emitClaims([pending]);
      await pumpEventQueue();
    });
    await tester.pumpAndSettle();
    expect(
      find.text(PointsCopy.kidNote(const WaitingForGrownUp(5))!),
      findsOneWidget,
    );

    // ---- the parent's stars screen: it looks good ----
    final points = FakePointsRepository();
    final rewards = FakeRewardRepository();
    final directory = FakePointsDirectory();
    final stars = ChorePointsController(
      pointsRepository: points,
      rewardRepository: rewards,
      pointsDirectory: directory,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
    );
    addTearDown(() async {
      stars.dispose();
      await points.close();
      await rewards.close();
    });
    Future<void> showParent() => pumpScreen(
      tester,
      const ChorePointsScreen(),
      providers: [
        Provider<PointsRepository>.value(value: points),
        ChangeNotifierProvider<ChorePointsController>.value(value: stars),
      ],
    );
    await showParent();
    points
      ..emitPending([pending])
      ..emitBalances(const []);
    rewards
      ..emitWaiting(const [])
      ..emitRewards([PointsFixtures.reward('ice-cream', 'Ice cream', 5)]);
    await tester.pumpAndSettle();
    await tapShown(tester, find.text(PointsCopy.reviewApprove));
    expect(directory.reviews.single, (
      completionId: pending.id,
      decision: ChoreReview.approve,
    ));

    // ---- the child's tablet: the stars land, and a treat is asked for ----
    await showKid();
    await tester.runAsync(() async {
      child.points
        ..emitClaims([pending.copyWith(status: ClaimStatus.awarded)])
        ..emitBalance(PointsFixtures.balance(kid, 5));
      await pumpEventQueue();
    });
    await tester.pump();
    expect(find.text(PointsCopy.kidJustEarned(5)), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text(PointsCopy.kidNote(const Earned(5))!), findsOneWidget);

    await tapShown(tester, find.text(PointsCopy.kidGetIt));
    await tester.tap(find.text(PointsCopy.kidAskYes));
    await tester.pumpAndSettle();
    expect(child.rewards.requested.single.rewardId, 'ice-cream');

    // ---- the parent's stars screen: handed over ----
    final asked = PointsFixtures.request('rq1', memberId: kid, cost: 5);
    await showParent();
    points.emitPending(const []);
    rewards.emitWaiting([asked]);
    await tester.pumpAndSettle();
    await tapShown(tester, find.text(PointsCopy.settleGiven));
    expect(directory.settlements.single, (
      requestId: 'rq1',
      decision: RewardSettlement.fulfil,
    ));

    // ---- the child's tablet: it is theirs ----
    await showKid();
    await tester.runAsync(() async {
      child.points.emitBalance(PointsFixtures.balance(kid, 0));
      child.rewards.emitMine([asked.copyWith(status: RequestStatus.fulfilled)]);
      await pumpEventQueue();
    });
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(PointsCopy.kidRequestFulfilled),
      200,
    );
    expect(find.text(PointsCopy.kidRequestFulfilled), findsOneWidget);
  });
}
