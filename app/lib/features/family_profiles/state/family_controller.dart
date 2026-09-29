import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../household/model/household_view.dart';
import '../../household/model/member.dart';
import '../data/child_profile_directory.dart';
import '../data/family_profile_repository.dart';
import '../model/family_access.dart';
import '../model/family_profile.dart';
import '../model/family_roster.dart';
import '../model/school.dart';
import 'family_edits.dart';

/// The family screens' controller: the household's members (read once by the
/// shell and handed in) and two live reads of this feature's own — profiles
/// and schools — become one `FamilyRoster`, so a screen has one loading state
/// (foundation ADR-0006).
///
/// It lives on the shell route above the family list and a person's profile,
/// so walking into a profile and back out does not reopen the listeners — the
/// documents feature's reasoning. Medication is not here: it is read per
/// person by `MemberHealthController`, because the rules let fewer people see
/// it (family-profiles ADR-0001).
final class FamilyController extends ChangeNotifier with ActionFailureHolder {
  FamilyController({
    required FamilyProfileRepository familyProfileRepository,
    required ChildProfileDirectory childProfileDirectory,
    required this.householdId,
    required HouseholdView household,
  }) : _repository = familyProfileRepository,
       _children = childProfileDirectory,
       _members = household.members,
       _access = FamilyAccess.of(household) {
    _start();
  }

  final FamilyProfileRepository _repository;
  final ChildProfileDirectory _children;
  final String householdId;

  List<Member> _members;
  FamilyAccess _access;

  StreamSubscription<List<FamilyProfile>>? _profileSubscription;
  StreamSubscription<List<School>>? _schoolSubscription;
  List<FamilyProfile>? _profiles;
  List<School>? _schools;
  AsyncState<FamilyRoster> _roster = const AsyncLoading();

  AsyncState<FamilyRoster> get roster => _roster;

  /// What the viewer may see and change — the rules' mirror (`FE-04`).
  FamilyAccess get access => _access;

  /// The edits a screen can make, one method per section. Kept apart so this
  /// file stays about reading (`ENG-05`).
  late final FamilyEdits edit = FamilyEdits(
    familyProfileRepository: _repository,
    childProfileDirectory: _children,
    householdId: householdId,
    runAction: runAction,
  );

  /// The household's members or the viewer's role changed — a rename, a new
  /// child, a promotion. The shell reads the members; this only follows them.
  void followHousehold(HouseholdView household) {
    final access = FamilyAccess.of(household);
    if (listEquals(_members, household.members) && access == _access) return;
    final scopeMoved = _profileScope(access) != _profileScope(_access);
    _members = household.members;
    _access = access;
    if (scopeMoved) {
      unawaited(retry());
      return;
    }
    _publish();
  }

  /// Which profiles the viewer may read: null for all of them, else their own
  /// (household ADR-0003) — asked for exactly, because a rule is not a filter.
  static String? _profileScope(FamilyAccess access) =>
      access.seesEveryProfile ? null : access.ownMemberId;

  Future<void> retry() async {
    await _cancel();
    _profiles = null;
    _schools = null;
    _roster = const AsyncLoading();
    notifyListeners();
    _start();
  }

  void _start() {
    _profileSubscription = _repository
        .watchProfiles(householdId, onlyMemberId: _profileScope(_access))
        .listen((profiles) {
          _profiles = profiles;
          _publish();
        }, onError: _onError);
    _schoolSubscription = _repository.watchSchools(householdId).listen((
      schools,
    ) {
      _schools = schools;
      _publish();
    }, onError: _onError);
  }

  /// Nothing is shown until both reads have answered, so a profile never
  /// flashes up without the school rule it is subject to.
  void _publish() {
    final profiles = _profiles;
    final schools = _schools;
    if (profiles == null || schools == null) return;
    _roster = AsyncData(
      FamilyRoster(
        members: [
          for (final member in _members)
            if (_access.canSeeProfile(member.id)) member,
        ],
        profiles: profiles,
        schools: schools,
      ),
    );
    notifyListeners();
  }

  void _onError(Object error) {
    _roster = AsyncFailure(error is AppFailure ? error : UnknownFailure(error));
    notifyListeners();
  }

  Future<void> _cancel() async {
    await _profileSubscription?.cancel();
    await _schoolSubscription?.cancel();
    _profileSubscription = null;
    _schoolSubscription = null;
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
