import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../design/tokens/nest_member_palette.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../data/household_directory.dart';
import '../data/household_repository.dart';
import '../model/household.dart';
import '../model/household_view.dart';
import '../model/member.dart';
import '../model/member_role.dart';

/// The household screen's controller: the household and its profiles, live, and
/// the admin actions the screen offers. Created at the route, so its listeners
/// end when the screen does (foundation ADR-0006).
final class HouseholdController extends ChangeNotifier {
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
  AppFailure? _actionFailure;
  InviteCode? _lastInvite;

  AsyncState<HouseholdView> get view => _view;
  bool get isBusy => _isBusy;
  AppFailure? get actionFailure => _actionFailure;

  /// The code the last `createInvite` produced, for the sheet to show.
  InviteCode? get lastInvite => _lastInvite;

  void dismissActionFailure() {
    if (_actionFailure == null) return;
    _actionFailure = null;
    notifyListeners();
  }

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

  Future<void> addMember({
    required String displayName,
    required MemberColor color,
    required MemberRole role,
  }) => _run(
    () => _repository.addMember(
      householdId: householdId,
      displayName: displayName,
      color: color,
      role: role,
    ),
  );

  Future<void> updateMember({
    required String memberId,
    required String displayName,
    required MemberColor color,
    required MemberRole role,
  }) async {
    final member = _members?.where((value) => value.id == memberId).firstOrNull;
    // A claimed member's role also lives in the household's uid→role map, so it
    // moves through the callable; everything else is a direct write the rules
    // allow (household ADR-0002).
    final roleMovedOnAClaimedMember =
        member != null && member.isClaimed && member.role != role;
    await _run(() async {
      await _repository.updateMember(
        householdId: householdId,
        memberId: memberId,
        displayName: displayName,
        color: color,
        role: roleMovedOnAClaimedMember ? member.role : role,
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

  Future<bool> _run(Future<void> Function() action) async {
    if (_isBusy) return false;
    _isBusy = true;
    _actionFailure = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on AppFailure catch (failure) {
      _actionFailure = failure;
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
