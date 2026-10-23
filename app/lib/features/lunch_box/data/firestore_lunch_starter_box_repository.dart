import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/parsed_document.dart';
import '../../../shared/log/app_log.dart';
import '../model/lunch_starter_box.dart';
import 'lunch_starter_box_document.dart';
import 'lunch_starter_box_repository.dart';

/// `lunchStarterBoxes`, published only, in their order — one bounded read
/// when a parent opens them (`BE-08`).
final class FirestoreLunchStarterBoxRepository
    implements LunchStarterBoxRepository {
  const FirestoreLunchStarterBoxRepository(this._firestore);

  static const collection = 'lunchStarterBoxes';

  final FirebaseFirestore _firestore;

  @override
  Future<List<LunchStarterBox>> fetchPublished() async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .where('status', isEqualTo: LunchStarterBoxDocument.published)
          .orderBy('order')
          .limit(LunchStarterBox.limit)
          .get();
      return [for (final doc in snapshot.docs) ?_boxOf(doc.id, doc.data())];
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }

  static LunchStarterBox? _boxOf(String id, Map<String, Object?> data) {
    switch (LunchStarterBoxDocument.parse(id, data)) {
      case ValidDocument(:final value, :final dropped):
        for (final part in dropped) {
          AppLog.failure('read starter box, part dropped', code: part);
        }
        return value;
      case RejectedDocument(:final reason):
        AppLog.failure('read starter box, dropped', code: reason);
        return null;
    }
  }
}
