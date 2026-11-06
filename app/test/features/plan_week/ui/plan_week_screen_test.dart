import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_place_resolver.dart';
import 'package:nestprep/features/add_to_checkers/model/retailer_shelf.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/plan_week/data/shop_week_groceries.dart';
import 'package:nestprep/features/plan_week/model/aisle_shelf.dart';
import 'package:nestprep/features/plan_week/model/left_out_reason.dart';
import 'package:nestprep/features/plan_week/model/lunch_idea.dart';
import 'package:nestprep/features/plan_week/model/lunch_ideas_reply.dart';
import 'package:nestprep/features/plan_week/model/lunch_week_reply.dart';
import 'package:nestprep/features/plan_week/model/packing_preference.dart';
import 'package:nestprep/features/plan_week/state/plan_week_controller.dart';
import 'package:nestprep/features/plan_week/state/shop_week_saver.dart';
import 'package:nestprep/features/plan_week/ui/plan_week_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/lunch_shop_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/checkers_fakes_for_plan_week.dart';
import '../../../support/fake_checkers.dart';
import '../../../support/fake_live_location.dart';
import '../../../support/fake_lunch_variety.dart';
import '../../../support/fake_plan_week.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_planning_harness.dart';
import '../../../support/pump_screen.dart';

/// *Plan my week from Checkers* on screen (lunch-box ADR-0012): each step
/// says what it is doing and what NestPrep left out and why; the working,
/// failing and empty states; and every step dark at 200% on a small phone.
const _yoghurtShelf = RetailerShelf.productList('69d4ebed9cccb04862bcb67f');

void main() {
  const lwazi = LunchFixtures.lwaziId;
  const ayanda = LunchFixtures.ayandaId;

  late LunchPlanningHarness harness;
  late FakeLunchIdeaDrafter drafter;
  final recipeSaver = FakeLunchRecipeSaver();
  late FakeLunchWeekBuilder builder;
  late FakeShopCatalogue shop;
  late FakeLunchAisleSource aisle;
  late PlanWeekController controller;

  setUp(() {
    harness = LunchPlanningHarness();
    drafter = FakeLunchIdeaDrafter()
      ..reply = LunchIdeasReply(
        ideas: [
          LunchIdea(
            id: 'idea-1',
            slot: LunchSlot.snack,
            idea: 'Fruit yoghurt',
            searchTerm: 'yoghurt',
            why: 'Both eat yoghurt',
            childIds: const [lwazi, ayanda],
            excluded: const [],
            origin: IdeaOrigin.drafted,
          ),
          LunchIdea(
            id: 'idea-2',
            slot: LunchSlot.snack,
            idea: 'Peanut butter crackers',
            searchTerm: 'crackers',
            why: '',
            childIds: const [ayanda],
            excluded: const [
              LeftOutReason(
                LeftOutKind.allergy,
                childId: lwazi,
                allergen: Allergen.peanut,
              ),
            ],
            origin: IdeaOrigin.drafted,
          ),
        ],
        budgetCents: 30000,
        callsLeft: 12,
      );
    builder = FakeLunchWeekBuilder()
      ..reply = LunchWeekReply(
        lunches: const [
          ReplyLunch(
            childId: lwazi,
            day: 3,
            slot: LunchSlot.snack,
            ideaId: 'idea-1',
            productId: 'yog',
          ),
        ],
        boxesPerPack: const {'yog': 6},
        budgetCents: 30000,
        dropped: 0,
        callsLeft: 11,
      );
    shop = FakeShopCatalogue()
      ..byQuery['yoghurt'] = [
        planWeekProduct(
          'Fruit yoghurt 6 x 100g',
          id: 'yog',
          cents: 3600,
          packCount: 6,
          ingredients: 'Milk',
        ),
        planWeekProduct('Peanut yoghurt', id: 'pyog', ingredients: 'Peanuts'),
        planWeekProduct('Plain yoghurt', id: 'gone', isInStock: false),
      ]
      ..byQuery['crackers'] = [
        planWeekProduct('Crackers', id: 'crack', ingredients: 'Wheat'),
      ];
    aisle = FakeLunchAisleSource();
    controller = PlanWeekController(
      drafter: drafter,
      aisleSource: aisle,
      weekBuilder: builder,
      catalogues: planWeekCatalogues(shop),
      shopChoice: planWeekShopChoice(Fixtures.householdId),
      shopsOn: planWeekShopsOn(),
      placeResolver: CheckersPlaceResolver(
        locationSource: FakeLocationSource(),
        areaPreference: FakeCheckersAreaPreference(),
      ),
      saver: ShopWeekSaver(
        lunchRepository: harness.lunch.repository,
        budgetRepository: harness.budgetRepository,
        recipeSaver: recipeSaver,
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
      ),
      groceries: ShopWeekGroceries(
        groceryRepository: harness.groceries,
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
      ),
      packingStore: FakePackingChoiceStore(),
      variety: lunchVarietyChoice(Fixtures.householdId),
      householdId: Fixtures.householdId,
      week: LunchFixtures.week,
    );
    harness.board.addListener(
      () => controller.followBoard(harness.board.board),
    );
  });

  tearDown(() async {
    controller.dispose();
    await harness.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
    Size size = const Size(420, 5000),
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      const PlanWeekScreen(),
      providers: [
        ...harness.lunch.providers,
        ...harness.providers,
        ChangeNotifierProvider<PlanWeekController>.value(value: controller),
        planWeekCartsProvider(),
      ],
      brightness: brightness,
      textScale: scale,
    );
    harness.lunch.emit();
    harness.emitPlanning(
      budget: const LunchBudget(id: 'weekly', cents: 30000, updatedBy: 'm'),
    );
    await tester.pumpAndSettle();
  }

  /// One shelf of Checkers' lunchbox aisle, with a yoghurt on it.
  void shelveYoghurt() {
    aisle.answer = const [
      AisleShelf(
        title: 'Yoghurt snack time',
        slot: LunchSlot.snack,
        list: _yoghurtShelf,
      ),
    ];
    shop.byShelf[_yoghurtShelf] = [
      planWeekProduct(
        'Aisle yoghurt 6 x 100g',
        id: 'ayog',
        ingredients: 'Milk',
      ),
    ];
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final target = find.byKey(ValueKey(key));
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  /// The brief, then on to the ideas.
  Future<void> toIdeas(WidgetTester tester) =>
      tapKey(tester, 'plan-week-ideas');

  testWidgets('the brief says what is kept out, the shop and the budget', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text(PlanWeekCopy.stepOf(1, 'Brief')), findsOneWidget);
    expect(find.textContaining('Kept out: Peanuts'), findsOneWidget);
    expect(find.text(PlanWeekCopy.likes('Grapes')), findsOneWidget);
    expect(find.text(PlanWeekCopy.aiNeverSees), findsOneWidget);
    expect(
      find.text(LunchShopCopy.shopNear(ProductRetailer.checkers, 'Cape Town')),
      findsOneWidget,
    );
    expect(find.text(PlanWeekCopy.budgetIs('R300')), findsOneWidget);
  });

  testWidgets('ideas show their working, then why one was struck out', (
    tester,
  ) async {
    await pump(tester);
    drafter.gate = Completer<void>();
    await tester.ensureVisible(find.byKey(const ValueKey('plan-week-ideas')));
    await tester.tap(find.byKey(const ValueKey('plan-week-ideas')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(PlanWeekCopy.draftingTitle), findsWidgets);
    drafter.gate!.complete();
    await tester.pumpAndSettle();
    expect(
      find.text(PlanWeekCopy.ideasHeadline(ProductRetailer.checkers)),
      findsOneWidget,
    );
    expect(find.text('Lwazi: contains peanuts'), findsOneWidget);
    expect(find.text(PlanWeekCopy.forChildren('Ayanda')), findsOneWidget);
  });

  testWidgets('a failed draft is said in words, with a retry', (tester) async {
    drafter.failWith = const PlanWeekFailure(PlanWeekProblem.weekNotPlannable);
    await pump(tester);
    await toIdeas(tester);
    expect(
      find.text(PlanWeekCopy.problem(PlanWeekProblem.weekNotPlannable)),
      findsOneWidget,
    );
    expect(find.text(AppCopy.retry), findsOneWidget);
  });

  testWidgets('the shop step counts the ideas while it works, then goes '
      'straight on to the week, the basket and the list', (tester) async {
    await pump(tester);
    await toIdeas(tester);
    shop.gate = Completer<void>();
    final search = find.byKey(const ValueKey('plan-week-search'));
    await tester.ensureVisible(search);
    await tester.tap(search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text(PlanWeekCopy.storeTitle(ProductRetailer.checkers)),
      findsWidgets,
    );
    expect(find.text(PlanWeekCopy.storeProgress(0, 2)), findsOneWidget);
    shop.gate!.complete();
    await tester.pumpAndSettle();

    expect(find.text(PlanWeekCopy.stepOf(4, 'The week')), findsOneWidget);
    expect(builder.packed.single.slots, {...LunchSlot.values});
    expect(find.text(PlanWeekCopy.weekHeadline('this week')), findsOneWidget);
    expect(find.text(PlanWeekCopy.basketHeadline), findsOneWidget);
    expect(find.text(LunchBudgetCopy.basketBuy(1)), findsOneWidget);
    expect(find.text(LunchBudgetCopy.basketRoom(6, 1)), findsOneWidget);

    await tapKey(tester, 'plan-week-use');
    expect(find.text(PlanWeekCopy.doneTitle), findsOneWidget);
    expect(harness.lunch.repository.writtenPicks, hasLength(1));
    expect(find.text(PlanWeekCopy.addToGroceries(1)), findsOneWidget);
  });

  testWidgets('names the week it plans — at the top, and over the week it '
      'builds', (tester) async {
    await pump(tester);
    expect(find.textContaining('This week · '), findsOneWidget);
    await toIdeas(tester);
    await tapKey(tester, 'plan-week-search');
    expect(find.text('Lunches for this week'), findsOneWidget);
  });

  testWidgets('the lunchbox aisle is read first and shown as Checkers\' own', (
    tester,
  ) async {
    shelveYoghurt();
    await pump(tester);
    await toIdeas(tester);
    expect(find.text('Yoghurt snack time'), findsOneWidget);
    expect(
      find.text(PlanWeekCopy.originAisle(ProductRetailer.checkers)),
      findsOneWidget,
    );
    expect(find.text(PlanWeekCopy.shelfKept(1)), findsOneWidget);
    expect(drafter.aisles.single.single.products, ['Aisle yoghurt 6 x 100g']);
    await tapKey(tester, 'plan-week-search');
    expect(builder.sent.single.first.ideaId, 'aisle-1');
    expect(shop.queries, isNot(contains('Yoghurt snack time')));
  });

  testWidgets('the brief chooses the compartments and how to pack, and the '
      'last compartment stays on', (tester) async {
    await pump(tester);
    expect(find.text(PlanWeekCopy.slotsHeader), findsOneWidget);
    expect(find.text(PlanWeekCopy.packingHeader), findsOneWidget);
    for (final slot in LunchSlot.values) {
      await tapKey(tester, 'plan-slot-${slot.name}');
    }
    expect(controller.packing.slots, {LunchSlot.treat});
    await tapKey(tester, 'plan-packing-airFryer');
    await toIdeas(tester);
    expect(drafter.packed.single.slots, {LunchSlot.treat});
    expect(drafter.packed.single.preferences, {PackingPreference.airFryer});
  });

  testWidgets('a shop run that kept nothing says so, and goes back to the '
      'ideas', (tester) async {
    shop.byQuery.clear();
    await pump(tester);
    await toIdeas(tester);
    await tapKey(tester, 'plan-week-search');
    expect(find.text(PlanWeekCopy.nothingKept), findsOneWidget);
    await tester.tap(find.text(PlanWeekCopy.back));
    await tester.pumpAndSettle();
    expect(
      find.text(PlanWeekCopy.ideasHeadline(ProductRetailer.checkers)),
      findsOneWidget,
    );
  });

  testWidgets('back from the week is the ideas', (tester) async {
    await pump(tester);
    await toIdeas(tester);
    await tapKey(tester, 'plan-week-search');
    expect(find.text(PlanWeekCopy.weekHeadline('this week')), findsOneWidget);
    final back = find.text(PlanWeekCopy.back);
    await tester.scrollUntilVisible(
      back,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(
      find.text(PlanWeekCopy.ideasHeadline(ProductRetailer.checkers)),
      findsOneWidget,
    );
  });

  testWidgets('every step renders dark at 200% text on a small phone', (
    tester,
  ) async {
    shelveYoghurt();
    await pump(
      tester,
      brightness: Brightness.dark,
      scale: 2,
      size: const Size(360, 800),
    );
    expect(tester.takeException(), isNull);
    for (final step in [
      'plan-week-ideas',
      'plan-week-search',
      'plan-week-use',
    ]) {
      await tapKey(tester, step);
      expect(tester.takeException(), isNull, reason: 'after $step');
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'scrolled after $step');
    }
  });
}
