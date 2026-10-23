import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_place_resolver.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_price.dart';
import 'package:nestprep/features/lunch_box/model/lunch_seed_catalogue.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/plan_week/data/shop_week_groceries.dart';
import 'package:nestprep/features/plan_week/model/left_out_reason.dart';
import 'package:nestprep/features/plan_week/model/lunch_idea.dart';
import 'package:nestprep/features/plan_week/model/lunch_ideas_reply.dart';
import 'package:nestprep/features/plan_week/model/lunch_week_reply.dart';
import 'package:nestprep/features/plan_week/state/plan_week_controller.dart';
import 'package:nestprep/features/plan_week/state/shop_week_saver.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../test/support/checkers_fakes_for_plan_week.dart';
import '../test/support/fake_checkers.dart';
import '../test/support/fake_live_location.dart';
import '../test/support/fake_plan_week.dart';
import '../test/support/household_fixtures.dart';
import '../test/support/lunch_fixtures.dart';
import '../test/support/lunch_planning_harness.dart';
import 'review_press.dart';

// The household, the model's answers and the shop for *Plan my week*'s
// design-review pictures (lunch-box ADR-0012), and the shutter that renders
// a step of it. Shared by the steps' press and Twig's
// (`plan_week_design_review_test.dart`, `plan_week_twig_design_review_test.dart`;
// `ENG-02`).

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
    planWeekProduct('Bakers Peanut Crackers', id: 'pbc', ingredients: 'Wheat'),
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

/// The press being run, so a step can read budget mode's week the way the
/// ideas panel does.
late LunchPlanningHarness current;

Future<void> capturePlanWeek(
  WidgetTester tester,
  String name,
  Widget screen, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  AppFailure? refusal,
  AppFailure? buildRefusal,
  Future<void> Function(PlanWeekController controller)? act,
  // Hold the model's answer, for a picture of the step waiting on it.
  bool isDraftHeld = false,
  bool isBuildHeld = false,
}) async {
  final harness = current = LunchPlanningHarness();
  final drafter = FakeLunchIdeaDrafter()
    ..reply = ideas
    ..failWith = refusal
    ..gate = isDraftHeld ? Completer<void>() : null;
  final builder = FakeLunchWeekBuilder()
    ..reply = week
    ..failWith = buildRefusal
    ..gate = isBuildHeld ? Completer<void>() : null;
  // A held answer is let go before the test ends, so nothing is left
  // pending (the vault lesson on settling a promise not awaited).
  addTearDown(() {
    drafter.gate?.complete();
    builder.gate?.complete();
  });
  final shop = FakeShopCatalogue();
  stock(shop);
  final controller = PlanWeekController(
    drafter: drafter,
    aisleSource: FakeLunchAisleSource(),
    weekBuilder: builder,
    catalogues: planWeekCatalogues(shop),
    shopChoice: planWeekShopChoice(Fixtures.householdId),
    isPnpOn: () => false,
    placeResolver: CheckersPlaceResolver(
      locationSource: FakeLocationSource(),
      areaPreference: FakeCheckersAreaPreference(),
    ),
    saver: ShopWeekSaver(
      lunchRepository: harness.lunch.repository,
      budgetRepository: harness.budgetRepository,
      recipeSaver: FakeLunchRecipeSaver(),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    ),
    groceries: ShopWeekGroceries(
      groceryRepository: harness.groceries,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    ),
    packingStore: FakePackingChoiceStore(),
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
        // Lwazi's Monday wrap is priced, so the week holds some of the
        // budget before the plan adds anything (lunch-box ADR-0019).
        prices: [
          LunchPrice(
            id: library.firstWhere((i) => i.seedKey == 'chicken-mayo').id,
            cents: 4500,
            updatedBy: 'm',
          ),
        ],
        budget: const LunchBudget(id: 'weekly', cents: 40000, updatedBy: 'm'),
      );
      follow();
    },
    brightness: brightness,
    textScale: textScale,
    act: act == null ? null : () => act(controller),
  );
}

Future<void> toIdeas(PlanWeekController controller) => controller.draftIdeas();

Future<void> toWeek(PlanWeekController controller) async {
  await controller.draftIdeas();
  await controller.searchStore(
    budgetWeek: switch (current.budget.week) {
      AsyncData(:final value) => value,
      _ => null,
    },
  );
}

Future<void> toDone(PlanWeekController controller) async {
  await toWeek(controller);
  await controller.use();
}
