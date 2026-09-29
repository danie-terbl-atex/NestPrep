import '../model/shift_booking.dart';

/// Booked shifts and the pass that names which one a carer is on, as
/// Firestore holds them (nanny-hub ADR-0006). Family books and cancels; a
/// carer reads their own and writes their own pass, and the rules check the
/// booking behind it on every read that needs a shift.
abstract interface class BookingRepository {
  /// Bookings that have not closed by [from], soonest first, bounded
  /// (`BE-08`). With [carerMemberId], only that carer's — what a carer kept
  /// to their shifts must ask for exactly, because a rule is not a filter.
  Stream<List<ShiftBooking>> watchUpcoming(
    String householdId, {
    required DateTime from,
    String? carerMemberId,
  });

  Future<void> book(BookingDraft draft);

  /// Removes [booking], and the pass that pointed at it in the same write,
  /// so its window closes at once for Storage as well as Firestore.
  Future<void> cancel(String householdId, ShiftBooking booking);

  /// Names [booking] as the shift [memberId] is on or is next on.
  Future<void> savePass(String householdId, ShiftBooking booking);
}

/// A shift a parent is booking.
typedef BookingDraft = ({
  String householdId,
  String carerMemberId,
  DateTime startsAt,
  DateTime endsAt,
  String? note,
  String createdBy,
});
