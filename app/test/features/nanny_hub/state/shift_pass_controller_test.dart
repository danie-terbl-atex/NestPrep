import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/nanny_hub/model/shift_window.dart';
import 'package:nestprep/features/nanny_hub/state/shift_pass_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_nanny_access.dart';
import '../../../support/nanny_access_fixtures.dart';

/// The booked-shift window on the household shell (nanny-hub ADR-0006): what
/// the gate and the house codes open on, and the pass the rules check the
/// time against. `testWidgets` so the stream and the edge timer both run in
/// the test's fake time.
void main() {
  late FakeBookingRepository bookings;
  late DateTime now;

  setUp(() {
    bookings = FakeBookingRepository();
    now = DateTime.utc(2026, 9, 30, 12);
  });
  tearDown(() => bookings.close());

  ShiftPassController carer({String? memberId = 'm-nomsa'}) =>
      ShiftPassController(
        bookingRepository: bookings,
        householdId: 'h1',
        memberId: memberId,
        isFamily: false,
        now: () => now,
      );

  ShiftWindow? windowOf(ShiftPassController controller) =>
      switch (controller.window) {
        AsyncData(:final value) => value,
        _ => null,
      };

  testWidgets('family is always open and never asks for bookings', (
    tester,
  ) async {
    final controller = ShiftPassController(
      bookingRepository: bookings,
      householdId: 'h1',
      memberId: 'm-sam',
      isFamily: true,
      now: () => now,
    );
    expect(windowOf(controller), const AlwaysOpen());
    expect(controller.isOpen, isTrue);
    expect(bookings.bookings.hasListener, isFalse);
    controller.dispose();
  });

  testWidgets('an account with no profile is off shift, with nothing next', (
    tester,
  ) async {
    final controller = carer(memberId: null);
    expect(windowOf(controller), const OffShift());
    expect(bookings.bookings.hasListener, isFalse);
    controller.dispose();
  });

  testWidgets('it asks for the carer’s own bookings only', (tester) async {
    final controller = carer();
    expect(bookings.askedForCarer, 'm-nomsa');
    expect(controller.window, isA<AsyncLoading<ShiftWindow>>());
    controller.dispose();
  });

  testWidgets('on a booked shift it is open, and the pass names that booking', (
    tester,
  ) async {
    final controller = carer();
    final booking = AccessFixtures.booking(
      now: now,
      from: const Duration(hours: -1),
    );
    bookings.bookings.add([booking]);
    await tester.pump();
    expect(windowOf(controller), OnBookedShift(booking));
    expect(controller.isOpen, isTrue);
    expect(bookings.passes, [booking.id]);
    controller.dispose();
  });

  testWidgets('off shift it waits for the next, and names it on the pass '
      'ahead — so the window opens without a signal at the gate', (
    tester,
  ) async {
    final controller = carer();
    final next = AccessFixtures.booking(
      now: now,
      from: const Duration(hours: 5),
    );
    bookings.bookings.add([next]);
    await tester.pump();
    expect(windowOf(controller), OffShift(next: next));
    expect(controller.isOpen, isFalse);
    expect(bookings.passes, [next.id]);
    expect(controller.stillToCome, [next]);
    controller.dispose();
  });

  testWidgets('the window opens and closes at its edges as the clock moves', (
    tester,
  ) async {
    final controller = carer();
    final booking = AccessFixtures.booking(
      now: now,
      from: const Duration(hours: 1),
      length: const Duration(hours: 2),
    );
    bookings.bookings.add([booking]);
    await tester.pump();
    expect(controller.isOpen, isFalse);

    // 45 minutes and a second on: 15 minutes before the start.
    now = booking.opensAt.add(const Duration(seconds: 1));
    await tester.pump(const Duration(minutes: 45, seconds: 1));
    expect(windowOf(controller), OnBookedShift(booking));

    now = booking.closesAt.add(const Duration(seconds: 1));
    await tester.pump(const Duration(hours: 2, minutes: 30));
    expect(windowOf(controller), const OffShift());
    expect(controller.stillToCome, isEmpty);
    controller.dispose();
  });

  testWidgets('a pass the server refused is written again at the next edge', (
    tester,
  ) async {
    final controller = carer();
    bookings.failPassesWith = const UnavailableFailure();
    final booking = AccessFixtures.booking(
      now: now,
      from: const Duration(hours: 1),
    );
    bookings.bookings.add([booking]);
    await tester.pump();
    expect(bookings.passes, isEmpty);

    bookings.failPassesWith = null;
    now = booking.opensAt.add(const Duration(seconds: 1));
    await tester.pump(const Duration(minutes: 45, seconds: 1));
    expect(bookings.passes, [booking.id]);
    controller.dispose();
  });

  testWidgets('a pass already written is not written twice', (tester) async {
    final controller = carer();
    final booking = AccessFixtures.booking(
      now: now,
      from: const Duration(hours: -1),
    );
    bookings.bookings.add([booking]);
    await tester.pump();
    bookings.bookings.add([booking]);
    await tester.pump();
    expect(bookings.passes, [booking.id]);
    controller.dispose();
  });

  testWidgets('a read that fails is a failure, and retry reads again', (
    tester,
  ) async {
    final controller = carer();
    bookings.bookings.addError(const PermissionDeniedFailure());
    await tester.pump();
    expect(controller.window, isA<AsyncFailure<ShiftWindow>>());
    expect(controller.isOpen, isFalse);

    // A real turn for the cancel inside retry to finish (the lesson on
    // awaiting a subscription's cancel in a widget test).
    await tester.runAsync(controller.retry);
    expect(controller.window, isA<AsyncLoading<ShiftWindow>>());
    bookings.bookings.add([]);
    await tester.pump();
    expect(windowOf(controller), const OffShift());
    controller.dispose();
  });
}
