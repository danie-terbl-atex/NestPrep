import '../model/reward.dart';
import '../model/reward_request.dart';

/// The reward shelf and the requests against it (todos ADR-0003).
///
/// Family writes the shelf; a child (or a parent for a child) writes a
/// request. What a request costs and whether it is met is the trigger's to
/// decide — the app only asks.
abstract interface class RewardRepository {
  /// The shelf, cheapest first.
  Stream<List<Reward>> watchRewards(String householdId);

  /// Requests waiting for a parent to hand the reward over.
  Stream<List<RewardRequest>> watchWaitingRequests(String householdId);

  /// One child's latest requests, newest first.
  Stream<List<RewardRequest>> watchRequestsFor(
    String householdId,
    String memberId,
  );

  Future<void> saveReward({
    required String householdId,
    String? rewardId,
    required String title,
    required int cost,
    required RewardIcon icon,
    required String createdBy,
  });

  Future<void> deleteReward({
    required String householdId,
    required String rewardId,
  });

  /// Asks for [rewardId] for [memberId]. The stars come off (or the request is
  /// refused) a moment later, on the server.
  Future<void> requestReward({
    required String householdId,
    required String rewardId,
    required String memberId,
    required String requestedBy,
  });

  static const shelfLimit = 100;
  static const requestLimit = 20;
}
