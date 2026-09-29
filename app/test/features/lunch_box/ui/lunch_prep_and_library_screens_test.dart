import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_prep.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_library_screen.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_prep_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_harness.dart';
import '../../../support/pump_screen.dart';

void main() {
  late LunchHarness harness;

  setUp(() => harness = LunchHarness());
  tearDown(() => harness.close());

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    // Tall enough that a sheet's button is above the fold.
    tester.view.physicalSize = const Size(420 * 3, 2000 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      screen,
      providers: harness.providers,
      brightness: brightness,
      textScale: scale,
    );
  }

  String key(int day, LunchSlot slot) => LunchFixtures.key(day, slot);

  final packedWeek = [
    LunchFixtures.plan(
      LunchFixtures.lwaziId,
      slots: {
        key(1, LunchSlot.veg): LunchPick.of(LunchFixtures.carrots),
        key(1, LunchSlot.main): LunchPick.of(LunchFixtures.wrap),
      },
    ),
    LunchFixtures.plan(
      LunchFixtures.ayandaId,
      slots: {key(2, LunchSlot.veg): LunchPick.of(LunchFixtures.carrots)},
    ),
  ];

  group('the Sunday prep list', () {
    testWidgets('holds the layout while it loads', (tester) async {
      await pump(tester, const LunchPrepScreen());
      await tester.pump();
      expect(find.text(LunchCopy.prepTitle), findsOneWidget);
    });

    testWidgets('with nothing planned, says so and offers the way back', (
      tester,
    ) async {
      await pump(tester, const LunchPrepScreen());
      harness.emit();
      await tester.pumpAndSettle();
      expect(find.text(LunchCopy.prepEmptyTitle), findsOneWidget);
      expect(find.text(LunchCopy.backToLunches), findsOneWidget);
    });

    testWidgets('shows a failure in words, with a retry', (tester) async {
      await pump(tester, const LunchPrepScreen());
      harness.repository.failItemsWith(const UnavailableFailure());
      await tester.pumpAndSettle();
      expect(
        find.text(AppCopy.failure(const UnavailableFailure())),
        findsOneWidget,
      );
      expect(find.text(AppCopy.retry), findsOneWidget);
    });

    testWidgets('lists what to make ahead first, summed across children', (
      tester,
    ) async {
      await pump(tester, const LunchPrepScreen());
      harness.emit(plans: packedWeek);
      await tester.pumpAndSettle();
      expect(find.text(LunchCopy.prepBatch), findsOneWidget);
      expect(find.text(LunchCopy.prepOnHand), findsOneWidget);
      expect(find.textContaining(LunchCopy.portions(2)), findsOneWidget);
      expect(find.textContaining('Cut on Sunday'), findsOneWidget);
      expect(find.text(LunchCopy.prepProgress(0, 2)), findsOneWidget);
    });

    testWidgets('a tick marks a thing ready for the whole household', (
      tester,
    ) async {
      await pump(tester, const LunchPrepScreen());
      harness.emit(
        plans: packedWeek,
        prep: LunchPrep(id: LunchFixtures.week.key, done: const ['wrap']),
      );
      await tester.pumpAndSettle();
      expect(find.text(LunchCopy.prepProgress(1, 2)), findsOneWidget);
      await tester.tap(find.text('Carrot sticks'));
      await tester.pumpAndSettle();
      expect(harness.repository.prepTicks.single.itemId, 'carrots');
      expect(harness.repository.prepTicks.single.done, isTrue);
    });

    testWidgets('renders in dark and at 200% text without overflowing', (
      tester,
    ) async {
      await pump(
        tester,
        const LunchPrepScreen(),
        brightness: Brightness.dark,
        scale: 2,
      );
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      harness.emit(plans: packedWeek);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('the library', () {
    testWidgets('lists every item under its slot, saying what is in it', (
      tester,
    ) async {
      await pump(tester, const LunchLibraryScreen());
      harness.emit();
      await tester.pumpAndSettle();
      expect(find.text(LunchCopy.slotName(LunchSlot.main)), findsOneWidget);
      expect(find.text('Peanut butter sandwich'), findsOneWidget);
      expect(
        find.text(LunchCopy.contains(['peanuts', 'wheat and gluten'])),
        findsOneWidget,
      );
    });

    testWidgets('while it is being set up, says so and keeps the add button', (
      tester,
    ) async {
      await pump(tester, const LunchLibraryScreen());
      harness.emit(items: const []);
      await tester.pumpAndSettle();
      expect(find.text(LunchCopy.libraryLoadingSeed), findsOneWidget);
      expect(find.bySemanticsLabel(LunchCopy.newItemTitle), findsOneWidget);
    });

    testWidgets('adds an item with what is in it', (tester) async {
      await pump(tester, const LunchLibraryScreen());
      harness.emit();
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(LunchCopy.newItemTitle));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Sushi rolls');
      await tester.tap(find.text('Fish'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(LunchCopy.addItem));
      await tester.pumpAndSettle();
      await tester.tap(find.text(LunchCopy.addItem));
      await tester.pumpAndSettle();
      final added = harness.repository.addedItems.single;
      expect(added.name, 'Sushi rolls');
      expect(added.allergens, ['fish']);
      expect(added.slotName, 'main');
    });

    testWidgets('puts an item away, and brings it back', (tester) async {
      await pump(tester, const LunchLibraryScreen());
      harness.emit(
        items: [
          LunchFixtures.apple,
          LunchFixtures.grapes.copyWith(archived: true),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text(LunchCopy.putAwayItems), findsOneWidget);
      await tester.tap(
        find.bySemanticsLabel(LunchCopy.putAway('Apple slices')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(LunchCopy.bringBack('Grapes')));
      await tester.pumpAndSettle();
      expect(harness.repository.archived, [
        (itemId: 'apple', archived: true),
        (itemId: 'grapes', archived: false),
      ]);
    });

    testWidgets('renders in dark and at 200% text without overflowing', (
      tester,
    ) async {
      await pump(
        tester,
        const LunchLibraryScreen(),
        brightness: Brightness.dark,
        scale: 2,
      );
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      harness.emit();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
