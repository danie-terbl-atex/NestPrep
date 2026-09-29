import 'package:nestprep/features/chore_points/model/point_balance.dart';
import 'package:nestprep/features/chore_points/model/point_claim.dart';
import 'package:nestprep/features/chore_points/model/point_entry.dart';
import 'package:nestprep/features/chore_points/model/reward.dart';
import 'package:nestprep/features/chore_points/model/reward_request.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import 'model_fixtures.dart';

/// The stored models of a child's stars (todos ADR-0003), every field filled,
/// spread into `modelFixtures()` — beside it rather than inside it, so the
/// shared fixture file does not grow a feature's worth for each feature.
List<ModelFixture> chorePointsModelFixtures() {
  final at = fixtureInstant;
  final pointBalance = PointBalance(
    id: 'm2',
    balance: 12,
    earned: 20,
    spent: 8,
    streakDays: 3,
    bestStreak: 4,
    streakLastDay: CalendarDate(2026, 9, 29),
    updatedAt: at,
  );
  final pointClaim = PointClaim(
    id: 't1_2026-09-29',
    memberId: 'm2',
    taskId: 't1',
    occurrenceDate: CalendarDate(2026, 9, 29),
    title: 'Bins',
    points: 5,
    status: ClaimStatus.pending,
    round: 2,
    claimedAt: at,
  );
  final pointEntry = PointEntry(
    id: 'chore_t1_2026-09-29_1',
    memberId: 'm2',
    delta: 5,
    kind: EntryKind.chore,
    sourceId: 't1_2026-09-29',
    title: 'Bins',
    at: at,
  );
  final reward = Reward(
    id: 'rw1',
    title: 'Ice cream',
    cost: 20,
    icon: RewardIcon.iceCream,
    createdBy: 'm1',
    createdAt: at,
  );
  final rewardRequest = RewardRequest(
    id: 'rq1',
    rewardId: 'rw1',
    memberId: 'm2',
    requestedBy: 'm2',
    requestedAt: at,
  );

  return [
    ModelFixture(
      label: 'PointBalance',
      id: 'm2',
      value: pointBalance,
      toJson: pointBalance.toJson,
      fromJson: PointBalance.fromJson,
      keys: const {
        'balance',
        'earned',
        'spent',
        'streakDays',
        'bestStreak',
        'streakLastDay',
        'updatedAt',
      },
      note:
          'written only by Functions, beside the ledger line that moved it '
          '(todos ADR-0003); the app reads it and never writes it.',
    ),
    ModelFixture(
      label: 'PointClaim',
      id: 't1_2026-09-29',
      value: pointClaim,
      toJson: pointClaim.toJson,
      fromJson: PointClaim.fromJson,
      keys: const {
        'memberId',
        'taskId',
        'occurrenceDate',
        'title',
        'points',
        'status',
        'round',
        'claimedAt',
      },
      note: 'written only by awardChorePoints and reviewChore.',
    ),
    ModelFixture(
      label: 'PointEntry',
      id: 'chore_t1_2026-09-29_1',
      value: pointEntry,
      toJson: pointEntry.toJson,
      fromJson: PointEntry.fromJson,
      keys: const {'memberId', 'delta', 'kind', 'sourceId', 'title', 'at'},
      note: 'the append-only ledger; only Functions write it.',
    ),
    ModelFixture(
      label: 'Reward',
      id: 'rw1',
      value: reward,
      toJson: reward.toJson,
      fromJson: Reward.fromJson,
      keys: const {'title', 'cost', 'icon', 'createdBy', 'createdAt'},
    ),
    ModelFixture(
      label: 'RewardRequest',
      id: 'rq1',
      value: rewardRequest,
      toJson: rewardRequest.toJson,
      fromJson: RewardRequest.fromJson,
      keys: const {'rewardId', 'memberId', 'requestedBy', 'requestedAt'},
      note:
          'the four fields the rules take from a client; the status, the '
          'cost and a refusal are the trigger’s alone (todos ADR-0003).',
    ),
  ];
}
