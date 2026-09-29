import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/nanny_hub/model/shift_window.dart';

import '../../../support/nanny_access_fixtures.dart';

/// The client's mirror of the rules' booked-shift window (nanny-hub
/// ADR-0006): 15 minutes either side of a booking, inclusive at both ends.
void main() {
  final start = DateTime.utc(2026, 9, 30, 15, 30);
  final booking = AccessFixtures.booking(now: start);

  ShiftWindow at(DateTime now) =>
      shiftWindowAt(now, memberId: 'm-nomsa', bookings: [booking]);

  group('a booking', () {
    test('opens 15 minutes before it starts and closes 15 after it ends', () {
      expect(booking.opensAt, start.subtract(const Duration(minutes: 15)));
      expect(
        booking.closesAt,
        start.add(const Duration(hours: 4, minutes: 15)),
      );
    });

    test('is open at both edges exactly, and not a moment outside them', () {
      expect(booking.isOpenAt(booking.opensAt), isTrue);
      expect(booking.isOpenAt(booking.closesAt), isTrue);
      expect(
        booking.isOpenAt(booking.opensAt.subtract(const Duration(seconds: 1))),
        isFalse,
      );
      expect(
        booking.isOpenAt(booking.closesAt.add(const Duration(seconds: 1))),
        isFalse,
      );
    });

    test('has closed only once its grace after the end has passed', () {
      expect(booking.hasClosedBy(booking.closesAt), isFalse);
      expect(
        booking.hasClosedBy(booking.closesAt.add(const Duration(seconds: 1))),
        isTrue,
      );
    });
  });

  group('where the carer stands', () {
    test('two hours before the shift is off shift, waiting for it', () {
      expect(
        at(start.subtract(const Duration(hours: 2))),
        OffShift(next: booking),
      );
    });

    test('ten minutes before the start is inside the grace', () {
      expect(
        at(start.subtract(const Duration(minutes: 10))),
        OnBookedShift(booking),
      );
    });

    test('during the shift is on it', () {
      expect(at(start.add(const Duration(hours: 1))), OnBookedShift(booking));
    });

    test('ten minutes after the end is still inside the grace', () {
      expect(
        at(start.add(const Duration(hours: 4, minutes: 10))),
        OnBookedShift(booking),
      );
    });

    test('two hours after the end is off shift, with nothing next', () {
      expect(at(start.add(const Duration(hours: 6))), const OffShift());
    });

    test('another carer’s booking never opens the window', () {
      final theirs = AccessFixtures.booking(
        now: start,
        carerMemberId: 'm-zanele',
      );
      expect(
        shiftWindowAt(
          start.add(const Duration(hours: 1)),
          memberId: 'm-nomsa',
          bookings: [theirs],
        ),
        const OffShift(),
      );
    });

    test('the soonest of several is the one waited for', () {
      final later = AccessFixtures.booking(
        now: start,
        id: 'b-later',
        from: const Duration(days: 2),
      );
      final sooner = AccessFixtures.booking(
        now: start,
        id: 'b-sooner',
        from: const Duration(days: 1),
      );
      expect(
        shiftWindowAt(
          start.subtract(const Duration(hours: 1)),
          memberId: 'm-nomsa',
          bookings: [later, sooner],
        ),
        OffShift(next: sooner),
      );
    });

    test('a shift that has closed is neither on nor next', () {
      final tomorrow = AccessFixtures.booking(
        now: start,
        id: 'b-tomorrow',
        from: const Duration(days: 1),
      );
      expect(
        shiftWindowAt(
          start.add(const Duration(hours: 6)),
          memberId: 'm-nomsa',
          bookings: [booking, tomorrow],
        ),
        OffShift(next: tomorrow),
      );
    });

    test('family is always open, and off shift never is', () {
      expect(const AlwaysOpen().isOpen, isTrue);
      expect(const OffShift().isOpen, isFalse);
    });
  });
}
