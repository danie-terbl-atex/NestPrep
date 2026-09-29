import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../family_profiles/data/firestore_family_profile_repository.dart';
import '../model/home_sheet.dart';
import '../model/nanny_limits.dart';
import '../model/shift_moment.dart';
import 'cache_warmer.dart';
import 'nanny_paths.dart';

/// Reads with `Source.server`, which is what writes the answer into
/// Firestore's persistent cache — the app's only local store for records
/// (foundation ADR-0006). Family profiles' collections are named by that
/// feature's own repository, and read under its grants (nanny-hub ADR-0003).
final class FirestoreCacheWarmer implements CacheWarmer {
  FirestoreCacheWarmer(this._firestore);

  static const _server = GetOptions(source: Source.server);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _home(String householdId) =>
      _firestore.collection(NannyPaths.households).doc(householdId);

  @override
  Future<Set<String>> warm(WarmRequest request) async {
    try {
      final home = _home(request.householdId);
      final withPhotos = await Future.wait([
        home
            .collection(NannyPaths.cards)
            .limit(NannyLimits.cardListen)
            .get(_server),
        home
            .collection(NannyPaths.guide)
            .limit(NannyLimits.guideListen)
            .get(_server),
        home
            .collection(NannyPaths.pickupPeople)
            .limit(NannyLimits.pickupPeopleListen)
            .get(_server),
      ]);
      await Future.wait<Object?>([
        _collection(home, NannyPaths.contacts, NannyLimits.contactListen),
        home.collection(NannyPaths.home).doc(HomeSheet.documentId).get(_server),
        _collection(home, NannyPaths.rules, NannyLimits.ruleListen),
        _collection(home, NannyPaths.checklists, ShiftMoment.values.length),
        _collection(home, NannyPaths.schoolRuns, NannyLimits.schoolRunListen),
        _collection(
          home,
          NannyPaths.pickupChanges,
          NannyLimits.pickupChangeListen,
        ),
        if (request.readsProfiles) ...[
          _collection(
            home,
            FirestoreFamilyProfileRepository.profilesPath,
            NannyLimits.cardListen,
          ),
          _collection(
            home,
            FirestoreFamilyProfileRepository.schoolsPath,
            NannyLimits.cardListen,
          ),
        ],
        for (final memberId in request.healthOf)
          home
              .collection(FirestoreFamilyProfileRepository.healthPath)
              .doc(memberId)
              .get(_server),
      ]);
      return {
        for (final snapshot in withPhotos)
          for (final doc in snapshot.docs)
            if (doc.data()['photoId'] case final String photoId) photoId,
      };
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _collection(
    DocumentReference<Map<String, dynamic>> home,
    String path,
    int limit,
  ) => home.collection(path).limit(limit).get(_server);
}
