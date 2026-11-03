import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/assistant_activity.dart';
import '../model/assistant_connection.dart';
import 'assistant_repository.dart';

final class FirestoreAssistantRepository implements AssistantRepository {
  FirestoreAssistantRepository(this._firestore);

  static const householdsPath = 'households';
  static const connectionsPath = 'assistantConnections';
  static const activityPath = 'assistantActivity';
  static const settingsPath = 'assistantSettings';
  static const currentSettings = 'current';

  static const _server = GetOptions(source: Source.server);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _household(String householdId) =>
      _firestore.collection(householdsPath).doc(householdId);

  CollectionReference<AssistantConnection> _connections(String householdId) =>
      typedCollection(
        _household(householdId).collection(connectionsPath),
        fromJson: AssistantConnection.fromJson,
        toJson: (connection) => connection.toJson(),
      );

  DocumentReference<Map<String, dynamic>> _settings(String householdId) =>
      _household(householdId).collection(settingsPath).doc(currentSettings);

  @override
  Stream<List<AssistantConnection>> watchConnections(
    String householdId, {
    String? ownerUid,
  }) {
    Query<AssistantConnection> query = _connections(householdId);
    if (ownerUid != null) query = query.where('uid', isEqualTo: ownerUid);
    return query
        .limit(AssistantRepository.connectionLimit)
        .snapshots()
        .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
        .handleError((Object error) => throw failureFromFirebase(error));
  }

  @override
  Stream<List<AssistantActivity>> watchActivity(
    String householdId, {
    String? memberId,
  }) {
    final Query<AssistantActivity> all = typedCollection(
      _household(householdId).collection(activityPath),
      fromJson: AssistantActivity.fromJson,
      toJson: (activity) => activity.toJson(),
    );
    // Newest first needs a composite index once it is filtered, so a member's
    // own activity is sorted on the device instead.
    final query = memberId == null
        ? all.orderBy('at', descending: true)
        : all.where('memberId', isEqualTo: memberId);
    return query
        .limit(AssistantRepository.activityLimit)
        .snapshots()
        .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
        .handleError((Object error) => throw failureFromFirebase(error));
  }

  @override
  Stream<bool> watchAllowed(String householdId) =>
      _household(householdId)
          .collection(settingsPath)
          .doc(currentSettings)
          .snapshots()
          .map((snapshot) => snapshot.data()?['allowed'] != false)
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<void> disconnect({
    required String householdId,
    required String connectionId,
  }) => _online(() async {
    final connection = _connections(householdId).doc(connectionId);
    await connection.get(_server);
    await connection.delete();
  });

  @override
  Future<void> setAllowed({
    required String householdId,
    required bool allowed,
    required String memberId,
  }) => _online(() async {
    final settings = _settings(householdId);
    await settings.get(_server);
    await settings.set({
      'allowed': allowed,
      'updatedBy': memberId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  });

  /// A write that must reach the server now: the read from the server before
  /// it fails at once when the phone is offline, rather than leaving the
  /// write queued while the cache shows it done.
  Future<void> _online(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
