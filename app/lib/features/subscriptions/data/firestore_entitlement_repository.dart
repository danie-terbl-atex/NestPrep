import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/entitlement.dart';
import '../model/free_child.dart';
import 'entitlement_repository.dart';

final class FirestoreEntitlementRepository implements EntitlementRepository {
  FirestoreEntitlementRepository(this._firestore);

  static const householdsPath = 'households';
  static const entitlementPath = 'entitlement';
  static const currentEntitlement = 'current';
  static const freeChildDocument = 'freeChild';

  final FirebaseFirestore _firestore;

  @override
  Stream<Entitlement> watchEntitlement(String householdId) =>
      typedCollection(
            _firestore
                .collection(householdsPath)
                .doc(householdId)
                .collection(entitlementPath),
            fromJson: Entitlement.fromJson,
            toJson: (entitlement) => entitlement.toJson(),
          )
          .doc(currentEntitlement)
          .snapshots()
          .map((snapshot) => snapshot.data() ?? Entitlement.free)
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<FreeChild?> watchFreeChild(String householdId) => _firestore
      .collection(householdsPath)
      .doc(householdId)
      .collection(entitlementPath)
      .doc(freeChildDocument)
      .snapshots()
      .map(
        (snapshot) => snapshot.exists
            ? FreeChild.fromStored(snapshot.data()?['memberId'])
            : null,
      )
      .handleError((Object error) => throw failureFromFirebase(error));
}
