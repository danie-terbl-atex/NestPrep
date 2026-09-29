import 'dart:async';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../family_profiles/data/family_profile_repository.dart';
import '../../family_profiles/model/family_profile.dart';
import '../../family_profiles/model/member_health.dart';
import '../../family_profiles/model/school.dart';
import '../model/child_in_care.dart';

/// What family profiles holds about the children, read through its own
/// repository and its own grants — never copied into the hub (nanny-hub
/// ADR-0003). One home per fact: the lunch planner and the carer read the same
/// allergy from the same document.
///
/// A viewer the `familyProfiles` grant does not open never asks for the
/// profiles, and one the `medical` grant does not open never asks for a
/// child's medication: the rules would refuse it, and a refusal is not an
/// error to show (family-profiles ADR-0002).
final class CareListeners {
  CareListeners({
    required FamilyProfileRepository familyProfileRepository,
    required this.householdId,
    required this.onChange,
  }) : _repository = familyProfileRepository;

  final FamilyProfileRepository _repository;
  final String householdId;
  final void Function() onChange;

  StreamSubscription<List<FamilyProfile>>? _profiles;
  StreamSubscription<List<School>>? _schools;
  List<FamilyProfile>? _profileList;
  List<School>? _schoolList;
  AsyncState<FamilyFood>? _food;
  final _health = <String, AsyncState<MemberHealth>>{};
  final _healthSubscriptions = <String, StreamSubscription<MemberHealth>>{};

  /// Null when the viewer may not read the profiles at all.
  AsyncState<FamilyFood>? get food => _food;

  /// Null when the viewer may not read this child's medication.
  AsyncState<MemberHealth>? healthOf(String memberId) => _health[memberId];

  /// Opens the profile reads, when [mayReadProfiles].
  void startFood({required bool mayReadProfiles}) {
    if (!mayReadProfiles) return;
    _food = const AsyncLoading();
    _profiles = _repository.watchProfiles(householdId).listen((profiles) {
      _profileList = profiles;
      _publishFood();
    }, onError: _failFood);
    _schools = _repository.watchSchools(householdId).listen((schools) {
      _schoolList = schools;
      _publishFood();
    }, onError: _failFood);
  }

  void _publishFood() {
    final profiles = _profileList;
    final schools = _schoolList;
    if (profiles == null || schools == null) return;
    _food = AsyncData((profiles: profiles, schools: schools));
    onChange();
  }

  void _failFood(Object error) {
    _food = AsyncFailure(error is AppFailure ? error : UnknownFailure(error));
    onChange();
  }

  /// Keeps one medication read open for each child in [memberIds] whose
  /// medication the viewer may see, and closes the rest. The new reads open
  /// before anything is awaited, so two calls in a row never open one twice.
  Future<void> followChildren(Iterable<String> memberIds) async {
    final wanted = memberIds.toSet();
    final open = _healthSubscriptions.keys.toSet();
    for (final memberId in wanted.difference(open)) {
      _health[memberId] = const AsyncLoading();
      _healthSubscriptions[memberId] = _repository
          .watchHealth(householdId: householdId, memberId: memberId)
          .listen(
            (health) {
              _health[memberId] = AsyncData(health);
              onChange();
            },
            onError: (Object error) {
              _health[memberId] = AsyncFailure(
                error is AppFailure ? error : UnknownFailure(error),
              );
              onChange();
            },
          );
    }
    for (final gone in open.difference(wanted)) {
      _health.remove(gone);
      await _healthSubscriptions.remove(gone)?.cancel();
    }
  }

  Future<void> stop() async {
    await _profiles?.cancel();
    await _schools?.cancel();
    _profiles = null;
    _schools = null;
    _profileList = null;
    _schoolList = null;
    _food = null;
    for (final subscription in _healthSubscriptions.values) {
      await subscription.cancel();
    }
    _healthSubscriptions.clear();
    _health.clear();
  }
}
