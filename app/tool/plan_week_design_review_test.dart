import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_seed_catalogue.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/model/lunch_week.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_screen.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/features/plan_week/data/plan_week_groceries.dart';
import 'package:nestprep/features/plan_week/data/week_planner.dart';
import 'package:nestprep/features/plan_week/model/dinner_idea.dart';
import 'package:nestprep/features/plan_week/model/plan_week_options.dart';
import 'package:nestprep/features/plan_week/model/plan_week_reply.dart';
import 'package:nestprep/features/plan_week/state/plan_week_controller.dart';
import 'package:nestprep/features/plan_week/state/plan_week_saver.dart';
import 'package:nestprep/features/plan_week/ui/plan_week_screen.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_meal_repository.dart';
import '../test/support/household_fixtures.dart';
import '../test/support/lunch_fixtures.dart';
import '../test/support/lunch_planning_harness.dart';
import 'review_press.dart';

/// *Plan my week* in the design-review press (lunch-box ADR-0011): the way
/// in on the board, the choices, the wait, the review — with AI and without —
/// and the week saved, light and dark, and the review dark at 200% text.
/// Regenerate with
///
///     flutter test tool/plan_week_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  final library = LunchSeedCatalogue.itemsFor(Fixtures.samMemberId);
  String id(String key) => LunchSeedCatalogue.idFor(key);
  LunchPick seed(String key) =>
      LunchPick.of(library.firstWhere((item) => item.seedKey == key));
  String at(int day, LunchSlot slot) => LunchPlan.slotKey(day, slot);

  final lwaziWeek = LunchFixtures.plan(
    LunchFixtures.lwaziId,
    slots: {
      at(1, LunchSlot.main): seed('chicken-mayo'),
      at(1, LunchSlot.fruit): seed('apple'),
      at(1, LunchSlot.snack): seed('biltong'),
    },
  );

  final meals = [
    for (final (index, name) in const [
      'Spaghetti bolognese',
      'Chicken curry and rice',
      'Boerewors and pap',
      'Fish cakes and salad',
      'Braai night',
    ].indexed)
      Meal.named(id: 'meal-$index', name: name, addedBy: Fixtures.samMemberId),
  ];

  ReplyLunch lunch(String child, int day, LunchSlot slot, String key) =>
      ReplyLunch(childId: child, day: day, slot: slot, itemId: id(key));

  final reply = PlanWeekReply(
    lunches: [
      for (final (day, main, fruit, veg, snack) in const [
        (2, 'cheese-rolls', 'naartjie', 'cucumber', 'crackers'),
        (3, 'pasta-salad', 'banana', 'sugar-snaps', 'raisins'),
        (4, 'mealie-bread', 'pear', 'baby-corn', 'cheese-cubes'),
        (5, 'egg-mayo', 'grapes', 'pepper-strips', 'rice-cakes'),
      ]) ...[
        lunch(LunchFixtures.lwaziId, day, LunchSlot.main, main),
        lunch(LunchFixtures.lwaziId, day, LunchSlot.fruit, fruit),
        lunch(LunchFixtures.lwaziId, day, LunchSlot.veg, veg),
        lunch(LunchFixtures.lwaziId, day, LunchSlot.snack, snack),
      ],
      lunch(LunchFixtures.lwaziId, 5, LunchSlot.treat, 'muffin'),
      for (final (day, main, fruit, snack) in const [
        (1, 'chicken-mayo', 'grapes', 'biltong'),
        (2, 'tuna-sandwich', 'grapes', 'yoghurt'),
        (3, 'frikkadels', 'strawberries', 'pretzels'),
        (4, 'hummus-pita', 'mango', 'droewors'),
        (5, 'cheese-rolls', 'grapes', 'crackers'),
      ]) ...[
        lunch(LunchFixtures.ayandaId, day, LunchSlot.main, main),
        lunch(LunchFixtures.ayandaId, day, LunchSlot.fruit, fruit),
        lunch(LunchFixtures.ayandaId, day, LunchSlot.snack, snack),
      ],
    ],
    dinners: [
      const ReplyDinner(day: 1, mealId: 'meal-0'),
      const ReplyDinner(day: 2, mealId: 'meal-1'),
      const ReplyDinner(
        day: 3,
        idea: DinnerIdea(
          name: 'Chicken and vegetable tray bake',
          ingredients: [
            IdeaIngredient(name: 'Chicken thighs', quantity: '1 kg'),
            IdeaIngredient(name: 'Butternut', quantity: '1'),
            IdeaIngredient(name: 'Red onions', quantity: '2'),
            IdeaIngredient(name: 'Baby potatoes', quantity: '500 g'),
          ],
        ),
      ),
      const ReplyDinner(day: 4, mealId: 'meal-3'),
      const ReplyDinner(day: 6, mealId: 'meal-2'),
      const ReplyDinner(day: 7, mealId: 'meal-4'),
    ],
    dinnersIncluded: true,
    dropped: 1,
    callsLeft: 97,
  );

  Future<void> capture(
    WidgetTester tester,
    String name,
    Widget screen, {
    Brightness brightness = Brightness.light,
    double textScale = 1,
    AppFailure? refusal,
    Future<void> Function(PlanWeekController controller)? act,
  }) async {
    final harness = LunchPlanningHarness();
    final mealRepository = FakeMealRepository();
    final controller = PlanWeekController(
      planner: _FixedPlanner(reply: reply, refusal: refusal),
      saver: PlanWeekSaver(
        lunchRepository: harness.lunch.repository,
        mealRepository: mealRepository,
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
      ),
      groceries: PlanWeekGroceries(
        groceryRepository: harness.groceries,
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
      ),
      mealRepository: mealRepository,
      householdId: Fixtures.householdId,
      week: LunchWeek.of(LunchFixtures.today),
      mayPlanDinners: true,
    );
    void follow() => controller.followBoard(harness.board.board);
    harness.board.addListener(follow);
    addTearDown(() async {
      harness.board.removeListener(follow);
      controller.dispose();
      await mealRepository.close();
      await harness.close();
    });
    await captureScreen(
      tester,
      name,
      screen: screen,
      providers: [
        ...harness.lunch.providers,
        ...harness.providers,
        ChangeNotifierProvider<PlanWeekController>.value(value: controller),
      ],
      emit: () async {
        harness.lunch.emit(items: library, plans: [lwaziWeek]);
        harness.emitPlanning();
        mealRepository
          ..emitMeals(meals)
          ..emitWeek(
            WeekPlan(
              id: LunchFixtures.week.monday.iso,
              slots: {WeekPlan.slotKey(5, MealSlot.dinner): 'meal-2'},
            ),
          );
        follow();
      },
      brightness: brightness,
      textScale: textScale,
      act: act == null ? null : () => act(controller),
    );
  }

  Future<void> plan(PlanWeekController controller) async {
    unawaited(controller.plan());
  }

  testWidgets(
    'the way in, on the board',
    (tester) => capture(
      tester,
      'plan-week-board-light',
      LunchScreen(onSelectTab: (_) {}),
    ),
  );

  for (final (brightness, suffix) in [
    (Brightness.light, 'light'),
    (Brightness.dark, 'dark'),
  ]) {
    testWidgets(
      'the choices, $suffix',
      (tester) => capture(
        tester,
        'plan-week-options-$suffix',
        const PlanWeekScreen(),
        brightness: brightness,
      ),
    );
    testWidgets(
      'the review, $suffix',
      (tester) => capture(
        tester,
        'plan-week-review-$suffix',
        const PlanWeekScreen(),
        brightness: brightness,
        act: plan,
      ),
    );
  }

  testWidgets(
    'the review further down, with the dinners',
    (tester) => capture(
      tester,
      'plan-week-review-dinners-light',
      const PlanWeekScreen(),
      act: (controller) async {
        await plan(controller);
        await tester.pumpAndSettle();
        await tester.drag(find.byType(Scrollable).last, const Offset(0, -2400));
      },
    ),
  );

  testWidgets(
    'the review without AI',
    (tester) => capture(
      tester,
      'plan-week-review-without-ai-light',
      const PlanWeekScreen(),
      refusal: const AiFailure(AiProblem.aiLimitReached),
      act: plan,
    ),
  );

  testWidgets(
    'the review, dark at 200% text',
    (tester) => capture(
      tester,
      'plan-week-review-dark-200-percent-text',
      const PlanWeekScreen(),
      brightness: Brightness.dark,
      textScale: 2,
      act: plan,
    ),
  );

  testWidgets(
    'the week saved',
    (tester) => capture(
      tester,
      'plan-week-done-light',
      const PlanWeekScreen(),
      act: (controller) async {
        await plan(controller);
        await tester.pumpAndSettle();
        unawaited(controller.use());
      },
    ),
  );
}

/// Answers every plan with [reply], or refuses with [refusal].
final class _FixedPlanner implements WeekPlanner {
  const _FixedPlanner({required this.reply, this.refusal});

  final PlanWeekReply reply;
  final AppFailure? refusal;

  @override
  Future<PlanWeekReply> plan({
    required String householdId,
    required LunchWeek week,
    required PlanWeekOptions options,
  }) async {
    final failure = refusal;
    if (failure != null) throw failure;
    return reply;
  }
}
