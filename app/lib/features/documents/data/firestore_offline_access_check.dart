import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/log/app_log.dart';
import '../model/offline_copy.dart';
import 'offline_access_check.dart';

/// Re-reads a copy's metadata row **from the server** (documents ADR-0007):
/// the rules answer for the person as they are now, so a revoked vault grant,
/// a narrowed role or a deleted document all come back as [OfflineAccess.lost].
final class FirestoreOfflineAccessCheck implements OfflineAccessCheck {
  const FirestoreOfflineAccessCheck(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _rowOf(OfflineCopy copy) {
    final household = _firestore.collection('households').doc(copy.householdId);
    final owner = copy.ownerMemberId;
    return owner == null
        ? household.collection('documents').doc(copy.documentId)
        : household
              .collection('vaults')
              .doc(owner)
              .collection('vaultDocuments')
              .doc(copy.documentId);
  }

  @override
  Future<OfflineAccess> check(OfflineCopy copy) async {
    try {
      final row = await _rowOf(
        copy,
      ).get(const GetOptions(source: Source.server));
      return row.exists ? OfflineAccess.kept : OfflineAccess.lost;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return OfflineAccess.lost;
      // Unreachable, or anything else: keep the copy and ask again next time.
      AppLog.failure('offline access check', code: error.code, error: error);
      return OfflineAccess.unknown;
    }
  }
}
