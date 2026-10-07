import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/allergy.dart';
import '../model/allergy_draft.dart';
import '../model/dietary_flag.dart';
import '../model/dietary_flags_converter.dart';
import '../model/family_profile.dart';
import '../model/medication.dart';
import '../model/member_health.dart';
import '../model/school.dart';
import 'allergy_write.dart';
import 'family_profile_repository.dart';

final class FirestoreFamilyProfileRepository
    implements FamilyProfileRepository {
  FirestoreFamilyProfileRepository(this._firestore);

  static const householdsPath = 'households';
  static const profilesPath = 'familyProfiles';
  static const healthPath = 'memberHealth';
  static const schoolsPath = 'schools';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _raw(
    String householdId,
    String path,
  ) => _firestore.collection(householdsPath).doc(householdId).collection(path);

  CollectionReference<FamilyProfile> _profiles(String householdId) =>
      typedCollection(
        _raw(householdId, profilesPath),
        fromJson: FamilyProfile.fromJson,
        toJson: (profile) => profile.toJson(),
      );

  CollectionReference<School> _schools(String householdId) => typedCollection(
    _raw(householdId, schoolsPath),
    fromJson: School.fromJson,
    toJson: (school) => school.toJson(),
  );

  CollectionReference<MemberHealth> _health(String householdId) =>
      typedCollection(
        _raw(householdId, healthPath),
        fromJson: MemberHealth.fromJson,
        toJson: (health) => health.toJson(),
      );

  @override
  Stream<List<FamilyProfile>> watchProfiles(
    String householdId, {
    String? onlyMemberId,
  }) {
    final Stream<List<FamilyProfile>> profiles = onlyMemberId == null
        ? _profiles(householdId)
              .limit(FamilyProfileRepository.profileLimit)
              .snapshots()
              .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
        : _profiles(
            householdId,
          ).doc(onlyMemberId).snapshots().map((snapshot) => [?snapshot.data()]);
    return profiles.handleError(
      (Object error) => throw failureFromFirebase(error),
    );
  }

  @override
  Stream<List<School>> watchSchools(String householdId) => _schools(householdId)
      .orderBy('name')
      .limit(FamilyProfileRepository.schoolLimit)
      .snapshots()
      .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
      .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<MemberHealth> watchHealth({
    required String householdId,
    required String memberId,
  }) => _health(householdId)
      .doc(memberId)
      .snapshots()
      .map((snapshot) => snapshot.data() ?? MemberHealth.empty(memberId))
      .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<void> saveFood({
    required String householdId,
    required String memberId,
    required List<String> likes,
    required List<String> dislikes,
    required Set<DietaryFlag> diet,
  }) => _mergeProfile(householdId, memberId, {
    'likes': likes,
    'dislikes': dislikes,
    'diet': const DietaryFlagsConverter().toJson(diet),
  });

  @override
  Future<void> saveAllergy({
    required String householdId,
    required String memberId,
    required AllergyDraft draft,
    Allergy? replacing,
  }) => _mergeProfile(
    householdId,
    memberId,
    allergyWriteFields(
      draft: draft,
      replacing: replacing,
      newOtherId: () => _raw(householdId, profilesPath).doc().id,
    ),
  );

  @override
  Future<void> removeAllergy({
    required String householdId,
    required String memberId,
    required Allergy allergy,
  }) => _mergeProfile(householdId, memberId, allergyRemovalFields(allergy));

  @override
  Future<void> saveSchooling({
    required String householdId,
    required String memberId,
    String? schoolId,
    String? grade,
  }) => _mergeProfile(householdId, memberId, {
    'schoolId': schoolId,
    'grade': grade,
  });

  @override
  Future<void> saveSizes({
    required String householdId,
    required String memberId,
    String? clothingSize,
    String? shoeSize,
  }) => _mergeProfile(householdId, memberId, {
    'clothingSize': clothingSize,
    'shoeSize': shoeSize,
  });

  @override
  Future<void> saveMedication({
    required String householdId,
    required String memberId,
    String? medicationId,
    required Medication medication,
  }) {
    final id = medicationId ?? _raw(householdId, healthPath).doc().id;
    return _guarded(
      () => _raw(householdId, healthPath).doc(memberId).set({
        'medications': {id: medication.toJson()},
      }, SetOptions(merge: true)),
    );
  }

  @override
  Future<void> removeMedication({
    required String householdId,
    required String memberId,
    required String medicationId,
  }) => _guarded(
    () => _raw(householdId, healthPath).doc(memberId).set({
      'medications': {medicationId: FieldValue.delete()},
    }, SetOptions(merge: true)),
  );

  @override
  Future<String> addSchool({
    required String householdId,
    required String name,
    required bool nutFree,
  }) async {
    final document = _schools(householdId).doc();
    await _guarded(
      () => document.set(School(id: document.id, name: name, nutFree: nutFree)),
    );
    return document.id;
  }

  @override
  Future<void> updateSchool({
    required String householdId,
    required String schoolId,
    required String name,
    required bool nutFree,
  }) => _guarded(
    () => _raw(
      householdId,
      schoolsPath,
    ).doc(schoolId).update({'name': name, 'nutFree': nutFree}),
  );

  @override
  Future<void> deleteSchool({
    required String householdId,
    required String schoolId,
  }) => _guarded(() => _raw(householdId, schoolsPath).doc(schoolId).delete());

  /// A profile is created by its first edit, so every write is a merge.
  Future<void> _mergeProfile(
    String householdId,
    String memberId,
    Map<String, Object?> fields,
  ) => _guarded(
    () => _raw(
      householdId,
      profilesPath,
    ).doc(memberId).set(fields, SetOptions(merge: true)),
  );

  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
