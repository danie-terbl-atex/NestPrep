import 'package:flutter/foundation.dart';

import 'shift_booking.dart';

/// Where the viewer stands against their booked shifts right now — the
/// client's mirror of the rules' `isOnBookedShift` (nanny-hub ADR-0006), used
/// only so nobody is shown a door the rules would keep shut (`FE-04`).
@immutable
sealed class ShiftWindow {
  const ShiftWindow();

  /// Whether a shift-only carer may be in the household, and anybody but
  /// family may read the house codes.
  bool get isOpen;
}

/// Family: never kept to a booking.
final class AlwaysOpen extends ShiftWindow {
  const AlwaysOpen();

  @override
  bool get isOpen => true;
}

/// Inside a booked shift's window.
final class OnBookedShift extends ShiftWindow {
  const OnBookedShift(this.booking);

  final ShiftBooking booking;

  @override
  bool get isOpen => true;

  @override
  bool operator ==(Object other) =>
      other is OnBookedShift && other.booking == booking;

  @override
  int get hashCode => booking.hashCode;
}

/// Outside every booked shift — with the next one, when there is one.
final class OffShift extends ShiftWindow {
  const OffShift({this.next});

  final ShiftBooking? next;

  @override
  bool get isOpen => false;

  @override
  bool operator ==(Object other) => other is OffShift && other.next == next;

  @override
  int get hashCode => next.hashCode;
}

/// The window [bookings] put [memberId] in at [now]: inside the first booking
/// of theirs whose window holds it, or else waiting for the next to open.
/// [bookings] may be anybody's; only the member's own count.
ShiftWindow shiftWindowAt(
  DateTime now, {
  required String memberId,
  required Iterable<ShiftBooking> bookings,
}) {
  final mine = [
    for (final booking in bookings)
      if (booking.carerMemberId == memberId && !booking.hasClosedBy(now))
        booking,
  ]..sort((a, b) => a.opensAt.compareTo(b.opensAt));
  final current = mine.where((booking) => booking.isOpenAt(now)).firstOrNull;
  if (current != null) return OnBookedShift(current);
  return OffShift(next: mine.firstOrNull);
}
