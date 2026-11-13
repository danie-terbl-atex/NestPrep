import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/home_care_route.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/home_care/model/shift/helper_shift.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/home_care_fixtures.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_home_care.dart';

/// A helper's clock through the real routes (home-care ADR-0007): the card
/// on her front door, and the shifts screen a parent ends a forgotten one
/// from. The fixture household is on Johannesburg time, two hours ahead.
void main() {
  late HomeCareHarness harness;
  final shiftsPath = HomeCareRoute.shiftsPathFor(Fixtures.householdId);

  setUp(() => harness = HomeCareHarness());
  tearDown(() => harness.close());

  HelperShift shift({
    String id = 'shift-1',
    bool isOpen = true,
    String via = HelperShift.app,
  }) => HelperShift(
    id: id,
    helperId: Fixtures.thandiMemberId,
    startedBy: Fixtures.thandiMemberId,
    startedAt: DateTime.utc(2026, 11, 12, 5, 30),
    startedVia: via,
    endedAt: isOpen ? null : DateTime.utc(2026, 11, 12, 14, 5),
    endedBy: isOpen ? null : Fixtures.thandiMemberId,
    endedVia: isOpen ? null : via,
    status: isOpen ? HelperShift.open : HelperShift.ended,
  );

  Future<void> openFrontDoor(
    WidgetTester tester, {
    bool asHelper = true,
  }) async {
    HomeCareHarness.makeRoom(tester);
    await harness.pump(
      tester,
      view: asHelper ? HomeCareFixtures.helperView() : null,
    );
    await harness.emit(tester);
  }

  NestButton button(WidgetTester tester, String label) =>
      tester.widget<NestButton>(find.widgetWithText(NestButton, label));

  group('the helper’s front door', () {
    testWidgets('offers Start shift once the shifts are read, and clocks in', (
      tester,
    ) async {
      await openFrontDoor(tester);
      expect(find.text(HomeCareShiftCopy.readyTitle), findsOneWidget);
      expect(button(tester, HomeCareShiftCopy.startShift).onPressed, isNull);

      await harness.emitShifts(tester, const []);
      await tester.tap(find.text(HomeCareShiftCopy.startShift));
      await tester.pumpAndSettle();
      expect(harness.shifts.writes.single.$1, 'startShift');
      expect(harness.shifts.writes.single.$2, {
        'helperId': Fixtures.thandiMemberId,
        'by': Fixtures.thandiMemberId,
      });
    });

    testWidgets('on shift: since when, on the household’s clock, and End shift '
        'asks first', (tester) async {
      await openFrontDoor(tester);
      await harness.emitShifts(tester, [shift()]);
      expect(find.text(HomeCareShiftCopy.onShiftTitle), findsOneWidget);
      expect(find.text(HomeCareShiftCopy.since('07:30')), findsOneWidget);
      expect(find.text(HomeCareShiftCopy.startShift), findsNothing);

      await tester.tap(find.text(HomeCareShiftCopy.endShift));
      await tester.pumpAndSettle();
      expect(find.text(HomeCareShiftCopy.endBody('07:30')), findsOneWidget);
      await tester.tap(find.text(HomeCareShiftCopy.cancel));
      await tester.pumpAndSettle();
      expect(harness.shifts.writes, isEmpty);

      await tester.tap(find.text(HomeCareShiftCopy.endShift));
      await tester.pumpAndSettle();
      await tester.tap(find.text(HomeCareShiftCopy.endShift).last);
      await tester.pumpAndSettle();
      expect(harness.shifts.writes.single.$1, 'endShift');
      expect(harness.shifts.writes.single.$2, {
        'shiftId': 'shift-1',
        'by': Fixtures.thandiMemberId,
      });
    });

    testWidgets('a refused start is said in words', (tester) async {
      await openFrontDoor(tester);
      await harness.emitShifts(tester, const []);
      harness.shifts.failWritesWith = const PermissionDeniedFailure();
      await tester.tap(find.text(HomeCareShiftCopy.startShift));
      await tester.pumpAndSettle();
      expect(
        find.text(AppCopy.failure(const PermissionDeniedFailure())),
        findsOneWidget,
      );
    });

    testWidgets('a parent has no clock of their own, only the way in', (
      tester,
    ) async {
      await openFrontDoor(tester, asHelper: false);
      await harness.emitShifts(tester, const []);
      expect(find.text(HomeCareShiftCopy.startShift), findsNothing);
      await tester.tap(find.text(HomeCareShiftCopy.shifts));
      await tester.pumpAndSettle();
      expect(find.text(HomeCareShiftCopy.emptyTitle), findsOneWidget);
      expect(find.text(HomeCareShiftCopy.emptyBody), findsOneWidget);
    });

    testWidgets('nothing of it shows, and nothing is read, switched off', (
      tester,
    ) async {
      harness.flagsDefaultOn = false;
      await openFrontDoor(tester);
      expect(find.text(HomeCareShiftCopy.readyTitle), findsNothing);
      expect(find.text(HomeCareShiftCopy.shifts), findsNothing);
      expect(harness.shifts.shiftsAskedFor, isEmpty);
    });
  });

  group('the shifts screen', () {
    testWidgets('a parent sees who is on, the past with its length, and ends '
        'a forgotten shift in their own name', (tester) async {
      HomeCareHarness.makeRoom(tester);
      await harness.pump(tester, location: shiftsPath);
      await harness.feedShell(tester);
      await harness.emitShifts(tester, [
        shift(via: HelperShift.frame),
        shift(id: 'shift-0', isOpen: false),
      ]);
      expect(find.text(HomeCareShiftCopy.onNow), findsOneWidget);
      expect(find.text(HomeCareShiftCopy.since('07:30')), findsOneWidget);
      expect(find.text(HomeCareShiftCopy.atTheFrame), findsOneWidget);
      expect(find.text(HomeCareShiftCopy.past), findsOneWidget);
      expect(find.textContaining('07:30 – 16:05'), findsOneWidget);
      expect(find.text('8 h 35 min'), findsOneWidget);

      await tester.tap(find.text(HomeCareShiftCopy.endShift));
      await tester.pumpAndSettle();
      expect(
        find.text(HomeCareShiftCopy.endForTitle('Thandi Helper')),
        findsOneWidget,
      );
      await tester.tap(find.text(HomeCareShiftCopy.endShift).last);
      await tester.pumpAndSettle();
      expect(harness.shifts.writes.single.$1, 'endShift');
      expect(harness.shifts.writes.single.$2, {
        'shiftId': 'shift-1',
        'by': Fixtures.samMemberId,
      });
    });

    testWidgets('a helper sees her own, with her own words when empty', (
      tester,
    ) async {
      HomeCareHarness.makeRoom(tester);
      await harness.pump(
        tester,
        location: shiftsPath,
        view: HomeCareFixtures.helperView(),
      );
      await harness.feedShell(tester);
      await harness.emitShifts(tester, const []);
      expect(harness.shifts.shiftsAskedFor, [Fixtures.thandiMemberId]);
      expect(find.text(HomeCareShiftCopy.emptyHelperBody), findsOneWidget);
    });

    testWidgets('says it is not switched on when reached by a link', (
      tester,
    ) async {
      harness.flagsDefaultOn = false;
      await harness.pump(tester, location: shiftsPath);
      await harness.feedShell(tester);
      await tester.pumpAndSettle();
      expect(find.text(HomeCareCopy.switchedOffTitle), findsOneWidget);
    });

    for (final asHelper in [true, false]) {
      testWidgets('holds in dark at 200% text on a 360-wide phone '
          '(${asHelper ? 'helper' : 'parent'})', (tester) async {
        tester.view.physicalSize = const Size(360 * 3, 800 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        for (final location in [
          shiftsPath,
          HomeCareRoute.pathFor(Fixtures.householdId),
        ]) {
          final held = HomeCareHarness();
          addTearDown(held.close);
          await held.pump(
            tester,
            location: location,
            view: asHelper ? HomeCareFixtures.helperView() : null,
            brightness: Brightness.dark,
            textScale: 2,
          );
          await held.feedShell(tester);
          await held.emitShifts(tester, [
            shift(via: HelperShift.frame),
            shift(id: 'shift-0', isOpen: false, via: HelperShift.frame),
          ]);
          expect(tester.takeException(), isNull);
        }
      });
    }
  });
}
