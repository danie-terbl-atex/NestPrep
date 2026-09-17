import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../design/tokens/nest_member_palette.dart';
import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/household.dart';
import '../model/member.dart';
import '../model/member_role.dart';
import 'household_repository.dart';

final class FirestoreHouseholdRepository implements HouseholdRepository {
  FirestoreHouseholdRepository(this._firestore);

  static const householdsPath = 'households';
  static const membersPath = 'members';

  final FirebaseFirestore _firestore;

  CollectionReference<Household> get _households => typedCollection(
    _firestore.collection(householdsPath),
    fromJson: Household.fromJson,
    toJson: (household) => household.toJson(),
  );

  CollectionReference<Member> _members(String householdId) => typedCollection(
    _firestore
        .collection(householdsPath)
        .doc(householdId)
        .collection(membersPath),
    fromJson: Member.fromJson,
    toJson: (member) => member.toJson(),
  );

  @override
  Stream<Household?> watchHousehold(String householdId) => _households
      .doc(householdId)
      .snapshots()
      .map((snapshot) => snapshot.data())
      .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<Member>> watchMembers(String householdId) =>
      _members(householdId)
          .orderBy('displayName')
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<void> addMember({
    required String householdId,
    required String displayName,
    required MemberColor color,
    required MemberRole role,
  }) async {
    final members = _members(householdId);
    final document = members.doc();
    await _guarded(
      () => document.set(
        Member(
          id: document.id,
          displayName: displayName,
          color: color,
          roleName: role.name,
        ),
      ),
    );
  }

  @override
  Future<void> updateMember({
    required String householdId,
    required String memberId,
    required String displayName,
    required MemberColor color,
    required MemberRole role,
  }) => _guarded(
    () => _members(householdId).doc(memberId).update({
      'displayName': displayName,
      'color': color.name,
      'role': role.name,
    }),
  );

  @override
  Future<void> updateHousehold({
    required String householdId,
    required String name,
    required String timeZone,
  }) => _guarded(
    () => _households.doc(householdId).update({
      'name': name,
      'timeZone': timeZone,
    }),
  );

  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
