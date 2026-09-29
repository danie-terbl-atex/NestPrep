import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/nanny_limits.dart';
import '../model/shift_booking.dart';
import 'booking_repository.dart';
import 'nanny_paths.dart';

final class FirestoreBookingRepository implements BookingRepository {
  FirestoreBookingRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _home(String householdId) =>
      _firestore.collection(NannyPaths.households).doc(householdId);

  CollectionReference<Map<String, dynamic>> _bookings(String householdId) =>
      _home(householdId).collection(NannyPaths.bookings);

  DocumentReference<Map<String, dynamic>> _pass(
    String householdId,
    String memberId,
  ) => _home(householdId).collection(NannyPaths.passes).doc(memberId);

  @override
  Stream<List<ShiftBooking>> watchUpcoming(
    String householdId, {
    required DateTime from,
    String? carerMemberId,
  }) {
    Query<ShiftBooking> query = typedCollection(
      _bookings(householdId),
      fromJson: ShiftBooking.fromJson,
      toJson: (_) => throw UnsupportedError('written field by field'),
    );
    if (carerMemberId != null) {
      query = query.where('carerMemberId', isEqualTo: carerMemberId);
    }
    // A booking still open for its grace counts: `endsAt` is compared with
    // the start of the grace, not with now.
    return query
        .where(
          'endsAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            from.toUtc().subtract(NannyLimits.shiftGrace),
          ),
        )
        .orderBy('endsAt')
        .limit(NannyLimits.bookingListen)
        .snapshots()
        .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
        .handleError((Object error) => throw failureFromFirebase(error));
  }

  @override
  Future<void> book(BookingDraft draft) => _guarded(
    () => _bookings(draft.householdId).add({
      'carerMemberId': draft.carerMemberId,
      'startsAt': Timestamp.fromDate(draft.startsAt.toUtc()),
      'endsAt': Timestamp.fromDate(draft.endsAt.toUtc()),
      'note': draft.note,
      'createdBy': draft.createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> cancel(String householdId, ShiftBooking booking) =>
      _guarded(() async {
        final pass = _pass(householdId, booking.carerMemberId);
        final named = await pass.get();
        final batch = _firestore.batch()
          ..delete(_bookings(householdId).doc(booking.id));
        if (named.data()?['bookingId'] == booking.id) batch.delete(pass);
        await batch.commit();
        return null;
      });

  @override
  Future<void> savePass(String householdId, ShiftBooking booking) => _guarded(
    () => _pass(householdId, booking.carerMemberId).set({
      'bookingId': booking.id,
      // Copies of the booking's own instants, which the rules hold equal:
      // Storage cannot read the booking, and reads these instead.
      'startsAt': Timestamp.fromDate(booking.startsAt.toUtc()),
      'endsAt': Timestamp.fromDate(booking.endsAt.toUtc()),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  Future<void> _guarded(Future<Object?> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
