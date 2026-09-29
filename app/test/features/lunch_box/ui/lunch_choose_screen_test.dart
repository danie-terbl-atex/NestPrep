import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_choices.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/state/lunch_choose_controller.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_choose_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_lunch_planning.dart';
import '../../../support/fake_lunch_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/pump_screen.dart';

/// The chooser (lunch-box ADR-0008): big cards per compartment, one tap to
/// choose, stars for how far along a day is — and the kind words when there
/// is nothing to choose or a pick is refused.
void main() {
  late FakeLunchRepository plans;
  late FakeLunchChoicesRepository choices;
  late LunchChooseController controller;
  var handedBack = 0;

  String key(int day, LunchSlot slot) => LunchFixtures.key(day, slot);
  final apple = LunchPick.of(LunchFixtures.apple);
  final grapes = LunchPick.of(LunchFixtures.grapes);
  final wrap = LunchPick.of(LunchFixtures.wrap);
  final cheese = LunchPick.of(LunchFixtures.cheese);

  setUp(() {
    handedBack = 0;
    plans = FakeLunchRepository();
    choices = FakeLunchChoicesRepository();
    controller = LunchChooseController(
      lunchRepository: plans,
      choicesRepository: choices,
      householdId: Fixtures.householdId,
      childId: LunchFixtures.lwaziId,
    );
  });

  tearDown(() async {
    controller.dispose();
    await plans.close();
    await choices.close();
  });

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
      LunchChooseScreen(childName: 'Lwazi', onDone: () => handedBack++),
      providers: [
        ChangeNotifierProvider<LunchChooseController>.value(value: controller),
      ],
      brightness: brightness,
      textScale: scale,
    );
    controller.follow(today: LunchFixtures.today);
    await tester.pump();
  }

  Future<void> arrive(
    WidgetTester tester, {
    Map<String, List<LunchPick>> options = const {},
    Map<String, LunchPick> packed = const {},
  }) async {
    plans.emitPlan(LunchFixtures.plan(LunchFixtures.lwaziId, slots: packed));
    choices.emitChoices(
      LunchChoices.none(
        childId: LunchFixtures.lwaziId,
        week: LunchFixtures.week,
      ).copyWith(options: options),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('holds the layout while it loads', (tester) async {
    await pump(tester);
    expect(
      find.text(LunchKidPicksCopy.chooserTitleFor('Lwazi')),
      findsOneWidget,
    );
  });

  testWidgets('with nothing offered, says so kindly', (tester) async {
    await pump(tester);
    await arrive(tester);
    expect(find.text(LunchKidPicksCopy.nothingToChoose), findsOneWidget);
  });

  testWidgets('a failed read says so, with a retry', (tester) async {
    await pump(tester);
    choices.failChoicesWith(const UnavailableFailure());
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.retry), findsOneWidget);
  });

  testWidgets('one tap chooses, and a finished day is celebrated and handed '
      'back', (tester) async {
    await pump(tester);
    await arrive(
      tester,
      options: {
        key(2, LunchSlot.fruit): [apple, grapes],
        key(2, LunchSlot.main): [wrap, cheese],
      },
      packed: {key(2, LunchSlot.main): wrap},
    );
    expect(find.text(LunchKidPicksCopy.progress(1, 2)), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(
        LunchKidPicksCopy.optionLabel('Chicken wrap', true),
      ),
      findsOneWidget,
    );
    semantics.dispose();

    await tester.tap(find.text('Grapes'));
    await tester.pump();
    expect(choices.chosen.single.pick.itemId, 'grapes');
    expect(controller.celebrations, 1);

    plans.emitPlan(
      LunchFixtures.plan(
        LunchFixtures.lwaziId,
        slots: {key(2, LunchSlot.main): wrap, key(2, LunchSlot.fruit): grapes},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(LunchKidPicksCopy.dayDone), findsOneWidget);
    await tester.tap(find.text(LunchKidPicksCopy.handBack));
    expect(handedBack, 1);
  });

  testWidgets('each day has its own chip, and today’s comes first', (
    tester,
  ) async {
    await pump(tester);
    await arrive(
      tester,
      options: {
        key(2, LunchSlot.fruit): [apple, grapes],
        key(4, LunchSlot.main): [wrap, cheese],
      },
    );
    expect(find.text('Chicken wrap'), findsNothing);
    await tester.tap(find.text('Thursday'));
    await tester.pumpAndSettle();
    expect(find.text('Chicken wrap'), findsOneWidget);
  });

  testWidgets('a refused pick is said in a child’s words', (tester) async {
    await pump(tester);
    await arrive(
      tester,
      options: {
        key(2, LunchSlot.fruit): [apple, grapes],
      },
    );
    choices.failWritesWith = const PermissionDeniedFailure();
    await tester.tap(find.text('Apple slices'));
    await tester.pumpAndSettle();
    expect(
      find.text(LunchPlanningCopy.problem(LunchPlanningProblem.notAnOption)),
      findsOneWidget,
    );
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
    await arrive(
      tester,
      options: {
        key(2, LunchSlot.fruit): [
          apple,
          grapes,
          LunchPick.of(LunchFixtures.biltong),
        ],
        key(2, LunchSlot.main): [wrap, cheese],
        key(3, LunchSlot.main): [wrap, cheese],
      },
    );
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
