import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../design/tokens/nest_member_palette.dart';
import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/birthday.dart';
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
  Future<List<Household>> readHouseholds(List<String> householdIds) async {
    try {
      final documents = await Future.wait([
        for (final id in householdIds) _households.doc(id).get(),
      ]);
      return [for (final document in documents) ?document.data()];
    } on Object catch (error) {
      throw failureFromFirebase(error);
    }
  }

  @override
  Stream<List<Member>> watchMembers(String householdId) =>
      _members(householdId)
          .orderBy('displayName')
          .limit(HouseholdRepository.memberLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<void> addMember({
    required String householdId,
    required String displayName,
    required MemberColor color,
    required MemberRole role,
    Birthday? birthday,
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
          birthday: birthday,
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
    Birthday? birthday,
  }) => _guarded(
    // Hand-built because an update names the fields it moves, so the birthday
    // goes in as the string it is stored as — Firestore never calls `toJson`
    // on a model it is handed.
    () => _members(householdId).doc(memberId).update({
      'displayName': displayName,
      'color': color.name,
      'role': role.name,
      'birthday': birthday?.iso,
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
