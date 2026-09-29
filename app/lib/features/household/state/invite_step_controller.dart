import 'package:flutter/foundation.dart';

import '../../../design/tokens/nest_member_palette.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../data/household_directory.dart';
import '../data/household_repository.dart';
import '../data/invite_sharer.dart';
import '../model/access_defaults.dart';
import '../model/guardian_consent.dart';
import '../model/member_role.dart';

/// Somebody invited from this screen: who, as what, and the code they join
/// with. Kept for as long as the screen is open, so a parent can share it
/// again — the code itself is never readable afterwards (household ADR-0002).
class SentInvite {
  const SentInvite({
    required this.memberId,
    required this.displayName,
    required this.role,
    required this.code,
  });

  final String memberId;
  final String displayName;
  final MemberRole role;
  final String code;
}

/// Inviting the people who share the house, as one step of setting it up
/// (household ADR-0003) — and the same flow from the people screen later.
///
/// Inviting is three things in order: a profile for them (with its role's
/// grant), a code for that profile, and the share sheet. Each can fail on its
/// own; a profile made without a code is still a profile the household can
/// invite from the people screen, so nothing is left unreachable.
final class InviteStepController extends ChangeNotifier
    with ActionFailureHolder {
  InviteStepController({
    required HouseholdRepository householdRepository,
    required HouseholdDirectory householdDirectory,
    required InviteSharer inviteSharer,
    required this.householdId,
    required this.householdName,
    required Iterable<MemberColor> coloursInUse,
    this.viewerMemberId,
  }) : _repository = householdRepository,
       _directory = householdDirectory,
       _sharer = inviteSharer,
       _coloursInUse = {...coloursInUse};

  final HouseholdRepository _repository;
  final HouseholdDirectory _directory;
  final InviteSharer _sharer;
  final String householdId;
  final String householdName;

  /// The inviting adult's own profile, who gives a kid's consent.
  final String? viewerMemberId;
  final Set<MemberColor> _coloursInUse;

  final _sent = <SentInvite>[];
  bool _isBusy = false;
  bool _shareUnavailable = false;

  List<SentInvite> get sent => List.unmodifiable(_sent);
  bool get isBusy => _isBusy;

  /// The last share sheet would not open; the screen says to copy instead.
  bool get shareUnavailable => _shareUnavailable;

  /// Makes the profile and its code, then opens the share sheet. Answers
  /// whether the invite exists — a dismissed sheet is still an invite.
  ///
  /// Inviting a kid records the consent the inviting adult gave (accounts
  /// ADR-0005); the rules refuse a kid profile without it.
  Future<bool> invite({
    required String displayName,
    required MemberRole role,
    bool guardianConsent = false,
  }) => _run(() async {
    final colour = _nextColour();
    final byMemberId = viewerMemberId;
    final memberId = await _repository.addMember(
      householdId: householdId,
      displayName: displayName,
      color: colour,
      role: role,
      access: AccessDefaults.forRole(role),
      guardianConsent:
          role == MemberRole.kid && guardianConsent && byMemberId != null
          ? GuardianConsent.givenBy(byMemberId)
          : null,
    );
    _coloursInUse.add(colour);
    final invite = await _directory.createInvite(
      householdId: householdId,
      memberId: memberId,
    );
    final sent = SentInvite(
      memberId: memberId,
      displayName: displayName,
      role: role,
      code: invite.code,
    );
    _sent.add(sent);
    notifyListeners();
    await _share(sent);
  });

  Future<void> shareAgain(SentInvite sent) => _share(sent);

  /// Closes the step, finished or skipped. The household listener sees the
  /// field go and the app moves on to the week.
  Future<bool> finish() => _run(() => _repository.finishSetupStep(householdId));

  Future<void> _share(SentInvite sent) async {
    final outcome = await _sharer.shareCode(
      householdName: householdName,
      code: sent.code,
    );
    _shareUnavailable = outcome == InviteShareOutcome.unavailable;
    notifyListeners();
  }

  /// A colour nobody in the household has yet, so a new face is told apart
  /// at a glance; the palette's first once all ten are taken.
  MemberColor _nextColour() => MemberColor.values.firstWhere(
    (colour) => !_coloursInUse.contains(colour),
    orElse: () => MemberColor.values.first,
  );

  Future<bool> _run(Future<void> Function() action) async {
    if (_isBusy) return false;
    _isBusy = true;
    clearFailureQuietly();
    notifyListeners();
    try {
      await action();
      return true;
    } on AppFailure catch (failure) {
      recordFailure(failure);
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
