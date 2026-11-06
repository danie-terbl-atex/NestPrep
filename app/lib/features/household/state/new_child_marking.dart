import '../../../shared/failure/app_failure.dart';
import '../../family_profiles/data/child_profile_directory.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../model/member_role.dart';

/// A profile made as a kid is a child — in lunches, Plan my week and the free
/// tier's count — from the moment it exists, not from when somebody joins as
/// them (household ADR-0009). A second child on a free household is refused
/// by the server; that child waits here until the paywall answers.
final class NewChildMarking {
  NewChildMarking({
    required ChildProfileDirectory childProfileDirectory,
    required this.householdId,
  }) : _directory = childProfileDirectory;

  final ChildProfileDirectory _directory;
  final String householdId;
  (String, PremiumFeature)? _awaitingPremium;

  PremiumFeature? get awaitingPremium => _awaitingPremium?.$2;

  Future<void> markIfKid(String memberId, MemberRole role) async {
    if (role != MemberRole.kid) return;
    try {
      await _mark(memberId);
    } on PremiumRequiredFailure catch (failure) {
      _awaitingPremium = (memberId, failure.feature);
    }
  }

  Future<void> markAfterUpgrade() async {
    final memberId = _awaitingPremium?.$1;
    _awaitingPremium = null;
    if (memberId != null) await _mark(memberId);
  }

  void forget() => _awaitingPremium = null;

  Future<void> _mark(String memberId) => _directory.setIsChild(
    householdId: householdId,
    memberId: memberId,
    isChild: true,
  );
}

/// A controller that makes profiles, and so may hold a new child waiting on
/// premium for the screen to answer with the paywall.
abstract interface class MakesChildren {
  PremiumFeature? get childAwaitingPremium;
  Future<void> markChildAfterUpgrade();
  void forgetChildAwaitingPremium();
}
