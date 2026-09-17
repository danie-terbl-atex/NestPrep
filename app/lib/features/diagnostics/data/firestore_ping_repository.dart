import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/emulator_ping.dart';
import 'ping_repository.dart';

final class FirestorePingRepository implements PingRepository {
  FirestorePingRepository(FirebaseFirestore firestore)
    : _pings = typedCollection(
        firestore.collection(collectionPath),
        fromJson: EmulatorPing.fromJson,
        toJson: (ping) => ping.toJson(),
      );

  static const collectionPath = 'diagnostics';

  final CollectionReference<EmulatorPing> _pings;

  @override
  Stream<List<EmulatorPing>> watchRecent({int limit = 20}) => _pings
      .orderBy('sentAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
      .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<void> send({required String sentFrom}) async {
    final ping = EmulatorPing(id: _pings.doc().id, sentFrom: sentFrom);
    try {
      await _pings.doc(ping.id).set(ping);
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
