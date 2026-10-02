import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_place_resolver.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_seed_catalogue.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_screen.dart';
import 'package:nestprep/features/plan_week/data/shop_week_groceries.dart';
import 'package:nestprep/features/plan_week/model/left_out_reason.dart';
import 'package:nestprep/features/plan_week/model/lunch_idea.dart';
import 'package:nestprep/features/plan_week/model/lunch_ideas_reply.dart';
import 'package:nestprep/features/plan_week/model/lunch_week_reply.dart';
import 'package:nestprep/features/plan_week/state/plan_week_controller.dart';
import 'package:nestprep/features/plan_week/state/shop_week_saver.dart';
import 'package:nestprep/features/plan_week/ui/plan_week_screen.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/checkers_fakes_for_plan_week.dart';
import '../test/support/fake_checkers.dart';
import '../test/support/fake_live_location.dart';
import '../test/support/fake_plan_week.dart';
import '../test/support/household_fixtures.dart';
import '../test/support/lunch_fixtures.dart';
import '../test/support/lunch_planning_harness.dart';
import 'review_press.dart';

/// *Plan my week from Checkers* in the design-review press (lunch-box
/// ADR-0012): the way in on the board, then each of the five steps — the
/// brief, the ideas (with AI and without), the shop, the week and done —
/// light and dark, and the week dark at 200% text. Regenerate with
///
///     flutter test tool/plan_week_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  const lwazi = LunchFixtures.lwaziId;
  const ayanda = LunchFixtures.ayandaId;
  final library = LunchSeedCatalogue.itemsFor(Fixtures.samMemberId);
  LunchPick seed(String key) =>
      LunchPick.of(library.firstWhere((item) => item.seedKey == key));
  String at(int day, LunchSlot slot) => LunchPlan.slotKey(day, slot);

  final lwaziWeek = LunchFixtures.plan(
    lwazi,
    slots: {
      at(1, LunchSlot.main): seed('chicken-mayo'),
      at(1, LunchSlot.fruit): seed('apple'),
    },
  );

  LunchIdea idea(
    String id,
    LunchSlot slot,
    String words,
    String why, {
    List<String> children = const [lwazi, ayanda],
    List<LeftOutReason> excluded = const [],
  }) => LunchIdea(
    id: id,
    slot: slot,
    idea: words,
    searchTerm: words,
    why: why,
    childIds: children,
    excluded: excluded,
    origin: IdeaOrigin.drafted,
  );

  final ideas = LunchIdeasReply(
    ideas: [
      idea('idea-1', LunchSlot.main, 'Wholewheat wraps', 'Both ate wraps well'),
      idea('idea-2', LunchSlot.fruit, 'Apples', 'A staple'),
      idea('idea-3', LunchSlot.snack, 'Fruit yoghurt', 'Ayanda likes it'),
      idea(
        'idea-4',
        LunchSlot.snack,
        'Peanut butter crackers',
        'Cheap and filling',
        children: const [ayanda],
        excluded: const [
          LeftOutReason(
            LeftOutKind.allergy,
            childId: lwazi,
            allergen: Allergen.peanut,
          ),
        ],
      ),
      idea('idea-5', LunchSlot.treat, 'Rice cakes', 'A Friday treat'),
    ],
    budgetCents: 40000,
    callsLeft: 23,
  );

  void stock(FakeShopCatalogue shop) => shop.byQuery
    ..['Wholewheat wraps'] = [
      planWeekProduct(
        'Sasko Wholewheat Wraps 6s',
        id: 'wraps',
        cents: 3299,
        packCount: 6,
        ingredients: 'Wheat flour, water',
      ),
    ]
    ..['Apples'] = [
      planWeekProduct(
        'Golden Delicious Apples 6 Pack',
        id: 'apples',
        cents: 2999,
        packCount: 6,
        ingredients: 'Apples',
      ),
      planWeekProduct('Loose Apples', id: 'loose', unit: 'KG'),
    ]
    ..['Fruit yoghurt'] = [
      planWeekProduct(
        'Clover Fruit Yoghurt 6 x 100g',
        id: 'yog',
        cents: 3699,
        packCount: 6,
        ingredients: 'Milk, fruit',
      ),
      planWeekProduct('Nutty Yoghurt Bar', id: 'nutty', ingredients: 'Almonds'),
    ]
    ..['Peanut butter crackers'] = [
      planWeekProduct(
        'Bakers Peanut Crackers',
        id: 'pbc',
        ingredients: 'Wheat',
      ),
    ]
    ..['Rice cakes'] = [planWeekProduct('Rice cakes 100g', id: 'rice')];

  final week = LunchWeekReply(
    lunches: [
      for (var day = 1; day <= 5; day++) ...[
        if (day > 1)
          ReplyLunch(
            childId: lwazi,
            day: day,
            slot: LunchSlot.main,
            ideaId: 'idea-1',
            productId: 'wraps',
          ),
        ReplyLunch(
          childId: ayanda,
          day: day,
          slot: LunchSlot.main,
          ideaId: 'idea-1',
          productId: 'wraps',
        ),
        ReplyLunch(
          childId: ayanda,
          day: day,
          slot: LunchSlot.snack,
          ideaId: 'idea-3',
          productId: 'yog',
        ),
      ],
    ],
    boxesPerPack: const {'wraps': 6, 'yog': 6},
    budgetCents: 40000,
    dropped: 0,
    callsLeft: 22,
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
    final drafter = FakeLunchIdeaDrafter()
      ..reply = ideas
      ..failWith = refusal;
    final builder = FakeLunchWeekBuilder()..reply = week;
    final shop = FakeShopCatalogue();
    stock(shop);
    final controller = PlanWeekController(
      drafter: drafter,
      aisleSource: FakeLunchAisleSource(),
      weekBuilder: builder,
      catalogue: shop,
      placeResolver: CheckersPlaceResolver(
        locationSource: FakeLocationSource(),
        areaPreference: FakeCheckersAreaPreference(),
      ),
      saver: ShopWeekSaver(
        lunchRepository: harness.lunch.repository,
        budgetRepository: harness.budgetRepository,
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
      ),
      groceries: ShopWeekGroceries(
        groceryRepository: harness.groceries,
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
      ),
      householdId: Fixtures.householdId,
      week: LunchFixtures.week,
    );
    void follow() => controller.followBoard(harness.board.board);
    harness.board.addListener(follow);
    addTearDown(() async {
      harness.board.removeListener(follow);
      controller.dispose();
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
        harness.emitPlanning(
          budget: const LunchBudget(id: 'weekly', cents: 40000, updatedBy: 'm'),
        );
        follow();
      },
      brightness: brightness,
      textScale: textScale,
      act: act == null ? null : () => act(controller),
    );
  }

  Future<void> toIdeas(PlanWeekController controller) =>
      controller.draftIdeas();

  Future<void> toStore(PlanWeekController controller) async {
    await controller.draftIdeas();
    await controller.searchStore();
  }

  Future<void> toWeek(PlanWeekController controller) async {
    await toStore(controller);
    await controller.buildWeek();
  }

  Future<void> toDone(PlanWeekController controller) async {
    await toWeek(controller);
    await controller.use();
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
    for (final (step, act) in [
      ('brief', null),
      ('ideas', toIdeas),
      ('store', toStore),
      ('week', toWeek),
      ('done', toDone),
    ]) {
      testWidgets(
        'step $step, $suffix',
        (tester) => capture(
          tester,
          'plan-week-$step-$suffix',
          const PlanWeekScreen(),
          brightness: brightness,
          act: act,
        ),
      );
    }
  }

  testWidgets(
    'the ideas without AI',
    (tester) => capture(
      tester,
      'plan-week-ideas-without-ai-light',
      const PlanWeekScreen(),
      refusal: const AiFailure(AiProblem.aiLimitReached),
      act: toIdeas,
    ),
  );

  testWidgets(
    'the week, dark at 200% text',
    (tester) => capture(
      tester,
      'plan-week-week-dark-200-percent-text',
      const PlanWeekScreen(),
      brightness: Brightness.dark,
      textScale: 2,
      act: toWeek,
    ),
  );

  testWidgets(
    'the basket, further down the week',
    (tester) => capture(
      tester,
      'plan-week-basket-light',
      const PlanWeekScreen(),
      act: (controller) async {
        await toWeek(controller);
        await tester.pumpAndSettle();
        await tester.drag(screenList(), const Offset(0, -2600));
      },
    ),
  );
}
