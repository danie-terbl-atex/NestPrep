import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../design/tokens/nest_member_palette.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../data/household_directory.dart';
import '../data/household_repository.dart';
import '../model/access_defaults.dart';
import '../model/birthday.dart';
import '../model/guardian_consent.dart';
import '../model/household.dart';
import '../model/household_view.dart';
import '../model/member.dart';
import '../model/member_role.dart';

/// The household screen's controller: the household and its profiles, live, and
/// the admin actions the screen offers. Created at the route, so its listeners
/// end when the screen does (foundation ADR-0006).
final class HouseholdController extends ChangeNotifier
    with ActionFailureHolder {
  HouseholdController({
    required HouseholdRepository householdRepository,
    required HouseholdDirectory householdDirectory,
    required this.householdId,
    required this.viewerUid,
  }) : _repository = householdRepository,
       _directory = householdDirectory {
    _subscribe();
  }

  final HouseholdRepository _repository;
  final HouseholdDirectory _directory;
  final String householdId;
  final String viewerUid;

  StreamSubscription<Household?>? _householdSubscription;
  StreamSubscription<List<Member>>? _membersSubscription;

  Household? _household;
  List<Member>? _members;

  AsyncState<HouseholdView> _view = const AsyncLoading();
  bool _isBusy = false;
  InviteCode? _lastInvite;

  AsyncState<HouseholdView> get view => _view;
  bool get isBusy => _isBusy;

  /// The code the last `createInvite` produced, for the sheet to show.
  InviteCode? get lastInvite => _lastInvite;

  void dismissInvite() {
    if (_lastInvite == null) return;
    _lastInvite = null;
    notifyListeners();
  }

  Future<void> retry() async {
    await _cancel();
    _household = null;
    _members = null;
    _view = const AsyncLoading();
    notifyListeners();
    _subscribe();
  }

  /// A kid, helper or carer starts from its role's grant, which a parent
  /// then adjusts (household ADR-0003).
  ///
  /// A kid is made with the consent the adult adding them gave, which the
  /// rules require (accounts ADR-0005).
  Future<void> addMember({
    required String displayName,
    required MemberColor color,
    required MemberRole role,
    Birthday? birthday,
    bool guardianConsent = false,
  }) => _run(
    () => _repository.addMember(
      householdId: householdId,
      displayName: displayName,
      color: color,
      role: role,
      birthday: birthday,
      access: AccessDefaults.forRole(role),
      guardianConsent: _consentFor(role, given: guardianConsent),
    ),
  );

  Future<void> updateMember({
    required String memberId,
    required String displayName,
    required MemberColor color,
    required MemberRole role,
    Birthday? birthday,
    bool guardianConsent = false,
  }) async {
    final member = _members?.where((value) => value.id == memberId).firstOrNull;
    // A claimed member's role also lives in the household's uid→role map, so it
    // moves through the callable; everything else is a direct write the rules
    // allow (household ADR-0002).
    final roleMovedOnAClaimedMember =
        member != null && member.isClaimed && member.role != role;
    // A new role on a profile nobody holds starts from that role's grant, as
    // `setMemberRole` does for a claimed one (household ADR-0003).
    final roleMovedOnAnUnclaimedMember =
        member != null && !member.isClaimed && member.role != role;
    await _run(() async {
      await _repository.updateMember(
        householdId: householdId,
        memberId: memberId,
        displayName: displayName,
        color: color,
        role: roleMovedOnAClaimedMember ? member.role : role,
        birthday: birthday,
        access: roleMovedOnAnUnclaimedMember
            ? AccessDefaults.forRole(role)
            : null,
        // A profile becoming a kid carries the consent with it; one that has
        // it already keeps the one it has (accounts ADR-0005).
        guardianConsent: member?.hasGuardianConsent ?? false
            ? null
            : _consentFor(role, given: guardianConsent),
      );
      if (roleMovedOnAClaimedMember) {
        await _directory.setMemberRole(
          householdId: householdId,
          memberId: memberId,
          role: role,
        );
      }
    });
  }

  /// The consent to record for a profile given [role], or none: only a kid
  /// carries one, and only an adult with a profile here can give it.
  GuardianConsent? _consentFor(MemberRole role, {required bool given}) {
    final viewer = _members
        ?.where((member) => member.isClaimedBy(viewerUid))
        .firstOrNull;
    if (role != MemberRole.kid || !given || viewer == null) return null;
    return GuardianConsent.givenBy(viewer.id);
  }

  Future<void> removeMember(String memberId) => _run(
    () => _directory.removeMember(householdId: householdId, memberId: memberId),
  );

  Future<void> createInvite(String memberId) => _run(() async {
    _lastInvite = await _directory.createInvite(
      householdId: householdId,
      memberId: memberId,
    );
  });

  Future<void> renameHousehold({
    required String name,
    required String timeZone,
  }) => _run(
    () => _repository.updateHousehold(
      householdId: householdId,
      name: name,
      timeZone: timeZone,
    ),
  );

  /// Leaves the household. The account's own document changes, which the
  /// session is listening to, so the router moves the screen on its own.
  Future<bool> leaveHousehold() =>
      _run(() => _directory.leaveHousehold(householdId));

  /// Like `runAction`, with two things this screen needs and the others do
  /// not: a guard so a double tap cannot remove somebody twice, and an answer
  /// the caller can act on.
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

  void _subscribe() {
    _householdSubscription = _repository.watchHousehold(householdId).listen((
      household,
    ) {
      _household = household;
      _publish();
    }, onError: _onError);
    _membersSubscription = _repository.watchMembers(householdId).listen((
      members,
    ) {
      _members = members;
      _publish();
    }, onError: _onError);
  }

  void _publish() {
    final household = _household;
    final members = _members;
    if (members == null) return;
    if (household == null) {
      // The household is gone, or this account can no longer read it — which
      // is what being removed looks like from here.
      _view = const AsyncFailure(NotFoundFailure());
      notifyListeners();
      return;
    }
    _view = AsyncData(
      HouseholdView(
        household: household,
        members: members,
        viewerUid: viewerUid,
      ),
    );
    notifyListeners();
  }

  void _onError(Object error) {
    _view = AsyncFailure(error is AppFailure ? error : UnknownFailure(error));
    notifyListeners();
  }

  Future<void> _cancel() async {
    await _householdSubscription?.cancel();
    await _membersSubscription?.cancel();
    _householdSubscription = null;
    _membersSubscription = null;
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
