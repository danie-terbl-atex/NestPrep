import 'dart:async';

import 'package:nestprep/features/chore_points/data/points_directory.dart';
import 'package:nestprep/features/chore_points/data/points_repository.dart';
import 'package:nestprep/features/chore_points/data/reward_repository.dart';
import 'package:nestprep/features/chore_points/model/point_balance.dart';
import 'package:nestprep/features/chore_points/model/point_claim.dart';
import 'package:nestprep/features/chore_points/model/point_entry.dart';
import 'package:nestprep/features/chore_points/model/reward.dart';
import 'package:nestprep/features/chore_points/model/reward_request.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// A child's stars, driven by hand — the server's side of todos ADR-0003 is
/// whatever the test emits.
final class FakePointsRepository implements PointsRepository {
  final _balances = StreamController<List<PointBalance>>.broadcast();
  final _balance = StreamController<PointBalance>.broadcast();
  final _pending = StreamController<List<PointClaim>>.broadcast();
  final _claims = StreamController<List<PointClaim>>.broadcast();
  final _entries = StreamController<List<PointEntry>>.broadcast();

  CalendarDate? claimsFrom;
  String? balanceFor;

  void emitBalances(List<PointBalance> value) => _balances.add(value);
  void emitBalance(PointBalance value) => _balance.add(value);
  void emitPending(List<PointClaim> value) => _pending.add(value);
  void emitClaims(List<PointClaim> value) => _claims.add(value);
  void emitEntries(List<PointEntry> value) => _entries.add(value);
  void failBalanceWith(Object error) => _balance.addError(error);
  void failPendingWith(Object error) => _pending.addError(error);

  Future<void> close() async {
    await _balances.close();
    await _balance.close();
    await _pending.close();
    await _claims.close();
    await _entries.close();
  }

  @override
  Stream<List<PointBalance>> watchBalances(String householdId) =>
      _balances.stream;

  @override
  Stream<PointBalance> watchBalance(String householdId, String memberId) {
    balanceFor = memberId;
    return _balance.stream;
  }

  @override
  Stream<List<PointClaim>> watchPendingClaims(String householdId) =>
      _pending.stream;

  @override
  Stream<List<PointClaim>> watchClaimsFor(
    String householdId,
    String memberId, {
    required CalendarDate from,
  }) {
    claimsFrom = from;
    return _claims.stream;
  }

  @override
  Stream<List<PointEntry>> watchEntriesFor(
    String householdId,
    String memberId,
  ) => _entries.stream;
}

final class FakeRewardRepository implements RewardRepository {
  final _rewards = StreamController<List<Reward>>.broadcast();
  final _waiting = StreamController<List<RewardRequest>>.broadcast();
  final _mine = StreamController<List<RewardRequest>>.broadcast();

  AppFailure? failWritesWith;

  final saved =
      <({String? rewardId, String title, int cost, RewardIcon icon})>[];
  final deleted = <String>[];
  final requested =
      <({String rewardId, String memberId, String requestedBy})>[];

  void emitRewards(List<Reward> value) => _rewards.add(value);
  void emitWaiting(List<RewardRequest> value) => _waiting.add(value);
  void emitMine(List<RewardRequest> value) => _mine.add(value);

  Future<void> close() async {
    await _rewards.close();
    await _waiting.close();
    await _mine.close();
  }

  @override
  Stream<List<Reward>> watchRewards(String householdId) => _rewards.stream;

  @override
  Stream<List<RewardRequest>> watchWaitingRequests(String householdId) =>
      _waiting.stream;

  @override
  Stream<List<RewardRequest>> watchRequestsFor(
    String householdId,
    String memberId,
  ) => _mine.stream;

  @override
  Future<void> saveReward({
    required String householdId,
    String? rewardId,
    required String title,
    required int cost,
    required RewardIcon icon,
    required String createdBy,
  }) async {
    _refuseIfAsked();
    saved.add((rewardId: rewardId, title: title, cost: cost, icon: icon));
  }

  @override
  Future<void> deleteReward({
    required String householdId,
    required String rewardId,
  }) async {
    _refuseIfAsked();
    deleted.add(rewardId);
  }

  @override
  Future<void> requestReward({
    required String householdId,
    required String rewardId,
    required String memberId,
    required String requestedBy,
  }) async {
    _refuseIfAsked();
    requested.add((
      rewardId: rewardId,
      memberId: memberId,
      requestedBy: requestedBy,
    ));
  }

  void _refuseIfAsked() {
    final failure = failWritesWith;
    if (failure != null) throw failure;
  }
}

final class FakePointsDirectory implements PointsDirectory {
  AppFailure? failWith;

  /// Completes each call when the test says so, to see the busy state.
  Completer<void>? hold;

  final reviews = <({String completionId, ChoreReview decision})>[];
  final settlements = <({String requestId, RewardSettlement decision})>[];

  @override
  Future<void> reviewChore({
    required String householdId,
    required String completionId,
    required ChoreReview decision,
  }) async {
    reviews.add((completionId: completionId, decision: decision));
    await hold?.future;
    final failure = failWith;
    if (failure != null) throw failure;
  }

  @override
  Future<void> settleReward({
    required String householdId,
    required String requestId,
    required RewardSettlement decision,
  }) async {
    settlements.add((requestId: requestId, decision: decision));
    await hold?.future;
    final failure = failWith;
    if (failure != null) throw failure;
  }
}

/// Stars, claims and rewards shaped the way the server writes them.
abstract final class PointsFixtures {
  static PointBalance balance(
    String memberId,
    int stars, {
    int streak = 0,
    CalendarDate? lastDay,
  }) => PointBalance(
    id: memberId,
    balance: stars,
    earned: stars,
    streakDays: streak,
    bestStreak: streak,
    streakLastDay: lastDay,
  );

  static PointClaim claim(
    String taskId,
    CalendarDate date, {
    required String memberId,
    ClaimStatus status = ClaimStatus.pending,
    int points = 5,
    String title = 'Tidy your room',
  }) => PointClaim(
    id: '${taskId}_${date.iso}',
    memberId: memberId,
    taskId: taskId,
    occurrenceDate: date,
    title: title,
    points: points,
    status: status,
  );

  static Reward reward(
    String id,
    String title,
    int cost, {
    RewardIcon icon = RewardIcon.iceCream,
  }) =>
      Reward(id: id, title: title, cost: cost, icon: icon, createdBy: 'm-sam');

  static RewardRequest request(
    String id, {
    required String memberId,
    String rewardId = 'ice-cream',
    RequestStatus? status = RequestStatus.waiting,
    String title = 'Ice cream',
    int cost = 10,
    RequestRefusal? refusal,
  }) => RewardRequest(
    id: id,
    rewardId: rewardId,
    memberId: memberId,
    requestedBy: memberId,
    requestedAt: DateTime.utc(2026, 9, 29, 8),
    status: status,
    title: title,
    cost: cost,
    icon: RewardIcon.iceCream,
    refusal: refusal,
  );
}
