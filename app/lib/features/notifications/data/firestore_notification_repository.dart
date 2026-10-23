import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/inbox_item.dart';
import '../model/notification_settings.dart';
import 'notification_repository.dart';

final class FirestoreNotificationRepository implements NotificationRepository {
  FirestoreNotificationRepository(this._firestore);

  static const inboxPath = 'notificationInbox';
  static const settingsPath = 'notificationSettings';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _raw(
    String householdId,
    String path,
  ) => _firestore.collection('households').doc(householdId).collection(path);

  CollectionReference<InboxItem> _inbox(String householdId) => typedCollection(
    _raw(householdId, inboxPath),
    fromJson: InboxItem.fromJson,
    toJson: (item) => item.toJson(),
  );

  // `digestSlot` is derived, never chosen: it is what the digest job asks for,
  // and the rules refuse a slot that is not the chosen minute (ADR-0002).
  CollectionReference<NotificationSettings> _settings(String householdId) =>
      typedCollection(
        _raw(householdId, settingsPath),
        fromJson: NotificationSettings.fromJson,
        toJson: (settings) => {
          ...settings.toJson(),
          'digestSlot': settings.digestSlot,
        },
      );

  @override
  Stream<List<InboxItem>> watchInbox(String householdId, String memberId) =>
      _inbox(householdId)
          .where('memberId', isEqualTo: memberId)
          // Newest first by a field, never by the document id (the vault
          // lesson on descending key scans).
          .orderBy('createdAt', descending: true)
          .limit(NotificationRepository.inboxLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError(_failed);

  @override
  Stream<int> watchUnreadCount(String householdId, String memberId) =>
      _inbox(householdId)
          .where('memberId', isEqualTo: memberId)
          .where('readAt', isNull: true)
          .limit(NotificationRepository.unreadLimit)
          .snapshots()
          .map((snapshot) => snapshot.size)
          .handleError(_failed);

  @override
  Stream<InboxItem?> watchItem(String householdId, String itemId) =>
      _inbox(householdId)
          .doc(itemId)
          .snapshots()
          .map((snapshot) => snapshot.data())
          .handleError(_failed);

  @override
  Future<void> markRead(String householdId, String itemId) async {
    try {
      await _raw(
        householdId,
        inboxPath,
      ).doc(itemId).update({'readAt': FieldValue.serverTimestamp()});
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }

  @override
  Future<void> clear(String householdId, String itemId) async {
    try {
      await _raw(householdId, inboxPath).doc(itemId).delete();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }

  @override
  Stream<NotificationSettings?> watchSettings(
    String householdId,
    String memberId,
  ) =>
      _settings(householdId)
          .doc(memberId)
          .snapshots()
          .map((snapshot) => snapshot.data())
          .handleError(_failed);

  @override
  Future<void> saveSettings(
    String householdId,
    NotificationSettings settings,
  ) async {
    try {
      await _settings(householdId).doc(settings.id).set(settings);
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }

  static Never _failed(Object error) => throw failureFromFirebase(error);
}
