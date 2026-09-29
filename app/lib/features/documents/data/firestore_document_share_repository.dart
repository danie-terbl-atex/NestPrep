import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/document_share.dart';
import 'document_share_repository.dart';

final class FirestoreDocumentShareRepository
    implements DocumentShareRepository {
  FirestoreDocumentShareRepository(this._firestore);

  static const sharesPath = 'documentShares';

  final FirebaseFirestore _firestore;

  CollectionReference<DocumentShare> _shares(String householdId) =>
      typedCollection(
        _firestore
            .collection('households')
            .doc(householdId)
            .collection(sharesPath),
        fromJson: DocumentShare.fromJson,
        toJson: (share) => share.toJson(),
      );

  /// Two shapes, because the rules allow two: the family's query over the
  /// whole household, and anybody else's over the links they made — each
  /// with its composite index in `firestore.indexes.json`.
  @override
  Stream<List<DocumentShare>> watchLiveShares({
    required String householdId,
    required String viewerUid,
    required bool isFamily,
    required DateTime now,
    int limit = DocumentShareRepository.liveShareLimit,
  }) {
    final after = Timestamp.fromDate(now.toUtc());
    final snapshots = isFamily
        ? _shares(householdId)
              .where('status', isEqualTo: DocumentShare.active)
              .where('expiresAt', isGreaterThan: after)
              .orderBy('expiresAt')
              .limit(limit)
              .snapshots()
        : _shares(householdId)
              .where('createdByUid', isEqualTo: viewerUid)
              .where('status', isEqualTo: DocumentShare.active)
              .where('expiresAt', isGreaterThan: after)
              .orderBy('expiresAt')
              .limit(limit)
              .snapshots();
    return snapshots
        .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
        .handleError((Object error) => throw failureFromFirebase(error));
  }
}
