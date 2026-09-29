import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/home_care_product.dart';
import '../model/home_care_room.dart';
import '../model/room_kind.dart';
import 'home_care_library_repository.dart';

final class FirestoreHomeCareLibraryRepository
    implements HomeCareLibraryRepository {
  FirestoreHomeCareLibraryRepository(this._firestore);

  static const householdsPath = 'households';
  static const roomsPath = 'homeCareRooms';
  static const productsPath = 'homeCareProducts';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _raw(
    String householdId,
    String path,
  ) => _firestore.collection(householdsPath).doc(householdId).collection(path);

  CollectionReference<HomeCareRoom> _rooms(String householdId) =>
      typedCollection(
        _raw(householdId, roomsPath),
        fromJson: HomeCareRoom.fromJson,
        toJson: (room) => room.toJson(),
      );

  CollectionReference<HomeCareProduct> _products(String householdId) =>
      typedCollection(
        _raw(householdId, productsPath),
        fromJson: HomeCareProduct.fromJson,
        toJson: (product) => product.toJson(),
      );

  @override
  Stream<List<HomeCareRoom>> watchRooms(String householdId) =>
      _rooms(householdId)
          .limit(HomeCareLibraryRepository.roomLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<HomeCareProduct>> watchProducts(String householdId) =>
      _products(householdId)
          .limit(HomeCareLibraryRepository.productLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<void> saveRoom({
    required String householdId,
    String? roomId,
    required String name,
    required RoomKind kind,
    required String createdBy,
  }) {
    if (roomId != null) {
      // A rename never rewrites who added it or when (the rules refuse that).
      return _guarded(
        () => _raw(
          householdId,
          roomsPath,
        ).doc(roomId).update({'name': name, 'kind': kind.name}),
      );
    }
    final rooms = _rooms(householdId);
    final document = rooms.doc();
    return _guarded(
      () => document.set(
        HomeCareRoom(
          id: document.id,
          name: name,
          kind: kind,
          createdBy: createdBy,
        ),
      ),
    );
  }

  @override
  Future<void> addRooms({
    required String householdId,
    required List<({String name, RoomKind kind})> rooms,
    required String createdBy,
  }) {
    final collection = _rooms(householdId);
    final batch = _firestore.batch();
    for (final room in rooms) {
      final document = collection.doc();
      batch.set(
        document,
        HomeCareRoom(
          id: document.id,
          name: room.name,
          kind: room.kind,
          createdBy: createdBy,
        ),
      );
    }
    return _guarded(batch.commit);
  }

  @override
  Future<void> deleteRoom({
    required String householdId,
    required String roomId,
  }) => _guarded(() => _rooms(householdId).doc(roomId).delete());

  @override
  Future<void> saveProduct({
    required String householdId,
    required HomeCareProduct product,
  }) {
    if (product.id.isNotEmpty) {
      final stored = product.toJson()
        ..remove('createdBy')
        ..remove('createdAt');
      return _guarded(
        () => _raw(householdId, productsPath).doc(product.id).update(stored),
      );
    }
    final document = _products(householdId).doc();
    return _guarded(() => document.set(product.copyWith(id: document.id)));
  }

  @override
  Future<void> deleteProduct({
    required String householdId,
    required String productId,
  }) => _guarded(() => _products(householdId).doc(productId).delete());

  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
