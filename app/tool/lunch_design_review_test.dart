import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_feedback.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_prep.dart';
import 'package:nestprep/features/lunch_box/model/lunch_seed_catalogue.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_library_screen.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_prep_screen.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_screen.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/household_fixtures.dart';
import '../test/support/lunch_fixtures.dart';
import '../test/support/lunch_harness.dart';
import 'review_press.dart';

/// Lunch boxes in the design-review press — the board, the one-tap swap, the
/// Sunday prep list and the library, light and dark, and the board at 200%
/// text. Pictures to look at, not assertions: regenerate with
///
///     flutter test tool/lunch_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  final library = LunchSeedCatalogue.itemsFor(Fixtures.samMemberId);
  LunchPick seed(String key) =>
      LunchPick.of(library.firstWhere((item) => item.seedKey == key));
  String at(int day, LunchSlot slot) => LunchPlan.slotKey(day, slot);

  /// A week that is half packed: Monday came home eaten, Tuesday — today —
  /// is full, Wednesday has a main, the rest wait for "Fill the week".
  final lwaziWeek = LunchFixtures.plan(
    LunchFixtures.lwaziId,
    slots: {
      at(1, LunchSlot.main): seed('cheese-rolls'),
      at(1, LunchSlot.fruit): seed('naartjie'),
      at(1, LunchSlot.veg): seed('carrot-sticks'),
      at(1, LunchSlot.snack): seed('biltong'),
      at(2, LunchSlot.main): seed('chicken-mayo'),
      at(2, LunchSlot.fruit): seed('apple'),
      at(2, LunchSlot.veg): seed('cucumber'),
      at(2, LunchSlot.snack): seed('popcorn'),
      at(2, LunchSlot.treat): seed('muffin'),
      at(3, LunchSlot.main): seed('pasta-salad'),
    },
    feedback: {
      '1': LunchFixtures.feedback(
        LunchVerdict.ate,
        items: {LunchSlot.veg: LunchVerdict.left},
      ),
    },
  );
  final ayandaWeek = LunchFixtures.plan(
    LunchFixtures.ayandaId,
    slots: {
      at(2, LunchSlot.main): seed('cheese-tomato'),
      at(2, LunchSlot.veg): seed('carrot-sticks'),
    },
  );

  Future<LunchHarness> packed(WidgetTester tester) async {
    final harness = LunchHarness();
    addTearDown(harness.close);
    return harness;
  }

  Future<void> emitWeek(LunchHarness harness) async => harness.emit(
    items: library,
    plans: [lwaziWeek, ayandaWeek],
    prep: LunchPrep(
      id: LunchFixtures.week.key,
      done: [LunchSeedCatalogue.idFor('carrot-sticks')],
    ),
  );

  Future<void> capture(
    WidgetTester tester,
    String name,
    Widget screen, {
    Brightness brightness = Brightness.light,
    double textScale = 1,
    Future<void> Function()? act,
  }) async {
    final harness = await packed(tester);
    await captureScreen(
      tester,
      name,
      screen: screen,
      providers: harness.providers,
      emit: () => emitWeek(harness),
      brightness: brightness,
      textScale: textScale,
      act: act,
    );
  }

  final board = LunchScreen(onSelectTab: (_) {});

  /// Scrolls Wednesday's empty fruit compartment into view and opens it.
  Future<void> openFruitPicker(WidgetTester tester) async {
    final fruit = find.byKey(const ValueKey('2026-09-30-fruit'));
    await tester.scrollUntilVisible(
      fruit,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    // Clear of the floating bottom bar, so the tap lands on the row.
    await tester.runAsync(
      () => Scrollable.ensureVisible(tester.element(fruit), alignment: 0.4),
    );
    await tester.pumpAndSettle();
    await tester.tap(fruit);
  }

  testWidgets(
    'lunch, light',
    (tester) => capture(tester, 'lunch-light', board),
  );

  testWidgets(
    'lunch, dark',
    (tester) =>
        capture(tester, 'lunch-dark', board, brightness: Brightness.dark),
  );

  testWidgets(
    'lunch, the week further down',
    (tester) => capture(
      tester,
      'lunch-week-light',
      board,
      act: () =>
          tester.drag(find.byType(Scrollable).last, const Offset(0, -620)),
    ),
  );

  testWidgets(
    'lunch, dark at 200% text',
    (tester) => capture(
      tester,
      'lunch-dark-200-percent-text',
      board,
      brightness: Brightness.dark,
      textScale: 2,
    ),
  );

  testWidgets(
    'lunch, swapping a slot',
    (tester) => capture(
      tester,
      'lunch-swap-light',
      board,
      act: () => openFruitPicker(tester),
    ),
  );

  testWidgets(
    'Sunday prep, light',
    (tester) => capture(tester, 'lunch-prep-light', const LunchPrepScreen()),
  );

  testWidgets(
    'Sunday prep, dark',
    (tester) => capture(
      tester,
      'lunch-prep-dark',
      const LunchPrepScreen(),
      brightness: Brightness.dark,
    ),
  );

  testWidgets(
    'the library, light',
    (tester) =>
        capture(tester, 'lunch-library-light', const LunchLibraryScreen()),
  );

  testWidgets(
    'the library, dark',
    (tester) => capture(
      tester,
      'lunch-library-dark',
      const LunchLibraryScreen(),
      brightness: Brightness.dark,
    ),
  );
}
