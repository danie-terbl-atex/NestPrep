import 'dart:async';

import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/household/data/household_directory.dart';
import 'package:nestprep/features/household/data/household_repository.dart';
import 'package:nestprep/features/household/model/birthday.dart';
import 'package:nestprep/features/household/model/household.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/household/model/member_role.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// The household document and its profiles, driven by hand. Two live reads, so
/// a test can make one arrive before the other and see what the controller does
/// while it only has half of what it needs (foundation ADR-0006).
final class FakeHouseholdRepository implements HouseholdRepository {
  final _households = StreamController<Household?>.broadcast();
  final _members = StreamController<List<Member>>.broadcast();

  /// Set to make the next write fail the way a rules denial does.
  AppFailure? failWritesWith;

  final added =
      <
        ({
          String displayName,
          MemberColor color,
          MemberRole role,
          Birthday? birthday,
        })
      >[];
  final updated =
      <
        ({
          String memberId,
          String displayName,
          MemberRole role,
          Birthday? birthday,
        })
      >[];
  final renamed = <({String name, String timeZone})>[];

  void emitHousehold(Household? household) => _households.add(household);
  void emitMembers(List<Member> members) => _members.add(members);
  void failHouseholdWith(Object error) => _households.addError(error);

  Future<void> close() async {
    await _households.close();
    await _members.close();
  }

  @override
  Stream<Household?> watchHousehold(String householdId) => _households.stream;

  /// What `readHouseholds` answers with, by id.
  final storedHouseholds = <String, Household>{};

  @override
  Future<List<Household>> readHouseholds(List<String> householdIds) async {
    _refuseIfAsked();
    return [for (final id in householdIds) ?storedHouseholds[id]];
  }

  @override
  Stream<List<Member>> watchMembers(String householdId) => _members.stream;

  @override
  Future<void> addMember({
    required String householdId,
    required String displayName,
    required MemberColor color,
    required MemberRole role,
    Birthday? birthday,
  }) async {
    _refuseIfAsked();
    added.add((
      displayName: displayName,
      color: color,
      role: role,
      birthday: birthday,
    ));
  }

  @override
  Future<void> updateMember({
    required String householdId,
    required String memberId,
    required String displayName,
    required MemberColor color,
    required MemberRole role,
    Birthday? birthday,
  }) async {
    _refuseIfAsked();
    updated.add((
      memberId: memberId,
      displayName: displayName,
      role: role,
      birthday: birthday,
    ));
  }

  @override
  Future<void> updateHousehold({
    required String householdId,
    required String name,
    required String timeZone,
  }) async {
    _refuseIfAsked();
    renamed.add((name: name, timeZone: timeZone));
  }

  void _refuseIfAsked() {
    final failure = failWritesWith;
    if (failure != null) throw failure;
  }
}

/// The six callables, without a network. Everything that changes who is in a
/// household goes through here (household ADR-0002), so a test can see which
/// path a change actually took.
final class FakeHouseholdDirectory implements HouseholdDirectory {
  AppFailure? failWith;

  /// Blocks the next call until [release] is called, so a test can look at the
  /// controller while an action is still in flight.
  Completer<void>? gate;

  final created = <({String name, String timeZone, String adminDisplayName})>[];
  final invitesMade = <({String householdId, String memberId})>[];
  final redeemed = <String>[];
  final left = <String>[];
  final removed = <({String householdId, String memberId})>[];
  final rolesSet = <({String memberId, MemberRole role})>[];

  void release() {
    gate?.complete();
    gate = null;
  }

  @override
  Future<String> createHousehold({
    required String name,
    required String timeZone,
    required String adminDisplayName,
    required String adminColorName,
  }) async {
    await _checkpoint();
    created.add((
      name: name,
      timeZone: timeZone,
      adminDisplayName: adminDisplayName,
    ));
    return 'h-new';
  }

  @override
  Future<InviteCode> createInvite({
    required String householdId,
    required String memberId,
  }) async {
    await _checkpoint();
    invitesMade.add((householdId: householdId, memberId: memberId));
    return InviteCode(code: 'ABCD2345', expiresAt: DateTime.utc(2026, 9, 25));
  }

  @override
  Future<String> redeemInvite(String code) async {
    await _checkpoint();
    redeemed.add(code);
    return 'h-joined';
  }

  @override
  Future<void> leaveHousehold(String householdId) async {
    await _checkpoint();
    left.add(householdId);
  }

  @override
  Future<void> removeMember({
    required String householdId,
    required String memberId,
  }) async {
    await _checkpoint();
    removed.add((householdId: householdId, memberId: memberId));
  }

  @override
  Future<void> setMemberRole({
    required String householdId,
    required String memberId,
    required MemberRole role,
  }) async {
    await _checkpoint();
    rolesSet.add((memberId: memberId, role: role));
  }

  Future<void> _checkpoint() async {
    final waiting = gate;
    if (waiting != null) await waiting.future;
    final failure = failWith;
    if (failure != null) throw failure;
  }
}
