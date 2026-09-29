import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/entitlement.dart';
import 'entitlement_repository.dart';

final class FirestoreEntitlementRepository implements EntitlementRepository {
  FirestoreEntitlementRepository(this._firestore);

  static const householdsPath = 'households';
  static const entitlementPath = 'entitlement';
  static const currentEntitlement = 'current';

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
}
