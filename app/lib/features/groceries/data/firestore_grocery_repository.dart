import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/grocery_item.dart';
import '../model/grocery_plan_changes.dart';
import '../model/grocery_plan_settings.dart';
import '../model/product_match.dart';
import '../model/product_match_converter.dart';
import 'grocery_repository.dart';

final class FirestoreGroceryRepository implements GroceryRepository {
  FirestoreGroceryRepository(this._firestore);

  static const householdsPath = 'households';
  static const itemsPath = 'groceryItems';
  static const settingsPath = 'grocerySettings';

  final FirebaseFirestore _firestore;

  CollectionReference<GroceryItem> _items(String householdId) =>
      typedCollection(
        _firestore
            .collection(householdsPath)
            .doc(householdId)
            .collection(itemsPath),
        fromJson: GroceryItem.fromJson,
        toJson: (item) => item.toJson(),
      );

  DocumentReference<Map<String, dynamic>> _settings(String householdId) =>
      _firestore
          .collection(householdsPath)
          .doc(householdId)
          .collection(settingsPath)
          .doc(GroceryPlanSettings.documentId);

  @override
  Stream<List<GroceryItem>> watchItems(String householdId) =>
      _items(householdId)
          // No filter, so nothing here can disagree with anything else while a
          // write is pending; `addedAt` is always written, so nothing is
          // excluded for missing it. The split into bought and unbought happens
          // on the client, off one snapshot.
          .orderBy('addedAt', descending: true)
          .limit(GroceryRepository.itemLimit)
          .snapshots()
          .map(_toList)
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<String> add({
    required String householdId,
    required String name,
    String? quantity,
    required String addedBy,
  }) async {
    final items = _items(householdId);
    final document = items.doc();
    await _guarded(
      () => document.set(
        GroceryItem(
          id: document.id,
          name: name,
          quantity: quantity,
          addedBy: addedBy,
        ),
      ),
    );
    return document.id;
  }

  @override
  Future<void> setBought({
    required String householdId,
    required String itemId,
    required bool isBought,
    required String memberId,
  }) => _guarded(
    () => _items(householdId).doc(itemId).update({
      'boughtAt': isBought ? FieldValue.serverTimestamp() : null,
      'boughtBy': isBought ? memberId : null,
    }),
  );

  @override
  Future<void> rename({
    required String householdId,
    required String itemId,
    required String name,
    required String? quantity,
  }) => _guarded(
    () => _items(householdId).doc(itemId).update({
      'name': name,
      'quantity': quantity,
      // Edited by a person, so theirs now (groceries ADR-0002).
      'sourceKey': null,
      'sourceWeek': null,
      'sourceNote': null,
      // Deleted rather than nulled: on an item nobody matched, deleting an
      // absent field changes nothing, so the rules see a plain text edit.
      'productMatch': FieldValue.delete(),
    }),
  );

  @override
  Future<void> setProductMatch({
    required String householdId,
    required String itemId,
    required ProductMatch match,
  }) => _guarded(
    () => _items(householdId).doc(itemId).update({
      // `pickedAt` null becomes the server's time (the converter's rule).
      'productMatch': const ProductMatchConverter().toJson(
        match.copyWith(pickedAt: null),
      ),
    }),
  );

  @override
  Future<void> clearProductMatch({
    required String householdId,
    required String itemId,
  }) => _guarded(
    () => _items(
      householdId,
    ).doc(itemId).update({'productMatch': FieldValue.delete()}),
  );

  @override
  Future<void> remove({required String householdId, required String itemId}) =>
      _guarded(() => _items(householdId).doc(itemId).delete());

  @override
  Future<void> applyPlanChanges({
    required String householdId,
    required GroceryPlanChanges changes,
    required String memberId,
  }) => _guarded(() {
    final items = _items(householdId);
    final batch = _firestore.batch();
    for (final create in changes.creates) {
      batch.set(
        items.doc(create.id),
        GroceryItem(
          id: create.id,
          name: create.name,
          quantity: create.quantity,
          addedBy: memberId,
          sourceKey: create.key,
          sourceWeek: create.week,
          sourceNote: create.note,
        ),
      );
    }
    for (final refresh in changes.refreshes) {
      batch.update(items.doc(refresh.itemId), {
        'quantity': refresh.quantity,
        'sourceNote': refresh.note,
      });
    }
    for (final itemId in changes.removals) {
      batch.delete(items.doc(itemId));
    }
    return batch.commit();
  });

  @override
  Stream<GroceryPlanSettings> watchPlanSettings(String householdId) =>
      _firestore
          .collection(householdsPath)
          .doc(householdId)
          .collection(settingsPath)
          .doc(GroceryPlanSettings.documentId)
          .withConverter<GroceryPlanSettings>(
            fromFirestore: (snapshot, _) =>
                GroceryPlanSettings.fromJson({...?snapshot.data()}),
            toFirestore: (settings, _) => settings.toJson(),
          )
          .snapshots()
          .map((snapshot) => snapshot.data() ?? GroceryPlanSettings.empty)
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<void> setKeepInStep({
    required String householdId,
    required bool keepInStep,
    required String memberId,
  }) => _writeSettings(householdId, memberId, {'keepInStep': keepInStep});

  @override
  Future<void> setStaple({
    required String householdId,
    required String key,
    required bool isStaple,
    required String memberId,
  }) => _writeSettings(householdId, memberId, {
    'staples': isStaple
        ? FieldValue.arrayUnion([key])
        : FieldValue.arrayRemove([key]),
  });

  /// Merged, so the switch and the staples never overwrite each other, and
  /// signed with who changed it at the server's time.
  Future<void> _writeSettings(
    String householdId,
    String memberId,
    Map<String, Object> fields,
  ) => _guarded(
    () => _settings(householdId).set({
      ...fields,
      'updatedBy': memberId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)),
  );

  List<GroceryItem> _toList(QuerySnapshot<GroceryItem> snapshot) => [
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
