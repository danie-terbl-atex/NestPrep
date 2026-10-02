import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nestprep/app/nanny_hub_route.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/nanny_hub/ui/hub_clock.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/household_clock.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/nanny_access_fixtures.dart';
import '../../../support/nanny_fixtures.dart';
import '../../../support/pump_nanny_hub.dart';

/// Booked shifts (nanny-hub ADR-0006): family books a carer's shifts ahead
/// and cancels them; an admin keeps a carer to them; a carer sees their own.
void main() {
  late NannyFakes fakes;

  setUp(() => fakes = NannyFakes());
  tearDown(() => fakes.close());

  // Made after the pump, which is what loads the timezone data.
  HouseholdClock clock() => HouseholdClock('Africa/Johannesburg');

  /// Sam as a parent who is not the admin: family, but not the one who
  /// decides what a carer sees.
  HouseholdView parentNotAdminView() {
    final view = NannyFixtures.parentView();
    return HouseholdView(
      household: view.household.copyWith(
        members: const {
          Fixtures.samUid: 'parent',
          Fixtures.thandiUid: 'helper',
          NannyFixtures.nomsaUid: 'carer',
        },
      ),
      members: view.members,
      viewerUid: Fixtures.samUid,
    );
  }

  Future<void> open(
    WidgetTester tester, {
    HouseholdView? view,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    await pumpNannyHub(
      tester,
      fakes,
      location: NannyHubRoute.bookingsPathFor(Fixtures.householdId),
      view: view,
      brightness: brightness,
      textScale: textScale,
    );
    await tester.pump();
  }

  testWidgets('the admin sees each carer, and keeping one to their shifts '
      'asks the server', (tester) async {
    await open(tester);
    fakes.bookings.bookings.add([]);
    await tester.pumpAndSettle();

    expect(find.text(NannyFixtures.nomsa.displayName), findsOneWidget);
    expect(find.text(NannyBookingCopy.shiftOnly), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(fakes.directory.shiftOnly, {NannyFixtures.nomsaMemberId: true});
  });

  testWidgets('a helper can be booked but has no shift-only switch — only a '
      'carer can be kept to their shifts', (tester) async {
    await open(tester);
    fakes.bookings.bookings.add([]);
    await tester.pumpAndSettle();
    expect(find.byType(Switch), findsOneWidget);
    expect(find.text(Fixtures.thandi.displayName), findsNothing);
  });

  testWidgets('a parent who is not the admin sees the choice, and cannot '
      'change it', (tester) async {
    await open(tester, view: parentNotAdminView());
    fakes.bookings.bookings.add([]);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    expect(
      find.textContaining(NannyBookingCopy.shiftOnlyAdminOnly),
      findsOneWidget,
    );
  });

  testWidgets('with nothing booked it says so in place, and the book button '
      'is still there', (tester) async {
    await open(tester);
    fakes.bookings.bookings.add([]);
    await tester.pumpAndSettle();
    expect(find.text(NannyBookingCopy.noBookingsTitle), findsOneWidget);
    expect(find.text(NannyBookingCopy.book), findsOneWidget);
  });

  testWidgets('booking through the sheet sends the household’s wall clock as '
      'instants; an end before the start is the next morning', (tester) async {
    await open(tester);
    fakes.bookings.bookings.add([]);
    await tester.pumpAndSettle();

    await tester.tap(find.text(NannyBookingCopy.book));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(NannyFixtures.nomsa.displayName),
      ),
    );
    await tester.pumpAndSettle();
    // The end: from 22:00 to 16:00, in the picker's typing mode.
    await tester.tap(find.text(NannyBookingCopy.endsAt('22:00')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '4');
    await tester.enterText(fields.at(1), '00');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text(NannyBookingCopy.endsNextDay), findsOneWidget);

    await tester.ensureVisible(find.text(NannyBookingCopy.confirmBook));
    await tester.tap(find.text(NannyBookingCopy.confirmBook));
    await tester.pumpAndSettle();

    final today = clock().today;
    final booked = fakes.bookings.booked.single;
    expect(booked.carerMemberId, NannyFixtures.nomsaMemberId);
    expect(booked.startsAt, clock().instantAt(today, hour: 17, minute: 30));
    expect(
      booked.endsAt,
      clock().instantAt(today.addDays(1), hour: 16, minute: 0),
    );
    expect(booked.startsAt.isUtc, isTrue);
    expect(booked.createdBy, Fixtures.samMemberId);
  });

  testWidgets('family sees whose each shift is, and cancelling asks first', (
    tester,
  ) async {
    final booking = AccessFixtures.booking(
      now: DateTime.now(),
      from: const Duration(days: 1),
      note: 'School run first',
    );
    await open(tester);
    fakes.bookings.bookings.add([booking]);
    await tester.pumpAndSettle();

    expect(find.textContaining(clock().bookingOf(booking)), findsOneWidget);
    expect(find.textContaining('School run first'), findsOneWidget);
    await tester.tap(find.byTooltip(NannyBookingCopy.cancel));
    await tester.pumpAndSettle();
    expect(find.text(NannyBookingCopy.cancelConfirm), findsOneWidget);
    await tester.tap(find.text(NannyBookingCopy.keep));
    await tester.pumpAndSettle();
    expect(fakes.bookings.cancelled, isEmpty);

    await tester.tap(find.byTooltip(NannyBookingCopy.cancel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(NannyBookingCopy.cancelAction));
    await tester.pumpAndSettle();
    expect(fakes.bookings.cancelled, [booking.id]);
  });

  testWidgets('a shift under way is marked as on now', (tester) async {
    await open(tester);
    fakes.bookings.bookings.add([
      AccessFixtures.booking(
        now: DateTime.now(),
        from: const Duration(hours: -1),
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.text(NannyBookingCopy.onNow), findsOneWidget);
  });

  testWidgets('a carer sees only their own shifts, and cannot book or '
      'cancel', (tester) async {
    final booking = AccessFixtures.booking(
      now: DateTime.now(),
      from: const Duration(days: 1),
    );
    await open(tester, view: NannyFixtures.carerView());
    fakes.bookings.bookings.add([booking]);
    await tester.pumpAndSettle();

    expect(fakes.bookings.askedForCarer, NannyFixtures.nomsaMemberId);
    expect(find.text(NannyBookingCopy.yourShifts), findsOneWidget);
    expect(find.text(clock().bookingOf(booking)), findsOneWidget);
    expect(find.text(NannyBookingCopy.book), findsNothing);
    expect(find.byTooltip(NannyBookingCopy.cancel), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('a carer with nothing booked is told a parent books them', (
    tester,
  ) async {
    await open(tester, view: NannyFixtures.carerView());
    fakes.bookings.bookings.add([]);
    await tester.pumpAndSettle();
    expect(find.text(NannyBookingCopy.yourShiftsEmpty), findsOneWidget);
  });

  testWidgets('loading holds the screen, a failure offers to try again', (
    tester,
  ) async {
    await open(tester);
    expect(find.text(NannyBookingCopy.noBookingsTitle), findsNothing);
    fakes.bookings.bookings.addError(const UnavailableFailure());
    await tester.pumpAndSettle();
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    await tester.tap(find.text(AppCopy.retry));
    // A real turn for the cancel inside retry, then it listens again.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    fakes.bookings.bookings.add([]);
    await tester.pumpAndSettle();
    expect(find.text(NannyBookingCopy.noBookingsTitle), findsOneWidget);
  });

  testWidgets('a refused booking is said in the banner', (tester) async {
    fakes.bookings.failWritesWith = const PermissionDeniedFailure();
    final booking = AccessFixtures.booking(
      now: DateTime.now(),
      from: const Duration(days: 1),
    );
    await open(tester);
    fakes.bookings.bookings.add([booking]);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(NannyBookingCopy.cancel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(NannyBookingCopy.cancelAction));
    await tester.pumpAndSettle();
    expect(
      find.text(AppCopy.failure(const PermissionDeniedFailure())),
      findsOneWidget,
    );
  });

  testWidgets('holds at 360 wide, in dark, at 200% text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await open(tester, brightness: Brightness.dark, textScale: 2);
    fakes.bookings.bookings.add([
      AccessFixtures.booking(
        now: DateTime.now(),
        from: const Duration(days: 1),
        note: 'School pick-up at 14:30, then home',
      ),
    ]);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byTooltip(NannyBookingCopy.cancel));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a carer’s list holds at 360 wide, in dark, at 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await open(
      tester,
      view: NannyFixtures.carerView(),
      brightness: Brightness.dark,
      textScale: 2,
    );
    fakes.bookings.bookings.add([
      AccessFixtures.booking(
        now: DateTime.now(),
        from: const Duration(days: 1),
      ),
    ]);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
