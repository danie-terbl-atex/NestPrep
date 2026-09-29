import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/calendar_connection.dart';
import '../model/calendar_feed_link.dart';
import '../model/synced_event.dart';
import 'calendar_sync_repository.dart';

final class FirestoreCalendarSyncRepository implements CalendarSyncRepository {
  FirestoreCalendarSyncRepository(this._firestore);

  static const householdsPath = 'households';
  static const connectionsPath = 'calendarConnections';
  static const syncedEventsPath = 'syncedEvents';
  static const feedPath = 'calendarFeed';
  static const currentFeed = 'current';

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _household(String householdId) =>
      _firestore.collection(householdsPath).doc(householdId);

  @override
  Stream<List<CalendarConnection>> watchConnections(String householdId) =>
      typedCollection(
            _household(householdId).collection(connectionsPath),
            fromJson: CalendarConnection.fromJson,
            toJson: (connection) => connection.toJson(),
          )
          .limit(CalendarSyncRepository.connectionLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<SyncedEvent>> watchSyncedEvents(
    String householdId, {
    required CalendarDate from,
    required CalendarDate to,
  }) =>
      typedCollection(
            _household(householdId).collection(syncedEventsPath),
            fromJson: SyncedEvent.fromJson,
            toJson: (event) => event.toJson(),
          )
          .where(
            'date',
            isGreaterThanOrEqualTo: from
                .addDays(-CalendarSyncRepository.spanReachDays)
                .iso,
          )
          .where('date', isLessThanOrEqualTo: to.iso)
          .snapshots()
          .map(
            (snapshot) => [
              for (final doc in snapshot.docs)
                if (doc.data().daysWithin(from, to).isNotEmpty) doc.data(),
            ],
          )
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<CalendarFeedLink?> watchFeedLink(String householdId) =>
      _household(householdId)
          .collection(feedPath)
          .doc(currentFeed)
          .snapshots()
          .map(_linkOf)
          .handleError((Object error) => throw failureFromFirebase(error));

  /// The link is the one field a client reads; anything else about the feed
  /// is the Function's (calendar ADR-0003).
  static CalendarFeedLink? _linkOf(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final url = snapshot.data()?['url'];
    return url is String && url.isNotEmpty ? CalendarFeedLink(url) : null;
  }
}
