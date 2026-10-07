import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../../../shared/recurrence/recurrence_rule.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/event_exception.dart';
import '../model/household_event.dart';
import 'calendar_repository.dart';

final class FirestoreCalendarRepository implements CalendarRepository {
  FirestoreCalendarRepository(this._firestore);

  static const householdsPath = 'households';
  static const eventsPath = 'events';
  static const exceptionsPath = 'eventExceptions';

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _household(String householdId) =>
      _firestore.collection(householdsPath).doc(householdId);

  CollectionReference<HouseholdEvent> _events(String householdId) =>
      typedCollection(
        _household(householdId).collection(eventsPath),
        fromJson: HouseholdEvent.fromJson,
        toJson: (event) => event.toJson(),
      );

  CollectionReference<EventException> _exceptions(String householdId) =>
      typedCollection(
        _household(householdId).collection(exceptionsPath),
        fromJson: EventException.fromJson,
        toJson: (exception) => exception.toJson(),
      );

  @override
  Stream<List<HouseholdEvent>> watchEvents(String householdId) =>
      _events(householdId)
          .limit(CalendarRepository.eventLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<EventException>> watchExceptions(
    String householdId, {
    required CalendarDate from,
    required CalendarDate to,
  }) => _exceptions(householdId)
      .where('occurrenceDate', isGreaterThanOrEqualTo: from.iso)
      .where('occurrenceDate', isLessThanOrEqualTo: to.iso)
      .snapshots()
      .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
      .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<void> saveEvent({
    required String householdId,
    String? eventId,
    required String title,
    String? note,
    required CalendarDate date,
    int? startMinute,
    int? endMinute,
    RecurrenceRule? recurrence,
    required List<String> memberIds,
    required String createdBy,
  }) {
    final events = _events(householdId);
    if (eventId == null) {
      final document = events.doc();
      return _guarded(
        () => document.set(
          HouseholdEvent(
            id: document.id,
            title: title,
            note: note,
            date: date,
            startMinute: startMinute,
            endMinute: endMinute,
            recurrence: recurrence,
            memberIds: memberIds,
            createdBy: createdBy,
          ),
        ),
      );
    }
    return _guarded(
      () => events.doc(eventId).update({
        'title': title,
        'note': note,
        'date': date.iso,
        'startMinute': startMinute,
        'endMinute': endMinute,
        'recurrence': recurrence?.toJson(),
        'memberIds': memberIds,
      }),
    );
  }

  @override
  Future<void> deleteEvent({
    required String householdId,
    required String eventId,
  }) => _guarded(() => _events(householdId).doc(eventId).delete());

  @override
  Future<void> skipOccurrence({
    required String householdId,
    required String eventId,
    required CalendarDate occurrenceDate,
    required String memberId,
  }) {
    final id = EventException.idFor(eventId, occurrenceDate);
    return _guarded(
      () => _exceptions(householdId)
          .doc(id)
          .set(
            EventException(
              id: id,
              eventId: eventId,
              occurrenceDate: occurrenceDate,
              skippedBy: memberId,
            ),
          ),
    );
  }

  @override
  Future<void> unskipOccurrence({
    required String householdId,
    required String eventId,
    required CalendarDate occurrenceDate,
  }) => _guarded(
    () => _exceptions(
      householdId,
    ).doc(EventException.idFor(eventId, occurrenceDate)).delete(),
  );

  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
