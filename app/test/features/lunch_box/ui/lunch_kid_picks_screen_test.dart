import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/features/lunch_box/model/lunch_choices.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_kid_picks_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_planning_harness.dart';
import '../../../support/pump_screen.dart';

/// A parent's kid-picks screen (lunch-box ADR-0008): the days from today,
/// each compartment the way to its options, *Suggest options*, what the
/// child chose, and the hand-over to *Let them choose*.
void main() {
  late LunchPlanningHarness harness;

  setUp(() => harness = LunchPlanningHarness());
  tearDown(() => harness.close());

  String key(int day, LunchSlot slot) => LunchFixtures.key(day, slot);
  final apple = LunchPick.of(LunchFixtures.apple);
  final grapes = LunchPick.of(LunchFixtures.grapes);

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
    Size size = const Size(420, 2600),
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpRouter(
      tester,
      router: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const LunchKidPicksScreen(),
          ),
          GoRoute(
            path: '/households/:householdId/lunch/choose/:childId',
            builder: (context, state) =>
                Text('choosing ${state.pathParameters['childId']}'),
          ),
        ],
      ),
      providers: harness.providers,
      brightness: brightness,
      textScale: scale,
    );
  }

  Future<void> arrive(
    WidgetTester tester, {
    List<LunchChoices> choices = const [],
  }) async {
    harness.lunch.emit(
      plans: [
        LunchFixtures.plan(
          LunchFixtures.lwaziId,
          slots: {
            key(2, LunchSlot.fruit): grapes,
            key(2, LunchSlot.main): LunchPick.of(LunchFixtures.wrap),
          },
        ),
      ],
    );
    harness.emitPlanning(choices: choices);
    await tester.pumpAndSettle();
  }

  LunchChoices offered() =>
      LunchChoices.none(
        childId: LunchFixtures.lwaziId,
        week: LunchFixtures.week,
      ).copyWith(
        options: {
          key(2, LunchSlot.fruit): [apple, grapes],
          key(3, LunchSlot.fruit): [apple, grapes],
        },
        chosen: {key(2, LunchSlot.fruit): 'grapes'},
      );

  testWidgets('holds the layout while it loads', (tester) async {
    await pump(tester);
    await tester.pump();
    expect(find.text(LunchKidPicksCopy.title), findsOneWidget);
  });

  testWidgets('shows a failure in words', (tester) async {
    await pump(tester);
    harness.lunch.repository.failItemsWith(const UnavailableFailure());
    await tester.pumpAndSettle();
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
  });

  testWidgets('with no options yet, every compartment is the way in', (
    tester,
  ) async {
    await pump(tester);
    await arrive(tester);
    expect(find.text(LunchKidPicksCopy.subtitle('Lwazi')), findsOneWidget);
    expect(find.text(LunchKidPicksCopy.suggestOptions), findsOneWidget);
    expect(find.text(LunchKidPicksCopy.letChoose('Lwazi')), findsNothing);
    // Monday has gone: the days are today and after.
    expect(find.text('Monday'), findsNothing);
    expect(find.text('Tuesday'), findsOneWidget);
    expect(find.text(LunchKidPicksCopy.packedByYou), findsWidgets);
  });

  testWidgets('says what the child chose, and hands over to them', (
    tester,
  ) async {
    await pump(tester);
    await arrive(tester, choices: [offered()]);
    expect(
      find.text(LunchKidPicksCopy.chose('Lwazi', 'Grapes')),
      findsOneWidget,
    );
    expect(find.text(LunchKidPicksCopy.waiting), findsOneWidget);
    await tester.tap(find.text(LunchKidPicksCopy.letChoose('Lwazi')));
    await tester.pumpAndSettle();
    expect(find.text('choosing ${LunchFixtures.lwaziId}'), findsOneWidget);
  });

  testWidgets('a compartment’s options are chosen from safe suggestions', (
    tester,
  ) async {
    await pump(tester);
    await arrive(tester);
    await tester.tap(find.text(LunchCopy.slotName(LunchSlot.snack)).first);
    await tester.pumpAndSettle();
    // Tuesday's snack for Lwazi: biltong alone — trail mix is not safe for
    // him, and one thing is not a choice.
    expect(find.text('Trail mix'), findsNothing);
    expect(find.text(LunchKidPicksCopy.noSuggestions), findsOneWidget);
  });

  testWidgets('two picked, the options are offered for that day', (
    tester,
  ) async {
    await pump(tester);
    await arrive(tester);
    await tester.tap(find.text(LunchCopy.slotName(LunchSlot.fruit)).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apple slices').last);
    await tester.tap(find.text('Grapes').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(LunchKidPicksCopy.saveOptions));
    await tester.pumpAndSettle();
    final write = harness.choicesRepository.setOptionsWrites.single;
    expect(write.day, 3);
    expect(write.options.keys.single, key(3, LunchSlot.fruit));
  });

  testWidgets('suggest options fills the week a day at a time — Tuesday '
      'is packed, or has only one of a thing', (tester) async {
    await pump(tester);
    await arrive(tester);
    await tester.tap(find.text(LunchKidPicksCopy.suggestOptions));
    await tester.pumpAndSettle();
    expect(
      harness.choicesRepository.setOptionsWrites.map((write) => write.day),
      [3, 4, 5],
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
    await arrive(tester, choices: [offered()]);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
