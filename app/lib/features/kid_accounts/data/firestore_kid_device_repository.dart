import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/kid_device.dart';
import 'kid_device_repository.dart';

final class FirestoreKidDeviceRepository implements KidDeviceRepository {
  FirestoreKidDeviceRepository(this._firestore);

  static const householdsPath = 'households';
  static const devicesPath = 'kidDevices';

  final FirebaseFirestore _firestore;

  CollectionReference<KidDevice> _devices(String householdId) =>
      typedCollection(
        _firestore
            .collection(householdsPath)
            .doc(householdId)
            .collection(devicesPath),
        fromJson: KidDevice.fromJson,
        toJson: (device) => device.toJson(),
      );

  @override
  Stream<List<KidDevice>> watchDevices(String householdId) =>
      _devices(householdId)
          .limit(KidDeviceRepository.deviceLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));
}
