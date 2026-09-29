import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/nanny_hub/model/handover_kind.dart';
import 'package:nestprep/features/nanny_hub/ui/emergency_screen.dart';
import 'package:nestprep/features/nanny_hub/ui/shift_screen.dart';
import 'package:nestprep/features/nanny_hub/ui/shift_summary_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/nanny_fixtures.dart';
import '../../../support/pump_nanny_hub.dart';

/// Lands on a pushed screen whose own reads have not answered yet — its
/// loading placeholder shimmers, so it never settles.
Future<void> pushed(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  late NannyFakes fakes;

  setUp(() => fakes = NannyFakes());
  tearDown(() => fakes.close());

  group('the hub’s four states', () {
    testWidgets('holds its layout while it loads', (tester) async {
      await pumpNannyHub(tester, fakes);
      await tester.pump();
      expect(find.text(NannyCopy.title), findsOneWidget);
      expect(find.text(NannyCopy.children), findsNothing);
    });

    testWidgets('waits for every read, not just the first', (tester) async {
      await pumpNannyHub(tester, fakes);
      fakes.hub.emitAll();
      await tester.pump();
      expect(find.text(NannyCopy.children), findsNothing);
      fakes.shifts.openShifts.add(const []);
      fakes.shifts.summaries.add(const []);
      await tester.pumpAndSettle();
      expect(find.text(NannyCopy.children), findsOneWidget);
    });

    testWidgets('says what went wrong in words, with a retry', (tester) async {
      await pumpNannyHub(tester, fakes);
      fakes.hub.guide.addError(const UnavailableFailure());
      await tester.pumpAndSettle();
      expect(
        find.text(AppCopy.failure(const UnavailableFailure())),
        findsOneWidget,
      );
      await tester.tap(find.text(AppCopy.retry));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      fakes.answerAFullHub();
      await tester.pumpAndSettle();
      expect(find.text('Kid Parker'), findsOneWidget);
    });

    testWidgets('an empty hub says how to fill each part, in place', (
      tester,
    ) async {
      await pumpNannyHub(tester, fakes, view: NannyFixtures.parentView());
      fakes.answerEverything();
      await tester.pumpAndSettle();
      // Kid is a kid profile, so has a card even before anything is written.
      expect(find.text('Kid Parker'), findsOneWidget);
      expect(find.text(NannyCopy.emergencyBody(0)), findsOneWidget);
      await tester.scrollUntilVisible(find.text(NannyCopy.noPastShifts), 200);
      expect(find.text(NannyCopy.noPastShifts), findsOneWidget);
    });
  });

  group('a carer on the carer defaults', () {
    testWidgets('starts their shift in one tap and lands in shift mode', (
      tester,
    ) async {
      await pumpNannyHub(tester, fakes, view: NannyFixtures.carerView());
      fakes.answerAFullHub();
      await tester.pumpAndSettle();
      expect(find.text(NannyCopy.readyTitle), findsOneWidget);

      await tester.tap(find.text(NannyCopy.startMyShift));
      await pushed(tester);

      expect(fakes.shifts.writes.single.$1, 'startShift');
      expect(fakes.shifts.writes.single.$2, {
        'carerMemberId': NannyFixtures.nomsaMemberId,
        'startedBy': NannyFixtures.nomsaMemberId,
      });
      expect(find.byType(ShiftScreen), findsOneWidget);
    });

    testWidgets('on shift already, goes back to it rather than starting '
        'another', (tester) async {
      await pumpNannyHub(tester, fakes, view: NannyFixtures.carerView());
      fakes.answerAFullHub(openShifts: [NannyFixtures.openShift]);
      await tester.pumpAndSettle();
      expect(find.text(NannyCopy.onShiftTitle), findsOneWidget);
      expect(find.text(NannyCopy.startMyShift), findsNothing);
      await tester.tap(find.text(NannyCopy.openShiftMode));
      await pushed(tester);
      expect(find.byType(ShiftScreen), findsOneWidget);
    });

    testWidgets('sees a severe allergy on the child before opening the card', (
      tester,
    ) async {
      await pumpNannyHub(tester, fakes, view: NannyFixtures.carerView());
      fakes.answerAFullHub();
      await tester.pumpAndSettle();
      expect(find.text('Peanuts'), findsOneWidget);
    });

    testWidgets('is told allergies are not shared, never shown nothing', (
      tester,
    ) async {
      await pumpNannyHub(
        tester,
        fakes,
        view: NannyFixtures.carerWithoutProfilesView(),
      );
      fakes.answerAFullHub();
      await tester.pumpAndSettle();
      expect(find.text(NannyCopy.allergiesHiddenTitle), findsOneWidget);
      expect(find.text('Peanuts'), findsNothing);
    });
  });

  testWidgets('a carer a parent narrowed to view reads, and is told why '
      'they cannot start a shift', (tester) async {
    await pumpNannyHub(tester, fakes, view: NannyFixtures.lookOnlyCarerView());
    fakes.answerAFullHub();
    await tester.pumpAndSettle();
    expect(find.text(NannyCopy.startMyShift), findsNothing);
    expect(find.text(NannyCopy.nobodyOnShift), findsOneWidget);
    await tester.scrollUntilVisible(find.text(NannyCopy.viewOnlyNote), 200);
    expect(find.text(NannyCopy.viewOnlyNote), findsOneWidget);
  });

  group('a parent', () {
    testWidgets('sees who is on shift, and opens it', (tester) async {
      await pumpNannyHub(tester, fakes);
      fakes.answerAFullHub(openShifts: [NannyFixtures.openShift]);
      await tester.pumpAndSettle();
      expect(
        find.text(NannyCopy.onShiftSince('Nomsa Carer', '14:05')),
        findsOneWidget,
      );
      await tester.tap(
        find.text(NannyCopy.onShiftSince('Nomsa Carer', '14:05')),
      );
      await pushed(tester);
      expect(find.byType(ShiftScreen), findsOneWidget);
    });

    testWidgets('starts a shift for the carer, who may not have their phone', (
      tester,
    ) async {
      await pumpNannyHub(tester, fakes);
      fakes.answerAFullHub();
      await tester.pumpAndSettle();
      await tester.tap(find.text(NannyCopy.startShiftFor));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nomsa Carer').last);
      await pushed(tester);
      expect(fakes.shifts.writes.single.$2, {
        'carerMemberId': NannyFixtures.nomsaMemberId,
        'startedBy': Fixtures.samMemberId,
      });
    });

    testWidgets('reads the latest handover first, and opens it', (
      tester,
    ) async {
      await pumpNannyHub(tester, fakes);
      fakes.answerAFullHub();
      await tester.pumpAndSettle();
      expect(find.text(NannyCopy.latestHandover), findsOneWidget);
      expect(
        find.text(NannyShiftCopy.summaryCount(HandoverKind.incident, 1)),
        findsOneWidget,
      );
      await tester.tap(find.text(NannyCopy.latestHandover));
      await tester.pumpAndSettle();
      expect(find.byType(ShiftSummaryScreen), findsOneWidget);
    });

    testWidgets('a refused start is a sentence, not a crash', (tester) async {
      await pumpNannyHub(tester, fakes);
      fakes.answerAFullHub();
      await tester.pumpAndSettle();
      fakes.shifts.failWritesWith = const PermissionDeniedFailure();
      await tester.tap(find.text(NannyCopy.startMyShift));
      await tester.pumpAndSettle();
      expect(
        find.text(AppCopy.failure(const PermissionDeniedFailure())),
        findsOneWidget,
      );
      expect(find.byType(ShiftScreen), findsNothing);
    });
  });

  testWidgets('the emergency sheet is one tap from the header', (tester) async {
    await pumpNannyHub(tester, fakes, view: NannyFixtures.carerView());
    fakes.answerAFullHub();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(NannyShiftCopy.openEmergency));
    await tester.pumpAndSettle();
    expect(find.byType(EmergencyScreen), findsOneWidget);
  });

  testWidgets('holds at 360 wide, in dark, at 200% text', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpNannyHub(
      tester,
      fakes,
      view: NannyFixtures.carerView(),
      brightness: Brightness.dark,
      textScale: 2,
    );
    fakes.answerAFullHub(openShifts: [NannyFixtures.openShift]);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(NannyCopy.pastShifts), 300);
    expect(tester.takeException(), isNull);
  });
}
