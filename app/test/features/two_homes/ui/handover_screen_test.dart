import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/two_homes/model/custody_side.dart';
import 'package:nestprep/features/two_homes/model/handover_note.dart';
import 'package:nestprep/features/two_homes/state/handover_controller.dart';
import 'package:nestprep/features/two_homes/ui/handover_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_two_homes.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_two_homes.dart';
import '../../../support/two_homes_model_fixtures.dart';

/// One handover (household ADR-0004): who goes where, what is in the bag, and
/// the notes both homes read — saved to both at once by family, read by
/// anybody else whose grant reaches it.
void main() {
  late FakeTwoHomesRepository repository;
  late FakeTwoHomesDirectory directory;
  final friday = CalendarDate(2026, 10, 2);

  setUp(() {
    repository = FakeTwoHomesRepository();
    directory = FakeTwoHomesDirectory();
  });

  tearDown(() => repository.close());

  /// Scrolls the form's own list — not a multi-line field's scroll inside
  /// it — until all of [finder] is on screen: a tap on the part below the
  /// fold lands somewhere else
  /// (`lessons/scroll-to-the-last-line-of-what-you-will-tap-not-the-first`).
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder.first);
    await tester.pumpAndSettle();
  }

  Future<void> open(
    WidgetTester tester, {
    HandoverNote? note,
    HouseholdView? view,
    Brightness brightness = Brightness.light,
    double textScale = 1,
    bool narrow = false,
  }) async {
    await pumpTwoHomes(
      tester,
      HandoverScreen(today: CalendarDate(2026, 10, 1)),
      view: view ?? Fixtures.view(),
      brightness: brightness,
      textScale: textScale,
      narrow: narrow,
      providers: [
        ChangeNotifierProvider(
          create: (_) => HandoverController(
            twoHomesRepository: repository,
            twoHomesDirectory: directory,
            householdId: Fixtures.householdId,
            linkId: 'link-sam',
            date: friday,
          ),
        ),
      ],
    );
    repository.link.add(aLink());
    repository.handover.add(note);
    await tester.pumpAndSettle();
  }

  final written = HandoverNote(
    id: '2026-10-02',
    date: friday,
    items: const [
      HandoverItem(text: 'School bag', packed: true),
      HandoverItem(text: 'Inhaler', packed: false),
    ],
    medicine: 'Inhaler at seven',
    updatedBySide: CustodySide.b,
  );

  testWidgets('says who goes where, and what the other home last saved', (
    tester,
  ) async {
    await open(tester, note: written);
    expect(
      find.text(
        TwoHomesHandoverCopy.goesFromTo(
          'Kid Parker',
          'Dad’s home',
          'Mum’s home',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.text(TwoHomesHandoverCopy.lastSavedBy('Dad’s home')),
      findsOneWidget,
    );
    expect(find.text(TwoHomesHandoverCopy.packedCount(1, 2)), findsOneWidget);
    expect(find.text('Inhaler at seven'), findsOneWidget);
  });

  testWidgets('ticks, adds and removes, then saves for both homes', (
    tester,
  ) async {
    await open(tester, note: written);
    await tester.tap(find.bySemanticsLabel('Inhaler'));
    await tester.pump();
    expect(find.text(TwoHomesHandoverCopy.packedCount(2, 2)), findsOneWidget);

    await reveal(tester, find.text('Lunchbox'));
    await tester.tap(find.text('Lunchbox'));
    await tester.pump();
    final remove = find.byTooltip(
      '${TwoHomesHandoverCopy.removeItem} School bag',
    );
    await reveal(tester, remove);
    await tester.tap(remove);
    await tester.pump();

    // "Homework" is a field and one of the usual things to pack.
    final homework = find.descendant(
      of: find.widgetWithText(NestTextField, TwoHomesHandoverCopy.homework),
      matching: find.byType(EditableText),
    );
    await reveal(tester, homework);
    await tester.enterText(homework, 'Reading log');
    await reveal(tester, find.text(TwoHomesHandoverCopy.save));
    await tester.tap(find.text(TwoHomesHandoverCopy.save));
    await tester.pumpAndSettle();

    final sent = directory.lastOf('saveHandover');
    expect(sent['date'], friday);
    expect(sent['items'], const [
      HandoverItem(text: 'Inhaler', packed: true),
      HandoverItem(text: 'Lunchbox', packed: false),
    ]);
    expect(sent['homework'], 'Reading log');
    expect(sent['medicine'], 'Inhaler at seven');
    expect(find.text(TwoHomesHandoverCopy.saved), findsOneWidget);
  });

  testWidgets(
    'a handover nobody has written starts empty, with the usual things',
    (tester) async {
      await open(tester);
      expect(
        find.text(TwoHomesHandoverCopy.lastSavedBy('Mum’s home')),
        findsNothing,
      );
      await reveal(tester, find.text('School bag'));
      await tester.tap(find.text('School bag'));
      await tester.pump();
      expect(find.text(TwoHomesHandoverCopy.packedCount(0, 1)), findsOneWidget);
    },
  );

  testWidgets('a refused save is said, in words', (tester) async {
    directory.failWith = const CoParentFailure(CoParentProblem.linkNotActive);
    await open(tester, note: written);
    await reveal(tester, find.text(TwoHomesHandoverCopy.save));
    await tester.tap(find.text(TwoHomesHandoverCopy.save));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(TwoHomesCopy.problem(CoParentProblem.linkNotActive)),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text(TwoHomesCopy.problem(CoParentProblem.linkNotActive)),
      findsOneWidget,
    );
  });

  testWidgets('a carer reads it, and cannot change it', (tester) async {
    await open(
      tester,
      note: written,
      view: Fixtures.helperView(
        AccessGrant.uniform(AccessLevel.none)
            .withLevel(HouseholdArea.calendar, AccessLevel.view)
            .withLevel(HouseholdArea.medical, AccessLevel.view),
      ),
    );
    expect(find.text(TwoHomesHandoverCopy.readOnly), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Inhaler'));
    await tester.pump();
    expect(find.text(TwoHomesHandoverCopy.packedCount(1, 2)), findsOneWidget);
    expect(find.text(TwoHomesHandoverCopy.save), findsNothing);
    expect(find.text('Lunchbox'), findsNothing);
  });

  testWidgets('holds at 360 wide, in dark, at 200% text', (tester) async {
    await open(
      tester,
      note: written,
      narrow: true,
      brightness: Brightness.dark,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await reveal(tester, find.text(TwoHomesHandoverCopy.save));
    expect(tester.takeException(), isNull);
  });
}
