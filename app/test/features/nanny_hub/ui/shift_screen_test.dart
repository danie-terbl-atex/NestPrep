import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nestprep/app/nanny_hub_route.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/nanny_hub/data/photo_picker.dart';
import 'package:nestprep/features/nanny_hub/model/handover_draft.dart';
import 'package:nestprep/features/nanny_hub/model/handover_entry.dart';
import 'package:nestprep/features/nanny_hub/model/handover_kind.dart';
import 'package:nestprep/features/nanny_hub/model/handover_mood.dart';
import 'package:nestprep/features/nanny_hub/model/shift.dart';
import 'package:nestprep/features/nanny_hub/ui/shift_summary_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/nanny_fixtures.dart';
import '../../../support/pump_nanny_hub.dart';
import '../../../support/pump_until.dart';

void main() {
  late NannyFakes fakes;

  setUp(() => fakes = NannyFakes());
  tearDown(() => fakes.close());

  Future<void> open(
    WidgetTester tester, {
    HouseholdView? view,
    Shift? shift,
    List<HandoverEntry>? entries,
    Brightness brightness = Brightness.light,
    double textScale = 1,
    bool tall = true,
  }) async {
    if (tall) {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    await pumpNannyHub(
      tester,
      fakes,
      location: NannyHubRoute.shiftPathFor(Fixtures.householdId, 'shift-1'),
      view: view ?? NannyFixtures.carerView(),
      brightness: brightness,
      textScale: textScale,
    );
    fakes.answerAFullHub(openShifts: [NannyFixtures.openShift]);
    fakes.shifts.shift.add(shift ?? NannyFixtures.openShift);
    fakes.shifts.entries.add(entries ?? [NannyFixtures.tea]);
    await tester.pumpAndSettle();
  }

  testWidgets('holds its layout while the shift loads', (tester) async {
    await pumpNannyHub(
      tester,
      fakes,
      location: NannyHubRoute.shiftPathFor(Fixtures.householdId, 'shift-1'),
      view: NannyFixtures.carerView(),
    );
    await tester.pump();
    expect(find.text(NannyShiftCopy.shiftTitle), findsOneWidget);
    expect(find.text(NannyShiftCopy.logSomething), findsNothing);
  });

  testWidgets('a failed read is words and a retry', (tester) async {
    await pumpNannyHub(
      tester,
      fakes,
      location: NannyHubRoute.shiftPathFor(Fixtures.householdId, 'shift-1'),
      view: NannyFixtures.carerView(),
    );
    fakes.answerAFullHub();
    fakes.shifts.entries.addError(const UnavailableFailure());
    await tester.pumpAndSettle();
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    expect(find.text(AppCopy.retry), findsOneWidget);
  });

  testWidgets('a shift that is not there is said, not blank', (tester) async {
    await pumpNannyHub(
      tester,
      fakes,
      location: NannyHubRoute.shiftPathFor(Fixtures.householdId, 'shift-1'),
      view: NannyFixtures.carerView(),
    );
    fakes.answerAFullHub();
    fakes.shifts.shift.add(null);
    fakes.shifts.entries.add(const []);
    await tester.pumpAndSettle();
    expect(find.text(NannyShiftCopy.shiftGoneTitle), findsOneWidget);
  });

  testWidgets('shows who is on, the log so far and this part of the '
      'evening', (tester) async {
    await open(tester);
    expect(find.text('Nomsa Carer'), findsOneWidget);
    expect(find.text(NannyShiftCopy.shiftStarted('14:05')), findsOneWidget);
    expect(find.text('Ate all the pasta'), findsOneWidget);
    expect(
      find.text('15:05 · ${NannyShiftCopy.kindName(HandoverKind.meal)}'),
      findsOneWidget,
    );
    // Bedtime has one of two ticked, so it is the part that opens.
    expect(find.text(NannyShiftCopy.ticked(1, 2)), findsOneWidget);
  });

  testWidgets('an empty log says how to add to it', (tester) async {
    await open(tester, entries: const []);
    expect(find.text(NannyShiftCopy.logEmpty), findsOneWidget);
  });

  testWidgets('logging a mood is two taps and a save, for every child', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(
      find.bySemanticsLabel(NannyShiftCopy.logTitle(HandoverKind.mood)),
    );
    await tester.pumpAndSettle();
    expect(find.text(NannyShiftCopy.entryNeedsSomething), findsOneWidget);
    await tester.tap(find.text(NannyShiftCopy.moodName(HandoverMood.tired)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(NannyShiftCopy.logIt));
    await tester.pumpAndSettle();
    final (method, arguments) = fakes.shifts.writes.single;
    expect(method, 'addEntry');
    expect(arguments['byMemberId'], NannyFixtures.nomsaMemberId);
    final draft = arguments['draft']! as HandoverDraft;
    expect(draft.kind, HandoverKind.mood);
    expect(draft.mood, HandoverMood.tired);
    expect(draft.childIds, [Fixtures.kidMemberId]);
    expect(draft.photoId, isNull);
  });

  testWidgets('a meal logged with a photo stores the photo — compressed, '
      'as a JPEG — before the entry that points at it', (tester) async {
    fakes.picker.next = Uint8List.fromList(
      img.encodeJpg(img.Image(width: 40, height: 30)),
    );
    await open(tester);
    await tester.tap(
      find.bySemanticsLabel(NannyShiftCopy.logTitle(HandoverKind.meal)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(NannyCopy.takePhoto));
    await tester.pumpAndSettle();
    await tester.tap(find.text(NannyShiftCopy.logIt));
    // Compression runs in a background isolate, which only real time moves.
    await pumpUntil(
      tester,
      () => fakes.shifts.writes.isNotEmpty,
      reason: 'the photo was never compressed and logged',
    );

    expect(fakes.picker.asked, [PhotoSource.camera]);
    final draft = fakes.shifts.writes.single.$2['draft']! as HandoverDraft;
    final stored = fakes.photos.objects[draft.photoId]!;
    expect(stored.sublist(0, 2), [0xFF, 0xD8]);
    expect(fakes.documents.syncCount, 1);
  });

  testWidgets('an incident warns to call for help first', (tester) async {
    await open(tester);
    await tester.tap(
      find.bySemanticsLabel(NannyShiftCopy.logTitle(HandoverKind.incident)),
    );
    await tester.pumpAndSettle();
    expect(find.text(NannyShiftCopy.incidentWarning), findsOneWidget);
  });

  testWidgets('ticks a checklist item on this shift only', (tester) async {
    await open(tester);
    await tester.tap(find.text('One story'));
    await tester.pumpAndSettle();
    final (method, arguments) = fakes.shifts.writes.single;
    expect(method, 'setTick');
    expect(arguments, {'tickKey': 'bedtime:story', 'isTicked': true});
  });

  testWidgets('the carer changes their own entry', (tester) async {
    await open(tester);
    await tester.tap(find.text('Ate all the pasta'));
    await tester.pumpAndSettle();
    await tester.enterText(
      fieldLabelled(NannyShiftCopy.note),
      'Ate all the pasta and the peas',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(NannyShiftCopy.logIt));
    await tester.pumpAndSettle();
    final (method, arguments) = fakes.shifts.writes.single;
    expect(method, 'updateEntry');
    expect(arguments['entryId'], 'e-tea');
  });

  testWidgets('a parent watching the shift cannot change the carer’s entry', (
    tester,
  ) async {
    await open(tester, view: NannyFixtures.parentView());
    await tester.tap(find.text('Ate all the pasta'));
    await tester.pumpAndSettle();
    expect(find.text(NannyShiftCopy.logTitle(HandoverKind.meal)), findsNothing);
    // …but may end it for them.
    expect(find.text(NannyShiftCopy.endShift), findsOneWidget);
  });

  testWidgets('ending asks first, then lands on the summary', (tester) async {
    await open(tester);
    await tester.tap(find.text(NannyShiftCopy.endShift));
    await tester.pumpAndSettle();
    expect(find.text(NannyShiftCopy.endShiftTitle), findsOneWidget);
    await tester.enterText(
      fieldLabelled(NannyShiftCopy.closingNote),
      ' Asleep by eight. ',
    );
    await tester.tap(find.text(NannyShiftCopy.endShift).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(fakes.directory.ended.single, (
      shiftId: 'shift-1',
      closingNote: 'Asleep by eight.',
    ));
    expect(find.byType(ShiftSummaryScreen), findsOneWidget);
  });

  testWidgets('a second tap on end while the first is on its way does '
      'nothing', (tester) async {
    fakes.directory.gate = Completer<void>();
    await open(tester);
    await tester.tap(find.text(NannyShiftCopy.endShift));
    await tester.pumpAndSettle();
    await tester.tap(find.text(NannyShiftCopy.endShift).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // The button waits while the first end is in flight.
    await tester.tap(find.text(NannyShiftCopy.endShift), warnIfMissed: false);
    await tester.pump();
    expect(find.text(NannyShiftCopy.endShiftTitle), findsNothing);
    fakes.directory.gate!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(fakes.directory.ended, hasLength(1));
  });

  testWidgets('a refused end stays on the shift and says why', (tester) async {
    fakes.directory.failWith = const NannyHubFailure(
      NannyHubProblem.shiftAlreadyEnded,
    );
    await open(tester);
    await tester.tap(find.text(NannyShiftCopy.endShift));
    await tester.pumpAndSettle();
    await tester.tap(find.text(NannyShiftCopy.endShift).last);
    await tester.pumpAndSettle();
    expect(
      find.text(
        AppCopy.failure(
          const NannyHubFailure(NannyHubProblem.shiftAlreadyEnded),
        ),
      ),
      findsOneWidget,
    );
    expect(find.byType(ShiftSummaryScreen), findsNothing);
  });

  testWidgets('an ended shift offers its summary and takes no more', (
    tester,
  ) async {
    await open(
      tester,
      shift: NannyFixtures.openShift.copyWith(status: Shift.ended),
    );
    expect(find.text(NannyShiftCopy.shiftEndedTitle), findsOneWidget);
    expect(find.text(NannyShiftCopy.logSomething), findsNothing);
    expect(find.text(NannyShiftCopy.endShift), findsNothing);
  });

  testWidgets('a carer at view watches and logs nothing', (tester) async {
    await open(tester, view: NannyFixtures.lookOnlyCarerView());
    expect(find.text(NannyShiftCopy.logSomething), findsNothing);
    expect(find.text(NannyShiftCopy.endShift), findsNothing);
    // The checklist is there to read, and a tap on it ticks nothing.
    await tester.tap(find.text('One story'));
    await tester.pumpAndSettle();
    expect(fakes.shifts.writes, isEmpty);
  });

  testWidgets('holds at 360 wide, in dark, at 200% text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await open(tester, brightness: Brightness.dark, textScale: 2, tall: false);
    await scrollTo(tester, find.text(NannyShiftCopy.endShift));
    expect(tester.takeException(), isNull);
  });
}
