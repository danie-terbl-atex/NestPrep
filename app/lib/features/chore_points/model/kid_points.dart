import '../../../shared/time/calendar_date.dart';
import 'point_balance.dart';
import 'point_claim.dart';
import 'reward.dart';
import 'reward_request.dart';

/// A child's stars as their own device shows them (todos ADR-0003): the
/// balance, what each recent job's claim says, the shelf and what they have
/// asked for. Derived once per emission, never in a build method (`FE-12`).
final class KidPoints {
  KidPoints({
    required this.balance,
    required List<PointClaim> claims,
    required this.rewards,
    required this.requests,
    required this.today,
    required this.canSpend,
    this.celebration,
  }) : _claims = {for (final claim in claims) claim.id: claim};

  final PointBalance balance;
  final Map<String, PointClaim> _claims;

  /// The shelf, cheapest first.
  final List<Reward> rewards;

  /// Newest first.
  final List<RewardRequest> requests;
  final CalendarDate today;

  /// `own` or `edit` on to-dos: they may ask for a reward. `view` only looks.
  final bool canSpend;

  /// Stars that just landed, for the card to celebrate; null otherwise.
  final StarCelebration? celebration;

  int get stars => balance.balance;

  int get streak => balance.streakOn(today);

  /// The claim for one job, keyed like its completion.
  PointClaim? claimFor(String completionId) => _claims[completionId];

  bool canAfford(Reward reward) => stars >= reward.cost;

  /// How many more stars [reward] needs — zero when it is within reach.
  int starsToGo(Reward reward) => reward.cost > stars ? reward.cost - stars : 0;

  /// How far along the way to [reward], from 0 to 1.
  double progressTowards(Reward reward) =>
      stars <= 0 ? 0 : (stars / reward.cost).clamp(0, 1).toDouble();

  /// Asked for and not yet answered — the shelf shows these as "asked".
  bool isAskedFor(Reward reward) => requests.any(
    (request) =>
        request.rewardId == reward.id &&
        (request.isBeingCounted || request.status == RequestStatus.waiting),
  );

  KidPoints celebrating(StarCelebration? next) => KidPoints(
    balance: balance,
    claims: _claims.values.toList(),
    rewards: rewards,
    requests: requests,
    today: today,
    canSpend: canSpend,
    celebration: next,
  );
}

/// Stars that landed while the child was looking. [sequence] tells one
/// celebration from the next, so the same number twice still celebrates.
final class StarCelebration {
  const StarCelebration({required this.gained, required this.sequence});

  final int gained;
  final int sequence;
}
