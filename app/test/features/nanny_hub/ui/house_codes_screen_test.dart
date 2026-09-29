import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

/// The house codes (nanny-hub ADR-0006): shut before a carer's booked shift,
/// open for it and its quarter-hour either side, shut after — and the screen
/// says which, never an empty list.
void main() {
  late NannyFakes fakes;
  // Made after the pump, which is what loads the timezone data.
  HouseholdClock clock() => HouseholdClock('Africa/Johannesburg');

  setUp(() {
    fakes = NannyFakes();
    fakes.codes.codes = const [AccessFixtures.alarm, AccessFixtures.gate];
  });
  tearDown(() => fakes.close());

  Future<void> open(
    WidgetTester tester, {
    HouseholdView? view,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    await pumpNannyHub(
      tester,
      fakes,
      location: NannyHubRoute.codesPathFor(Fixtures.householdId),
      view: view,
      brightness: brightness,
      textScale: textScale,
    );
    await tester.pump();
  }

  testWidgets('a carer on a booked shift sees the codes, large, and until '
      'when', (tester) async {
    final booking = AccessFixtures.booking(
      now: DateTime.now(),
      from: const Duration(hours: -1),
    );
    await open(tester, view: NannyFixtures.carerView());
    fakes.bookings.bookings.add([booking]);
    await tester.pumpAndSettle();

    expect(find.text('4821'), findsOneWidget);
    expect(find.text('1990#'), findsOneWidget);
    expect(
      find.text(
        NannyBookingCopy.codesOpenUntil(clock().timeOf(booking.closesAt)),
      ),
      findsOneWidget,
    );
    expect(find.text(NannyBookingCopy.addCode), findsNothing);
  });

  testWidgets('a carer off shift sees them shut, the next shift named, and '
      'never a code', (tester) async {
    final next = AccessFixtures.booking(
      now: DateTime.now(),
      from: const Duration(hours: 6),
    );
    await open(tester, view: NannyFixtures.carerView());
    fakes.bookings.bookings.add([next]);
    await tester.pumpAndSettle();

    expect(find.text(NannyBookingCopy.codesClosedTitle), findsOneWidget);
    expect(
      find.text(NannyBookingCopy.codesClosedNext(clock().bookingOf(next))),
      findsOneWidget,
    );
    expect(find.text('4821'), findsNothing);
    expect(fakes.codes.fetches, 0);
  });

  testWidgets('a carer with nothing booked is told to ask a parent', (
    tester,
  ) async {
    await open(tester, view: NannyFixtures.carerView());
    fakes.bookings.bookings.add([]);
    await tester.pumpAndSettle();
    expect(find.text(NannyBookingCopy.codesClosedNone), findsOneWidget);
  });

  testWidgets('loading holds the screen until the window is known', (
    tester,
  ) async {
    await open(tester, view: NannyFixtures.carerView());
    expect(find.text('4821'), findsNothing);
    expect(find.text(NannyBookingCopy.codesClosedTitle), findsNothing);
    fakes.bookings.bookings.add([]);
    await tester.pumpAndSettle();
  });

  testWidgets('no signal is said, and trying again reads them', (tester) async {
    fakes.codes.failFetchWith = const UnavailableFailure();
    await open(tester);
    await tester.pumpAndSettle();
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );

    fakes.codes.failFetchWith = null;
    await tester.tap(find.text(AppCopy.retry));
    await tester.pumpAndSettle();
    expect(find.text('4821'), findsOneWidget);
  });

  testWidgets('family sees every code and the note on who sees them when', (
    tester,
  ) async {
    await open(tester);
    await tester.pumpAndSettle();
    expect(find.text(NannyBookingCopy.codesFamilyNote), findsOneWidget);
    expect(find.text('4821'), findsOneWidget);
  });

  testWidgets('family with no codes is told what to add, beside the button', (
    tester,
  ) async {
    fakes.codes.codes = const [];
    await open(tester);
    await tester.pumpAndSettle();
    expect(find.text(NannyBookingCopy.noCodesTitle), findsOneWidget);
    expect(find.text(NannyBookingCopy.addCode), findsOneWidget);
  });

  testWidgets('family adds a code through the sheet', (tester) async {
    await open(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text(NannyBookingCopy.addCode));
    await tester.pumpAndSettle();
    await tester.enterText(fieldLabelled(NannyBookingCopy.codeLabel), 'Gate');
    await tester.enterText(fieldLabelled(NannyBookingCopy.codeValue), ' 2468 ');
    await tester.enterText(
      fieldLabelled(NannyBookingCopy.codeNote),
      'Keypad on the left',
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(NannyBookingCopy.saveCode));
    await tester.tap(find.text(NannyBookingCopy.saveCode));
    await tester.pumpAndSettle();

    expect(fakes.codes.writes, [
      ('add', (label: 'Gate', value: '2468', note: 'Keypad on the left')),
    ]);
    expect(fakes.codes.fetches, 2);
  });

  testWidgets('saving waits until both the name and the code are there', (
    tester,
  ) async {
    await open(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text(NannyBookingCopy.addCode));
    await tester.pumpAndSettle();
    await tester.enterText(fieldLabelled(NannyBookingCopy.codeLabel), 'Gate');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(NannyBookingCopy.saveCode));
    await tester.tap(find.text(NannyBookingCopy.saveCode));
    await tester.pumpAndSettle();
    expect(fakes.codes.writes, isEmpty);
  });

  testWidgets('family changes a code by tapping it, and removes one', (
    tester,
  ) async {
    await open(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('4821'));
    await tester.pumpAndSettle();
    await tester.enterText(fieldLabelled(NannyBookingCopy.codeValue), '9999');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(NannyBookingCopy.saveCode));
    await tester.tap(find.text(NannyBookingCopy.saveCode));
    await tester.pumpAndSettle();
    expect(fakes.codes.writes.single.$1, 'update:code-alarm');
    expect(fakes.codes.writes.single.$2?.value, '9999');

    await tester.tap(find.text('1990#'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(NannyBookingCopy.removeCode));
    await tester.tap(find.text(NannyBookingCopy.removeCode));
    await tester.pumpAndSettle();
    await tester.tap(find.text(NannyCopy.delete));
    await tester.pumpAndSettle();
    expect(fakes.codes.writes.last, ('remove:code-gate', null));
  });

  testWidgets('a refused change is said in the banner', (tester) async {
    await open(tester);
    await tester.pumpAndSettle();
    fakes.codes.failWritesWith = const PermissionDeniedFailure();
    await tester.tap(find.text('4821'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(NannyBookingCopy.saveCode));
    await tester.tap(find.text(NannyBookingCopy.saveCode));
    await tester.pumpAndSettle();
    expect(
      find.text(AppCopy.failure(const PermissionDeniedFailure())),
      findsOneWidget,
    );
  });

  testWidgets('holds at 360 wide, in dark, at 200% text — open and shut', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await open(tester, brightness: Brightness.dark, textScale: 2);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('1990#'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the shut card holds at 360 wide, in dark, at 200% text', (
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
    await scrollTo(tester, find.text(NannyBookingCopy.codesNeedSignal));
    expect(tester.takeException(), isNull);
  });
}
