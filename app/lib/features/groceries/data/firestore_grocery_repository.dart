import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/grocery_item.dart';
import 'grocery_repository.dart';

final class FirestoreGroceryRepository implements GroceryRepository {
  FirestoreGroceryRepository(this._firestore);

  static const householdsPath = 'households';
  static const itemsPath = 'groceryItems';

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
  Future<void> add({
    required String householdId,
    required String name,
    String? quantity,
    required String addedBy,
  }) {
    final items = _items(householdId);
    final document = items.doc();
    return _guarded(
      () => document.set(
        GroceryItem(
          id: document.id,
          name: name,
          quantity: quantity,
          addedBy: addedBy,
        ),
      ),
    );
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
    () =>
        _items(householdId)
            .doc(itemId)
            .update({'name': name, 'quantity': quantity}),
  );

  @override
  Future<void> remove({required String householdId, required String itemId}) =>
      _guarded(() => _items(householdId).doc(itemId).delete());

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
