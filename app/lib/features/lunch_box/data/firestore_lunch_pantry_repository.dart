import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/lunch_packed_day.dart';
import '../model/lunch_pantry_entry.dart';
import '../model/lunch_week.dart';
import 'lunch_pantry_repository.dart';

final class FirestoreLunchPantryRepository implements LunchPantryRepository {
  FirestoreLunchPantryRepository(this._firestore);

  static const householdsPath = 'households';
  static const pantryPath = 'lunchPantry';
  static const packedPath = 'lunchPacked';

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _household(String householdId) =>
      _firestore.collection(householdsPath).doc(householdId);

  CollectionReference<LunchPantryEntry> _pantry(String householdId) =>
      typedCollection(
        _household(householdId).collection(pantryPath),
        fromJson: LunchPantryEntry.fromJson,
        toJson: (entry) => entry.toJson(),
      );

  CollectionReference<LunchPackedDay> _packed(String householdId) =>
      typedCollection(
        _household(householdId).collection(packedPath),
        fromJson: LunchPackedDay.fromJson,
        toJson: (day) => day.toJson(),
      );

  @override
  Stream<List<LunchPantryEntry>> watchPantry(String householdId) =>
      _pantry(householdId)
          .limit(LunchPantryRepository.entryLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<LunchPackedDay>> watchPacked(
    String householdId,
    LunchWeek week,
  ) =>
      _packed(householdId)
          .where('week', isEqualTo: week.key)
          .limit(LunchPantryRepository.packedLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<void> setPortions({
    required String householdId,
    required String itemId,
    required int portions,
    required String by,
  }) => _guarded(
    () => _pantry(householdId)
        .doc(itemId)
        .set(
          LunchPantryEntry(
            id: itemId,
            portions: LunchPantryEntry.clamp(portions),
            updatedBy: by,
          ),
        ),
  );

  @override
  Future<void> remove({required String householdId, required String itemId}) =>
      _guarded(() => _pantry(householdId).doc(itemId).delete());

  @override
  Future<void> markPacked({
    required String householdId,
    required LunchPackedDay day,
    required Map<String, int> takeFrom,
  }) => _guarded(() {
    final batch = _firestore.batch()
      ..set(_packed(householdId).doc(day.id), day);
    _move(batch, householdId, takeFrom, sign: -1, by: day.by);
    return batch.commit();
  });

  @override
  Future<void> unmarkPacked({
    required String householdId,
    required LunchPackedDay day,
    required Map<String, int> giveBack,
  }) => _guarded(() {
    final batch = _firestore.batch()..delete(_packed(householdId).doc(day.id));
    _move(batch, householdId, giveBack, sign: 1, by: day.by);
    return batch.commit();
  });

  /// Moves each entry's portions by its count, in the direction of [sign].
  void _move(
    WriteBatch batch,
    String householdId,
    Map<String, int> counts, {
    required int sign,
    required String by,
  }) {
    for (final MapEntry(key: itemId, value: count) in counts.entries) {
      if (count <= 0) continue;
      batch.update(_household(householdId).collection(pantryPath).doc(itemId), {
        'portions': FieldValue.increment(sign * count),
        'updatedBy': by,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
