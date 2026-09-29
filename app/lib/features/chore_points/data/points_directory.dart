/// What a parent decides about a chore that waited for them (todos ADR-0003).
enum ChoreReview { approve, sendBack }

/// What a parent decides about a reward a child asked for.
enum RewardSettlement { fulfil, decline }

/// The two parent decisions that move stars, as callables (todos ADR-0003).
///
/// They are Functions rather than Firestore writes because the decision and
/// the stars it moves happen in one transaction, and because a kid device can
/// call no callable at all — so a child cannot approve their own chore.
abstract interface class PointsDirectory {
  Future<void> reviewChore({
    required String householdId,
    required String completionId,
    required ChoreReview decision,
  });

  Future<void> settleReward({
    required String householdId,
    required String requestId,
    required RewardSettlement decision,
  });
}
