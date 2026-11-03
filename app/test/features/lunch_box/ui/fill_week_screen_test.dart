import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/lunch_box/model/lunch_box.dart';
import 'package:nestprep/features/lunch_box/model/lunch_favourite.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/state/fill_week_controller.dart';
import 'package:nestprep/features/lunch_box/ui/fill_week_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_lunch_variety.dart';
import '../../../support/fake_recipe_repository.dart';
import '../../../support/fake_starter_boxes.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_harness.dart';
import '../../../support/pump_screen.dart';

/// *Fill the week* on screen (lunch-box ADR-0020), for Ayanda on Tuesday 29
/// September: the two groups of boxes, a choice numbered by its turn, the
/// week before anything is written with each lunch saying where it came
/// from, then the write. Loading, a ready-made list that cannot be read and
/// nothing to choose are each said in place, with the way on still there;
/// every step holds dark at 200% text on a small phone; no Twig — no AI.
void main() {
  late LunchHarness harness;
  late FakeLunchStarterBoxRepository starterBoxes;
  late FillWeekController controller;

  final wrapDay = LunchFavourite.of(
    id: 'fav-wrap',
    childId: LunchFixtures.ayandaId,
    name: 'Wrap day',
    box: LunchBox({
      LunchSlot.main: LunchPick.of(LunchFixtures.wrap),
      LunchSlot.fruit: LunchPick.of(LunchFixtures.grapes),
    }),
    createdBy: Fixtures.samMemberId,
  );

  setUp(() {
    harness = LunchHarness();
    starterBoxes = FakeLunchStarterBoxRepository(StarterBoxFixtures.all);
  });

  tearDown(() async {
    controller.dispose();
    await harness.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    List<LunchFavourite>? favourites,
    bool arrive = true,
    Brightness brightness = Brightness.light,
    double scale = 1,
    Size size = const Size(420, 2400),
    bool settle = true,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    controller = FillWeekController(
      starterBoxes: starterBoxes,
      recipes: FakeRecipeRepository(StarterBoxFixtures.recipes),
      lunchRepository: harness.repository,
      variety: lunchVarietyChoice(Fixtures.householdId),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      childId: LunchFixtures.ayandaId,
    );
    harness.controller.addListener(
      () => controller.followBoard(harness.controller.board),
    );
    await pumpScreen(
      tester,
      const FillWeekScreen(),
      providers: [
        ...harness.providers,
        ChangeNotifierProvider<FillWeekController>.value(value: controller),
      ],
      brightness: brightness,
      textScale: scale,
    );
    if (arrive) harness.emit(favourites: favourites ?? [wrapDay]);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // A skeleton breathes for as long as it waits, so it never settles.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  /// The step's own list, not the header's.
  Finder stepList() => find
      .descendant(
        of: find.byType(ListView).last,
        matching: find.byType(Scrollable),
      )
      .first;

  Future<void> tapKey(WidgetTester tester, String key) async {
    final target = find.byKey(ValueKey(key));
    await tester.scrollUntilVisible(target, 300, scrollable: stepList());
    await tester.pumpAndSettle();
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('holds its place while the board loads', (tester) async {
    await pump(tester, arrive: false, settle: false);
    expect(find.byType(NestLoadingView), findsWidgets);
    expect(find.text(FillWeekCopy.stepOf(1)), findsOneWidget);
  });

  testWidgets('offers Ayanda\'s go-to boxes and NestPrep\'s, in two '
      'labelled groups, and says which week is filled', (tester) async {
    await pump(tester);
    expect(find.text(FillWeekCopy.goToHeader), findsOneWidget);
    expect(find.text(FillWeekCopy.readyMadeHeader), findsOneWidget);
    expect(find.text('Wrap day'), findsOneWidget);
    expect(find.text('The classic'), findsOneWidget);
    expect(
      find.text(FillWeekCopy.forChild('Ayanda', LunchCopy.thisWeek)),
      findsOneWidget,
    );
    expect(find.byType(NestTwig), findsNothing);
  });

  testWidgets('a chosen box is numbered by its turn, and the week shows '
      'where every new lunch came from before anything is written', (
    tester,
  ) async {
    await pump(tester);
    await tapKey(tester, 'fill-week-box-ready-test-box-classic');
    expect(find.text(FillWeekCopy.chosenTurn(1)), findsOneWidget);
    await tapKey(tester, 'fill-week-review');
    expect(find.text(FillWeekCopy.stepOf(2)), findsOneWidget);
    expect(find.text(FillWeekCopy.fromBox('The classic')), findsWidgets);
    expect(find.text(FillWeekCopy.byNestPrep), findsWidgets);
    expect(find.text(FillWeekCopy.dayGone), findsNWidgets(2));
    expect(harness.repository.writtenPicks, isEmpty);
    await tapKey(tester, 'fill-week-fill');
    expect(harness.repository.writtenPicks, hasLength(1));
    expect(find.text(FillWeekCopy.doneHeadline('Ayanda')), findsOneWidget);
    expect(find.byType(NestTwig), findsNothing);
  });

  testWidgets('skipping fills it all from go-to boxes and what they eat', (
    tester,
  ) async {
    await pump(tester);
    await tapKey(tester, 'fill-week-skip');
    expect(find.text(FillWeekCopy.fromBox('Wrap day')), findsWidgets);
  });

  testWidgets('the review keeps fruit the same all week until its chip is '
      'turned off', (tester) async {
    await pump(tester, favourites: const []);
    await tapKey(tester, 'fill-week-skip');
    expect(find.text(LunchVarietyCopy.header), findsOneWidget);
    Set<String> fruits() => {
      for (final MapEntry(:key, :value)
          in controller.preview!.result.picks.entries)
        if (key.endsWith('_fruit')) value.itemId,
    };
    expect(fruits(), hasLength(1));
    await tapKey(tester, 'variety-fruit');
    expect(fruits().length, greaterThan(1));
  });

  testWidgets('the ready-made list loading is said in its own place', (
    tester,
  ) async {
    starterBoxes.gate = Completer<void>();
    await pump(tester, settle: false);
    expect(find.text('Wrap day'), findsOneWidget);
    expect(find.byType(NestLoadingView), findsOneWidget);
    starterBoxes.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('The classic'), findsOneWidget);
  });

  testWidgets('a ready-made list that cannot be read says so in words with a '
      'retry, and skipping still works', (tester) async {
    starterBoxes.failWith = const UnavailableFailure();
    await pump(tester);
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    starterBoxes.failWith = null;
    await tester.tap(find.text(AppCopy.retry));
    await tester.pumpAndSettle();
    expect(find.text('The classic'), findsOneWidget);
    await tapKey(tester, 'fill-week-skip');
    expect(find.text(FillWeekCopy.reviewHeadline('Ayanda')), findsOneWidget);
  });

  testWidgets('with nothing to choose it says so, and skipping is still '
      'there', (tester) async {
    starterBoxes.boxes = const [];
    await pump(tester, favourites: const []);
    expect(find.text(FillWeekCopy.nothingToChooseTitle), findsOneWidget);
    await tapKey(tester, 'fill-week-skip');
    expect(find.text(FillWeekCopy.reviewHeadline('Ayanda')), findsOneWidget);
  });

  testWidgets('a box chip says what tapping it does', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    expect(
      find.bySemanticsLabel(FillWeekCopy.chooseBox('The classic')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('every step holds dark at 200% text on a small phone', (
    tester,
  ) async {
    await pump(
      tester,
      brightness: Brightness.dark,
      scale: 2,
      size: const Size(360, 800),
    );
    expect(tester.takeException(), isNull, reason: 'boxes');
    for (final step in [
      'fill-week-box-ready-test-box-trail',
      'fill-week-review',
      'fill-week-fill',
    ]) {
      await tester.drag(stepList(), const Offset(0, 3000));
      await tester.pumpAndSettle();
      await tapKey(tester, step);
      expect(tester.takeException(), isNull, reason: 'after $step');
      await tester.drag(stepList(), const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'scrolled after $step');
    }
  });
}
