import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../household/model/member.dart';
import '../data/points_directory.dart';
import '../data/points_repository.dart';
import '../data/reward_repository.dart';
import '../model/point_balance.dart';
import '../model/point_claim.dart';
import '../model/points_board.dart';
import '../model/reward.dart';
import '../model/reward_request.dart';

/// The parent's stars screen (todos ADR-0003): four live reads — what is
/// waiting, every balance, the shelf — joined into one [PointsBoard], and the
/// decisions a parent makes on them.
///
/// It decides nothing about stars. Approving and handing over are callables
/// that check the caller is family and move the stars themselves; this only
/// asks, and holds a refusal for the screen to put into words.
final class ChorePointsController extends ChangeNotifier
    with ActionFailureHolder {
  ChorePointsController({
    required PointsRepository pointsRepository,
    required RewardRepository rewardRepository,
    required PointsDirectory pointsDirectory,
    required this.householdId,
    required this.memberId,
    required this._members,
  }) : _points = pointsRepository,
       _rewards = rewardRepository,
       _directory = pointsDirectory {
    _subscribe();
  }

  final PointsRepository _points;
  final RewardRepository _rewards;
  final PointsDirectory _directory;
  final String householdId;

  /// The parent's own profile — who a reward is made by.
  final String memberId;

  List<Member> _members;
  final _subscriptions = <StreamSubscription<Object?>>[];
  final _busy = <String>{};

  List<PointClaim>? _claims;
  List<RewardRequest>? _requests;
  List<PointBalance>? _balances;
  List<Reward>? _shelf;

  AsyncState<PointsBoard> _board = const AsyncLoading();

  AsyncState<PointsBoard> get board => _board;

  /// Whether a decision on [id] (a claim or a request) is on its way, so its
  /// buttons cannot be pressed twice (`FE-10`).
  bool isBusy(String id) => _busy.contains(id);

  /// The household's people changed — a child added, a role moved.
  void followMembers(List<Member> members) {
    _members = members;
    _publish();
  }

  Future<void> retry() async {
    await _cancel();
    _claims = _requests = null;
    _balances = null;
    _shelf = null;
    _board = const AsyncLoading();
    notifyListeners();
    _subscribe();
  }

  Future<void> review(PointClaim claim, ChoreReview decision) => _decide(
    claim.id,
    () => _directory.reviewChore(
      householdId: householdId,
      completionId: claim.id,
      decision: decision,
    ),
  );

  Future<void> settle(RewardRequest request, RewardSettlement decision) =>
      _decide(
        request.id,
        () => _directory.settleReward(
          householdId: householdId,
          requestId: request.id,
          decision: decision,
        ),
      );

  Future<void> saveReward({
    String? rewardId,
    required String title,
    required int cost,
    required RewardIcon icon,
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty || cost < 1 || cost > Reward.maxCost) {
      return Future.value();
    }
    return runAction(
      () => _rewards.saveReward(
        householdId: householdId,
        rewardId: rewardId,
        title: trimmed,
        cost: cost,
        icon: icon,
        createdBy: memberId,
      ),
    );
  }

  Future<void> deleteReward(String rewardId) => runAction(
    () => _rewards.deleteReward(householdId: householdId, rewardId: rewardId),
  );

  /// A parent spends a child's stars for them — a child with no device of
  /// their own. The trigger hands it over at once, or refuses it.
  Future<void> spendFor(String kidMemberId, Reward reward) => runAction(
    () => _rewards.requestReward(
      householdId: householdId,
      rewardId: reward.id,
      memberId: kidMemberId,
      requestedBy: memberId,
    ),
  );

  Future<void> _decide(String id, Future<void> Function() call) async {
    if (!_busy.add(id)) return;
    notifyListeners();
    try {
      await runAction(call);
    } finally {
      _busy.remove(id);
      notifyListeners();
    }
  }

  void _subscribe() {
    _listen(_points.watchPendingClaims(householdId), (value) {
      _claims = value;
    });
    _listen(_rewards.watchWaitingRequests(householdId), (value) {
      _requests = value;
    });
    _listen(_points.watchBalances(householdId), (value) {
      _balances = value;
    });
    _listen(_rewards.watchRewards(householdId), (value) {
      _shelf = value;
    });
  }

  void _listen<T>(Stream<T> stream, void Function(T value) onValue) {
    _subscriptions.add(
      stream.listen(
        (value) {
          onValue(value);
          _publish();
        },
        onError: (Object error) {
          _board = AsyncFailure(
            error is AppFailure ? error : UnknownFailure(error),
          );
          notifyListeners();
        },
      ),
    );
  }

  void _publish() {
    final (claims, requests, balances, shelf) = (
      _claims,
      _requests,
      _balances,
      _shelf,
    );
    if (claims == null ||
        requests == null ||
        balances == null ||
        shelf == null) {
      return;
    }
    _board = AsyncData(
      PointsBoard(
        pendingClaims: claims,
        waitingRequests: requests,
        balances: balances,
        rewards: shelf,
        members: _members,
      ),
    );
    notifyListeners();
  }

  Future<void> _cancel() async {
    final open = [..._subscriptions];
    _subscriptions.clear();
    for (final subscription in open) {
      await subscription.cancel();
    }
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
