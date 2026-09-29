import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/chore_points/model/kid_chore_note.dart';
import 'package:nestprep/features/chore_points/model/kid_points.dart';
import 'package:nestprep/features/chore_points/model/point_balance.dart';
import 'package:nestprep/features/chore_points/model/point_claim.dart';
import 'package:nestprep/features/chore_points/model/points_board.dart';
import 'package:nestprep/features/chore_points/model/reward_request.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/model/task_completion.dart';
import 'package:nestprep/features/todos/model/task_occurrence.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/fake_chore_points.dart';
import '../../../support/household_fixtures.dart';

/// The pure parts of stars (todos ADR-0003): what a job's tile says, how a
/// streak lives and dies, what a child can reach, and the order a parent sees
/// things in.
void main() {
  final today = CalendarDate(2026, 9, 29);
  const kid = Fixtures.kidMemberId;

  TaskOccurrence chore({int points = 5, bool done = false}) => TaskOccurrence(
    task: Task(
      id: 'room',
      title: 'Tidy your room',
      dueDate: today,
      assigneeIds: const [kid],
      createdBy: Fixtures.samMemberId,
      points: points,
    ),
    date: today,
    assigneeIds: const [kid],
    completion: done
        ? TaskCompletion(
            id: 'room_2026-09-29',
            taskId: 'room',
            occurrenceDate: today,
            completedBy: kid,
            completedFor: kid,
          )
        : null,
  );

  PointClaim claim(ClaimStatus status, {int points = 5}) =>
      PointsFixtures.claim(
        'room',
        today,
        memberId: kid,
        status: status,
        points: points,
      );

  group('what a job’s tile says about its stars', () {
    test('nothing for a job worth nothing', () {
      expect(KidChoreNote.of(chore(points: 0), null), isA<NoStars>());
    });

    test('what it is worth, before it is done', () {
      final note = KidChoreNote.of(chore(), null);
      expect(note, isA<Earns>().having((n) => n.points, 'points', 5));
    });

    test('“have another go” when a grown-up sent it back', () {
      expect(
        KidChoreNote.of(chore(), claim(ClaimStatus.sentBack)),
        isA<TryAgain>(),
      );
    });

    test('counting while the server has not yet written a claim', () {
      expect(KidChoreNote.of(chore(done: true), null), isA<Counting>());
      // A claim from an earlier tick that was unticked is not this tick's.
      expect(
        KidChoreNote.of(chore(done: true), claim(ClaimStatus.withdrawn)),
        isA<Counting>(),
      );
    });

    test('waiting, then earned — at the stars the claim was made with', () {
      expect(
        KidChoreNote.of(chore(done: true), claim(ClaimStatus.pending)),
        isA<WaitingForGrownUp>(),
      );
      final earned = KidChoreNote.of(
        chore(points: 20, done: true),
        claim(ClaimStatus.awarded),
      );
      expect(earned, isA<Earned>().having((n) => n.points, 'points', 5));
    });
  });

  group('a streak', () {
    PointBalance lastEarned(CalendarDate day) =>
        PointsFixtures.balance(kid, 10, streak: 4, lastDay: day);

    test('is alive today and yesterday, and gone after a missed day', () {
      expect(lastEarned(today).streakOn(today), 4);
      expect(lastEarned(today.addDays(-1)).streakOn(today), 4);
      expect(lastEarned(today.addDays(-2)).streakOn(today), 0);
    });

    test('is nothing before the first star', () {
      expect(PointBalance.none(kid).streakOn(today), 0);
    });
  });

  group('what a child can reach', () {
    final iceCream = PointsFixtures.reward('ice-cream', 'Ice cream', 10);

    KidPoints withStars(int stars, {List<RewardRequest> requests = const []}) =>
        KidPoints(
          balance: PointsFixtures.balance(kid, stars),
          claims: const [],
          rewards: [iceCream],
          requests: requests,
          today: today,
          canSpend: true,
        );

    test('affords it at exactly the cost', () {
      expect(withStars(10).canAfford(iceCream), isTrue);
      expect(withStars(9).canAfford(iceCream), isFalse);
      expect(withStars(9).starsToGo(iceCream), 1);
      expect(withStars(30).starsToGo(iceCream), 0);
    });

    test('shows progress from nothing to full, never past it', () {
      expect(withStars(0).progressTowards(iceCream), 0);
      expect(withStars(5).progressTowards(iceCream), 0.5);
      expect(withStars(50).progressTowards(iceCream), 1);
      expect(withStars(-4).progressTowards(iceCream), 0);
    });

    test('treats a request still being counted or waiting as asked', () {
      final waiting = PointsFixtures.request('r', memberId: kid);
      final counting = PointsFixtures.request('r', memberId: kid, status: null);
      final given = PointsFixtures.request(
        'r',
        memberId: kid,
        status: RequestStatus.fulfilled,
      );
      expect(withStars(10, requests: [waiting]).isAskedFor(iceCream), isTrue);
      expect(withStars(10, requests: [counting]).isAskedFor(iceCream), isTrue);
      expect(withStars(10, requests: [given]).isAskedFor(iceCream), isFalse);
    });
  });

  group('the parent’s board', () {
    test('newest chore first, longest-waiting request first, kids only', () {
      final board = PointsBoard(
        pendingClaims: [
          PointsFixtures.claim('a', today.addDays(-2), memberId: kid),
          PointsFixtures.claim('b', today, memberId: kid),
        ],
        waitingRequests: [
          PointsFixtures.request(
            'late',
            memberId: kid,
          ).copyWith(requestedAt: DateTime.utc(2026, 9, 29, 12)),
          PointsFixtures.request(
            'early',
            memberId: kid,
          ).copyWith(requestedAt: DateTime.utc(2026, 9, 29, 6)),
        ],
        balances: [PointsFixtures.balance(kid, 7)],
        rewards: const [],
        members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
      );
      expect(board.pendingClaims.map((c) => c.taskId), ['b', 'a']);
      expect(board.waitingRequests.map((r) => r.id), ['early', 'late']);
      expect(board.kids.map((k) => k.id), [kid]);
      expect(board.balanceOf(kid).balance, 7);
      expect(board.balanceOf('m-nobody').balance, 0);
      expect(board.waitingCount, 4);
    });
  });
}
