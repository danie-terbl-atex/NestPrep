import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/language/helper_language.dart';
import '../model/language/helper_profile.dart';
import 'helper_profile_repository.dart';

final class FirestoreHelperProfileRepository
    implements HelperProfileRepository {
  FirestoreHelperProfileRepository(this._firestore);

  static const householdsPath = 'households';
  static const profilesPath = 'homeCareHelpers';

  final FirebaseFirestore _firestore;

  CollectionReference<HelperProfile> _profiles(String householdId) =>
      typedCollection(
        _firestore
            .collection(householdsPath)
            .doc(householdId)
            .collection(profilesPath),
        fromJson: HelperProfile.fromJson,
        toJson: (profile) => profile.toJson(),
      );

  @override
  Stream<List<HelperProfile>> watchProfiles(String householdId) =>
      _profiles(householdId)
          .limit(HelperProfileRepository.profileLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<HelperProfile?> watchProfile(String householdId, String memberId) =>
      _profiles(householdId)
          .doc(memberId)
          .snapshots()
          .map((snapshot) => snapshot.data())
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<void> setLanguage({
    required String householdId,
    required String memberId,
    required HelperLanguage language,
    required String by,
  }) async {
    try {
      await _profiles(householdId)
          .doc(memberId)
          .set(HelperProfile(id: memberId, language: language, updatedBy: by));
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
