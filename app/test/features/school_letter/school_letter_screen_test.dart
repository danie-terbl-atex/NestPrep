import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/school_letter/model/letter_reading.dart';
import 'package:nestprep/features/school_letter/state/school_letter_controller.dart';
import 'package:nestprep/features/school_letter/ui/school_letter_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../support/fake_calendar_repository.dart';
import '../../support/fake_calendar_v2.dart';
import '../../support/pump_screen.dart';

/// Snap a school letter, as the parent sees it (calendar ADR-0005): every
/// step drawn — choosing, reading, the review, an empty letter, a failure,
/// done — and nothing on the calendar until the add button says so.
void main() {
  late FakeSchoolLetterReader reader;
  late FakeLetterPicker picker;
  late FakeCalendarRepository calendar;

  setUp(() {
    reader = FakeSchoolLetterReader()
      ..reading = LetterReading(proposals: twoProposals(), callsLeft: 6);
    picker = FakeLetterPicker();
    calendar = FakeCalendarRepository();
  });

  tearDown(() => calendar.close());

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    await pumpScreen(
      tester,
      const SchoolLetterScreen(),
      brightness: brightness,
      textScale: textScale,
      providers: [
        ChangeNotifierProvider(
          create: (_) => SchoolLetterController(
            schoolLetterReader: reader,
            letterPicker: picker,
            calendarRepository: calendar,
            householdId: 'h1',
            memberId: 'm-sam',
          ),
        ),
      ],
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    // A lazy list builds only near the screen; at 200% text the buttons can
    // be further down than that.
    if (find.text(text).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        find.text(text),
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    // Centred, because the header sits over the top of the list.
    await Scrollable.ensureVisible(
      tester.element(find.text(text).last),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the three ways in, and says what leaves the phone', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text(SchoolLetterCopy.heroTitle), findsOneWidget);
    expect(find.text(SchoolLetterCopy.takePhoto), findsOneWidget);
    expect(find.text(SchoolLetterCopy.choosePhoto), findsOneWidget);
    expect(find.text(SchoolLetterCopy.choosePdf), findsOneWidget);
    expect(find.text(SchoolLetterCopy.privacyBody), findsOneWidget);
  });

  testWidgets('says it is reading while the model has the letter', (
    tester,
  ) async {
    reader.gate = Completer<void>();
    await pump(tester);
    await tester.tap(find.text(SchoolLetterCopy.takePhoto));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(SchoolLetterCopy.readingTitle), findsOneWidget);
    reader.complete();
    await tester.pumpAndSettle();
    expect(find.text(SchoolLetterCopy.found(2)), findsOneWidget);
  });

  testWidgets('shows what was found, all ticked, and adds only what stays '
      'ticked', (tester) async {
    await pump(tester);
    await tap(tester, SchoolLetterCopy.choosePdf);
    expect(find.text('Grade 3 zoo outing'), findsOneWidget);
    expect(find.text('Civvies day'), findsOneWidget);
    expect(find.text('Bring a hat'), findsOneWidget);
    expect(find.text(AiCopy.callsLeft(6)), findsOneWidget);
    expect(find.text(SchoolLetterCopy.addTicked(2)), findsOneWidget);
    expect(calendar.savedEvents, isEmpty);

    await tap(tester, 'Civvies day');
    expect(find.text(SchoolLetterCopy.addTicked(1)), findsOneWidget);
    await tap(tester, SchoolLetterCopy.addTicked(1));

    expect(calendar.savedEvents.map((event) => event.title), [
      'Grade 3 zoo outing',
    ]);
    expect(find.text(SchoolLetterCopy.addedTitle(1)), findsOneWidget);
    await tap(tester, SchoolLetterCopy.snapAnother);
    expect(find.text(SchoolLetterCopy.heroTitle), findsOneWidget);
  });

  testWidgets('Change opens the event sheet with the proposal filled in', (
    tester,
  ) async {
    // A phone's height, so the sheet's Save is on the screen (the vault
    // lesson on taps below the fold of a sheet).
    tester.view.physicalSize = const Size(400 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pump(tester);
    await tap(tester, SchoolLetterCopy.takePhoto);
    await tap(tester, SchoolLetterCopy.edit);
    expect(find.text(AppCopy.calendarAddEvent), findsOneWidget);
    // The last Change is the last proposal's: civvies day.
    final titleField = find.byWidgetPredicate(
      (widget) =>
          widget is EditableText && widget.controller.text == 'Civvies day',
    );
    expect(titleField, findsOneWidget);
    await tester.enterText(titleField, 'Civvies day, bring R10');
    await tap(tester, AppCopy.householdSave);
    expect(find.text('Civvies day, bring R10'), findsOneWidget);
    expect(find.text('Civvies day'), findsNothing);
    expect(calendar.savedEvents, isEmpty, reason: 'changed, not added');
  });

  testWidgets('a letter with no dates says so in place, with the way on', (
    tester,
  ) async {
    reader.reading = const LetterReading(proposals: [], callsLeft: 5);
    await pump(tester);
    await tap(tester, SchoolLetterCopy.takePhoto);
    expect(find.text(SchoolLetterCopy.noneTitle), findsOneWidget);
    await tap(tester, SchoolLetterCopy.chooseAnother);
    expect(find.text(SchoolLetterCopy.heroTitle), findsOneWidget);
  });

  testWidgets('a spent month is said in words, with the way to try again', (
    tester,
  ) async {
    reader.failWith = const AiFailure(AiProblem.aiLimitReached);
    await pump(tester);
    await tap(tester, SchoolLetterCopy.takePhoto);
    expect(find.text(AiCopy.problem(AiProblem.aiLimitReached)), findsOneWidget);
    expect(find.text(SchoolLetterCopy.takePhoto), findsOneWidget);

    reader.failWith = null;
    await tap(tester, SchoolLetterCopy.tryAgain);
    expect(find.text(SchoolLetterCopy.found(2)), findsOneWidget);
  });

  testWidgets('events that could not be added stay, ticked, with the reason', (
    tester,
  ) async {
    calendar.refuseTitles.add('Civvies day');
    await pump(tester);
    await tap(tester, SchoolLetterCopy.takePhoto);
    await tap(tester, SchoolLetterCopy.addTicked(2));
    expect(
      find.text(SchoolLetterCopy.problem(SchoolLetterProblem.someNotAdded)),
      findsOneWidget,
    );
    expect(find.text('Civvies day'), findsOneWidget);
    expect(find.text(SchoolLetterCopy.addTicked(1)), findsOneWidget);
  });

  for (final step in ['choosing', 'review', 'done', 'failure']) {
    testWidgets('the $step step survives dark at 200% text on a 360-wide '
        'phone', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      if (step == 'failure') {
        reader.failWith = const AiFailure(AiProblem.aiUnavailable);
      }
      await pump(tester, brightness: Brightness.dark, textScale: 2);
      if (step != 'choosing') await tap(tester, SchoolLetterCopy.takePhoto);
      if (step == 'done') await tap(tester, SchoolLetterCopy.addTicked(2));
      expect(tester.takeException(), isNull);
    });
  }
}
