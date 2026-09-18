import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/coordinates.dart';
import '../model/member_location.dart';
import 'live_location_repository.dart';

final class FirestoreLiveLocationRepository implements LiveLocationRepository {
  FirestoreLiveLocationRepository(this._firestore);

  static const householdsPath = 'households';
  static const locationsPath = 'memberLocations';

  final FirebaseFirestore _firestore;

  CollectionReference<MemberLocation> _locations(String householdId) =>
      typedCollection(
        _firestore
            .collection(householdsPath)
            .doc(householdId)
            .collection(locationsPath),
        fromJson: MemberLocation.fromJson,
        toJson: (location) => location.toJson(),
      );

  @override
  Stream<List<MemberLocation>> watchLocations(String householdId) =>
      _locations(householdId)
          .limit(LiveLocationRepository.locationLimit)
          .snapshots()
          .map(_toList)
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<void> report({
    required String householdId,
    required String memberId,
    required Coordinates at,
    required int accuracyMetres,
    required DateTime sharingUntil,
  }) => _guarded(
    () => _locations(householdId)
        .doc(memberId)
        .set(
          MemberLocation(
            id: memberId,
            point: at,
            accuracyMetres: accuracyMetres,
            sharingUntil: sharingUntil,
          ),
        ),
  );

  @override
  Future<void> stopSharing({
    required String householdId,
    required String memberId,
  }) => _guarded(() => _locations(householdId).doc(memberId).delete());

  List<MemberLocation> _toList(QuerySnapshot<MemberLocation> snapshot) => [
    for (final document in snapshot.docs) document.data(),
  ];

  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
