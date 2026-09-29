import '../../household/model/member.dart';
import '../../household/model/member_role.dart';
import 'point_balance.dart';
import 'point_claim.dart';
import 'reward.dart';
import 'reward_request.dart';

/// The parent's stars screen (todos ADR-0003): what is waiting for them, each
/// child's stars, and the shelf. Derived once per emission (`FE-12`).
final class PointsBoard {
  PointsBoard({
    required List<PointClaim> pendingClaims,
    required List<RewardRequest> waitingRequests,
    required List<PointBalance> balances,
    required this.rewards,
    required List<Member> members,
  }) : pendingClaims = [...pendingClaims]
         ..sort((a, b) => b.occurrenceDate.compareTo(a.occurrenceDate)),
       waitingRequests = [...waitingRequests]
         ..sort(
           (a, b) =>
               (a.requestedAt ?? _never).compareTo(b.requestedAt ?? _never),
         ),
       kids = [
         for (final member in members)
           if (member.role == MemberRole.kid) member,
       ],
       _balances = {for (final balance in balances) balance.id: balance};

  static final _never = DateTime.utc(1970);

  /// Newest chore first.
  final List<PointClaim> pendingClaims;

  /// Oldest request first — the child who has waited longest.
  final List<RewardRequest> waitingRequests;

  /// The household's kid profiles — who can earn.
  final List<Member> kids;

  /// Cheapest first.
  final List<Reward> rewards;

  final Map<String, PointBalance> _balances;

  PointBalance balanceOf(String memberId) =>
      _balances[memberId] ?? PointBalance.none(memberId);

  int get waitingCount => pendingClaims.length + waitingRequests.length;

  bool get hasNothingWaiting => waitingCount == 0;
}
