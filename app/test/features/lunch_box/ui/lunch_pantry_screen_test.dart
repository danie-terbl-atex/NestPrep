import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pantry_entry.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_pantry_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_planning_harness.dart';
import '../../../support/pump_screen.dart';

/// The pantry screen (lunch-box ADR-0006) in every state: loading, empty
/// with its way in still there, a failure in words, and a pantry held
/// against the week — stepped, topped up, and sent to the grocery list.
void main() {
  late LunchPlanningHarness harness;

  setUp(() => harness = LunchPlanningHarness());
  tearDown(() => harness.close());

  String key(int day, LunchSlot slot) => LunchFixtures.key(day, slot);
  LunchPantryEntry entry(String itemId, int portions) =>
      LunchPantryEntry(id: itemId, portions: portions, updatedBy: 'm-sam');

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
    Size size = const Size(420, 2000),
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      const LunchPantryScreen(),
      providers: harness.providers,
      brightness: brightness,
      textScale: scale,
    );
  }

  Future<void> arrive(
    WidgetTester tester, {
    List<LunchPantryEntry> pantry = const [],
  }) async {
    harness.lunch.emit(
      plans: [
        LunchFixtures.plan(
          LunchFixtures.ayandaId,
          slots: {
            key(3, LunchSlot.fruit): LunchPick.of(LunchFixtures.apple),
            key(4, LunchSlot.fruit): LunchPick.of(LunchFixtures.apple),
            key(3, LunchSlot.snack): LunchPick.of(LunchFixtures.biltong),
          },
        ),
      ],
    );
    harness.emitPlanning(pantry: pantry);
    await tester.pumpAndSettle();
  }

  testWidgets('holds the layout while it loads, the add button already there', (
    tester,
  ) async {
    await pump(tester);
    await tester.pump();
    expect(find.text(LunchPantryCopy.title), findsOneWidget);
    expect(find.text(LunchPantryCopy.addToPantry), findsOneWidget);
  });

  testWidgets('shows a failure in words, with a retry', (tester) async {
    await pump(tester);
    harness.pantryRepository.failPantryWith(const UnavailableFailure());
    harness.lunch.emit();
    await tester.pumpAndSettle();
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    expect(find.text(AppCopy.retry), findsOneWidget);
  });

  testWidgets('with nothing stocked, the week’s needs are the way in', (
    tester,
  ) async {
    await pump(tester);
    await arrive(tester);
    expect(find.text(LunchPantryCopy.missingTitle), findsOneWidget);
    expect(find.text(LunchPantryCopy.addMissingToGroceries(2)), findsOneWidget);
    expect(find.text(LunchPantryCopy.addToPantry), findsOneWidget);
  });

  testWidgets('says what is in the house against the week, and steps it', (
    tester,
  ) async {
    await pump(tester);
    await arrive(tester, pantry: [entry('apple', 1), entry('grapes', 0)]);
    expect(find.text(LunchPantryCopy.inTheHouse), findsOneWidget);
    expect(find.text(LunchPantryCopy.usedUp), findsOneWidget);
    expect(
      find.text(
        '${LunchPantryCopy.enoughFor(1)} · ${LunchPantryCopy.weekTakes(2)}',
      ),
      findsOneWidget,
    );
    expect(find.text(LunchPantryCopy.short(1)), findsOneWidget);

    await tester.tap(
      find.bySemanticsLabel(LunchPantryCopy.oneMore('Apple slices')),
    );
    await tester.pumpAndSettle();
    expect(harness.pantryRepository.portions.single, (
      itemId: 'apple',
      portions: 2,
    ));
  });

  testWidgets('a tap on an entry tops it up, uses it up or takes it out', (
    tester,
  ) async {
    await pump(tester);
    await arrive(tester, pantry: [entry('apple', 1)]);
    // The pantry's own row — the week's shortfall above names it too.
    await tester.tap(find.text('Apple slices').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(LunchPantryCopy.markUsedUp));
    await tester.pumpAndSettle();
    expect(harness.pantryRepository.portions.single.portions, 0);

    await tester.tap(find.text('Apple slices').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(LunchPantryCopy.remove));
    await tester.pumpAndSettle();
    expect(harness.pantryRepository.removed, ['apple']);
  });

  testWidgets('quick add finds a library item and stocks a pack of it', (
    tester,
  ) async {
    await pump(tester);
    await arrive(tester);
    await tester.tap(find.text(LunchPantryCopy.addToPantry));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'bil');
    await tester.pumpAndSettle();
    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('Apple slices')),
      findsNothing,
    );
    await tester.tap(find.text('Biltong').last);
    await tester.pumpAndSettle();
    expect(harness.pantryRepository.portions.single, (
      itemId: 'biltong',
      portions: LunchPantryEntry.aPack,
    ));
  });

  testWidgets('what is missing goes to the grocery list, and says so', (
    tester,
  ) async {
    await pump(tester);
    await arrive(tester, pantry: [entry('apple', 2)]);
    await tester.tap(find.text(LunchPantryCopy.addMissingToGroceries(1)));
    await tester.pump();
    harness.groceries.emitItems(const []);
    await tester.pumpAndSettle();
    expect(harness.groceries.added.single.name, 'Biltong');
    expect(find.text(LunchPantryCopy.addedToGroceries(1)), findsOneWidget);
  });

  testWidgets('renders in dark and at 200% text on a small phone', (
    tester,
  ) async {
    await pump(
      tester,
      brightness: Brightness.dark,
      scale: 2,
      size: const Size(360, 800),
    );
    await arrive(tester, pantry: [entry('apple', 1), entry('grapes', 0)]);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -1600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
