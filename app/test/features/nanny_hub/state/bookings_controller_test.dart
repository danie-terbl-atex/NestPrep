import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/nanny_hub/model/shift_booking.dart';
import 'package:nestprep/features/nanny_hub/state/bookings_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_nanny_access.dart';
import '../../../support/fake_nanny_hub.dart';
import '../../../support/nanny_access_fixtures.dart';

/// Booked shifts (nanny-hub ADR-0006): family books and cancels, an admin
/// keeps a carer to them, a carer reads their own. A double tap books once.
void main() {
  late FakeBookingRepository bookings;
  late FakeShiftDirectory directory;
  final now = DateTime.utc(2026, 9, 30, 12);

  setUp(() {
    bookings = FakeBookingRepository();
    directory = FakeShiftDirectory();
  });
  tearDown(() => bookings.close());

  BookingsController controllerFor({bool isFamily = true}) =>
      BookingsController(
        bookingRepository: bookings,
        shiftDirectory: directory,
        householdId: 'h1',
        viewerMemberId: isFamily ? 'm-sam' : 'm-nomsa',
        isFamily: isFamily,
        now: () => now,
      );

  List<ShiftBooking>? listed(BookingsController controller) =>
      switch (controller.upcoming) {
        AsyncData(:final value) => value,
        _ => null,
      };

  test('family watches everybody’s shifts', () {
    final controller = controllerFor();
    addTearDown(controller.dispose);
    expect(bookings.askedForCarer, isNull);
  });

  test('a carer watches only their own', () {
    final controller = controllerFor(isFamily: false);
    addTearDown(controller.dispose);
    expect(bookings.askedForCarer, 'm-nomsa');
  });

  test(
    'a shift that has closed is dropped, and the rest are soonest first',
    () async {
      final controller = controllerFor();
      addTearDown(controller.dispose);
      final closed = AccessFixtures.booking(
        now: now,
        id: 'b-closed',
        from: const Duration(hours: -6),
      );
      final later = AccessFixtures.booking(
        now: now,
        id: 'b-later',
        from: const Duration(days: 2),
      );
      final sooner = AccessFixtures.booking(
        now: now,
        id: 'b-sooner',
        from: const Duration(days: 1),
      );
      bookings.bookings.add([closed, later, sooner]);
      await pumpEventQueue();
      expect(listed(controller), [sooner, later]);
    },
  );

  test('a failed read is the screen’s failure', () async {
    final controller = controllerFor();
    addTearDown(controller.dispose);
    bookings.bookings.addError(const PermissionDeniedFailure());
    await pumpEventQueue();
    expect(controller.upcoming, isA<AsyncFailure<List<ShiftBooking>>>());
  });

  test('booking sends the shift, stamped with who booked it, the note '
      'tidied', () async {
    final controller = controllerFor();
    addTearDown(controller.dispose);
    final startsAt = now.add(const Duration(days: 1));
    final endsAt = startsAt.add(const Duration(hours: 4));
    final booked = await controller.book(
      carerMemberId: 'm-nomsa',
      startsAt: startsAt,
      endsAt: endsAt,
      note: '  School run first  ',
    );
    expect(booked, isTrue);
    expect(bookings.booked.single, (
      householdId: 'h1',
      carerMemberId: 'm-nomsa',
      startsAt: startsAt,
      endsAt: endsAt,
      note: 'School run first',
      createdBy: 'm-sam',
    ));
  });

  test('a blank note is no note', () async {
    final controller = controllerFor();
    addTearDown(controller.dispose);
    await controller.book(
      carerMemberId: 'm-nomsa',
      startsAt: now,
      endsAt: now.add(const Duration(hours: 1)),
      note: '   ',
    );
    expect(bookings.booked.single.note, isNull);
  });

  test('a second tap while booking books nothing more', () async {
    final controller = controllerFor();
    addTearDown(controller.dispose);
    final first = controller.book(
      carerMemberId: 'm-nomsa',
      startsAt: now,
      endsAt: now.add(const Duration(hours: 1)),
    );
    expect(controller.isBooking, isTrue);
    final second = await controller.book(
      carerMemberId: 'm-nomsa',
      startsAt: now,
      endsAt: now.add(const Duration(hours: 1)),
    );
    expect(second, isFalse);
    expect(await first, isTrue);
    expect(bookings.booked, hasLength(1));
    expect(controller.isBooking, isFalse);
  });

  test('a refused booking is the banner and answers false', () async {
    final controller = controllerFor();
    addTearDown(controller.dispose);
    bookings.failWritesWith = const PermissionDeniedFailure();
    final booked = await controller.book(
      carerMemberId: 'm-nomsa',
      startsAt: now,
      endsAt: now.add(const Duration(hours: 1)),
    );
    expect(booked, isFalse);
    expect(controller.actionFailure, isA<PermissionDeniedFailure>());
  });

  test('cancelling hands the booking to the repository', () async {
    final controller = controllerFor();
    addTearDown(controller.dispose);
    await controller.cancel(AccessFixtures.booking(now: now, id: 'b-gone'));
    expect(bookings.cancelled, ['b-gone']);
  });

  test('keeping a carer to their shifts asks the Function, and the switch '
      'waits while it is on its way', () async {
    final controller = controllerFor();
    addTearDown(controller.dispose);
    final gate = Completer<void>();
    directory.gate = gate;
    final changing = controller.setShiftOnly('m-nomsa', isShiftOnly: true);
    expect(controller.isChangingShiftOnly('m-nomsa'), isTrue);
    gate.complete();
    await changing;
    expect(directory.shiftOnly, {'m-nomsa': true});
    expect(controller.isChangingShiftOnly('m-nomsa'), isFalse);
  });

  test('a refused change is the banner', () async {
    final controller = controllerFor();
    addTearDown(controller.dispose);
    directory.failWith = const NannyHubFailure(NannyHubProblem.notACarer);
    await controller.setShiftOnly('m-thandi', isShiftOnly: true);
    expect(
      controller.actionFailure,
      isA<NannyHubFailure>().having(
        (failure) => failure.problem,
        'problem',
        NannyHubProblem.notACarer,
      ),
    );
  });
}
