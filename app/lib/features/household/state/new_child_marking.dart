import '../../family_profiles/data/child_profile_directory.dart';
import '../model/member_role.dart';

/// A profile made as a kid is a child — in lunches and Plan my week — from
/// the moment it exists, not from when somebody joins as them (household
/// ADR-0009).
final class NewChildMarking {
  NewChildMarking({
    required ChildProfileDirectory childProfileDirectory,
    required this.householdId,
  }) : _directory = childProfileDirectory;

  final ChildProfileDirectory _directory;
  final String householdId;

  Future<void> markIfKid(String memberId, MemberRole role) async {
    if (role != MemberRole.kid) return;
    await _directory.setIsChild(
      householdId: householdId,
      memberId: memberId,
      isChild: true,
    );
  }
}
