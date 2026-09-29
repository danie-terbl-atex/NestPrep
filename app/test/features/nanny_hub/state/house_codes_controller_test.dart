import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/nanny_hub/model/house_codes.dart';
import 'package:nestprep/features/nanny_hub/state/house_codes_controller.dart';
import 'package:nestprep/features/nanny_hub/state/shift_pass_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_nanny_access.dart';
import '../../../support/nanny_access_fixtures.dart';

/// The house codes (nanny-hub ADR-0006): family reads them always; anybody
/// else only inside a shift booked for them, fetched fresh when it opens and
/// let go of when it closes. A refusal is the window being shut, not an error.
void main() {
  late FakeBookingRepository bookings;
  late FakeHouseCodeRepository codes;
  late DateTime now;

  setUp(() {
    bookings = FakeBookingRepository();
    codes = FakeHouseCodeRepository()
      ..codes = const [AccessFixtures.alarm, AccessFixtures.gate];
    now = DateTime.utc(2026, 9, 30, 12);
  });
  tearDown(() => bookings.close());

  ShiftPassController pass({bool isFamily = false}) => ShiftPassController(
    bookingRepository: bookings,
    householdId: 'h1',
    memberId: isFamily ? 'm-sam' : 'm-nomsa',
    isFamily: isFamily,
    now: () => now,
  );

  HouseCodesController codesFor(
    ShiftPassController window, {
    bool isFamily = false,
  }) => HouseCodesController(
    houseCodeRepository: codes,
    pass: window,
    householdId: 'h1',
    memberId: isFamily ? 'm-sam' : 'm-nomsa',
    isFamily: isFamily,
  );

  HouseCodes? shown(HouseCodesController controller) =>
      switch (controller.codes) {
        AsyncData(:final value) => value,
        _ => null,
      };

  testWidgets('family reads the codes at once, with no window to wait for', (
    tester,
  ) async {
    final window = pass(isFamily: true);
    final controller = codesFor(window, isFamily: true);
    await tester.pump();
    final value = shown(controller);
    expect(value, isA<CodesShown>());
    expect((value! as CodesShown).codes, hasLength(2));
    expect((value as CodesShown).closesAt, isNull);
    controller.dispose();
    window.dispose();
  });

  testWidgets('a carer off shift sees them shut, the next shift named, and '
      'the server is never asked', (tester) async {
    final window = pass();
    final controller = codesFor(window);
    final next = AccessFixtures.booking(
      now: now,
      from: const Duration(hours: 5),
    );
    bookings.bookings.add([next]);
    await tester.pump();
    final value = shown(controller);
    expect(value, isA<CodesClosed>());
    expect((value! as CodesClosed).next, next);
    expect(codes.fetches, 0);
    controller.dispose();
    window.dispose();
  });

  testWidgets('the window opening fetches the codes, shown until it closes; '
      'the window closing lets them go', (tester) async {
    final window = pass();
    final controller = codesFor(window);
    final booking = AccessFixtures.booking(
      now: now,
      from: const Duration(hours: 1),
      length: const Duration(hours: 2),
    );
    bookings.bookings.add([booking]);
    await tester.pump();
    expect(shown(controller), isA<CodesClosed>());

    now = booking.opensAt.add(const Duration(seconds: 1));
    await tester.pump(const Duration(minutes: 45, seconds: 1));
    final open = shown(controller);
    expect(open, isA<CodesShown>());
    expect((open! as CodesShown).closesAt, booking.closesAt);
    expect(codes.fetches, 1);

    now = booking.closesAt.add(const Duration(seconds: 1));
    await tester.pump(const Duration(hours: 2, minutes: 30));
    expect(shown(controller), isA<CodesClosed>());
    expect(codes.fetches, 1);
    controller.dispose();
    window.dispose();
  });

  testWidgets('a refusal from the rules is the window shut, not an error', (
    tester,
  ) async {
    codes.failFetchWith = const PermissionDeniedFailure();
    final window = pass();
    final controller = codesFor(window);
    bookings.bookings.add([
      AccessFixtures.booking(now: now, from: const Duration(minutes: -30)),
    ]);
    await tester.pump();
    expect(codes.fetches, 1);
    expect(shown(controller), isA<CodesClosed>());
    controller.dispose();
    window.dispose();
  });

  testWidgets('no signal is a failure the screen offers to retry', (
    tester,
  ) async {
    codes.failFetchWith = const UnavailableFailure();
    final window = pass();
    final controller = codesFor(window);
    bookings.bookings.add([
      AccessFixtures.booking(now: now, from: const Duration(minutes: -30)),
    ]);
    await tester.pump();
    expect(controller.codes, isA<AsyncFailure<HouseCodes>>());

    codes.failFetchWith = null;
    await controller.retry();
    await tester.pump();
    expect(shown(controller), isA<CodesShown>());
    controller.dispose();
    window.dispose();
  });

  testWidgets('family adds, changes and removes a code, and reads them again '
      'after each', (tester) async {
    final window = pass(isFamily: true);
    final controller = codesFor(window, isFamily: true);
    await tester.pump();
    const draft = (label: 'Alarm', value: '1234', note: null);
    await controller.add(draft);
    await controller.update('code-alarm', draft);
    await controller.remove('code-gate');
    await tester.pump();
    expect(codes.writes, [
      ('add', draft),
      ('update:code-alarm', draft),
      ('remove:code-gate', null),
    ]);
    expect(codes.fetches, 4);
    controller.dispose();
    window.dispose();
  });

  testWidgets('a refused change is the banner, and nothing is read again', (
    tester,
  ) async {
    final window = pass(isFamily: true);
    final controller = codesFor(window, isFamily: true);
    await tester.pump();
    codes.failWritesWith = const PermissionDeniedFailure();
    await controller.remove('code-gate');
    expect(controller.actionFailure, isA<PermissionDeniedFailure>());
    expect(codes.fetches, 1);
    controller.dispose();
    window.dispose();
  });
}
