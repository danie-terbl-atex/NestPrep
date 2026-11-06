import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_place_resolver.dart';
import 'package:nestprep/features/add_to_checkers/model/retailer_product.dart';
import 'package:nestprep/features/add_to_checkers/state/shop_carts.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/plan_week/data/shop_week_groceries.dart';
import 'package:nestprep/features/plan_week/model/lunch_idea.dart';
import 'package:nestprep/features/plan_week/model/lunch_ideas_reply.dart';
import 'package:nestprep/features/plan_week/model/lunch_week_reply.dart';
import 'package:nestprep/features/plan_week/state/lunch_shop_choice.dart';
import 'package:nestprep/features/plan_week/state/plan_week_controller.dart';
import 'package:nestprep/features/plan_week/state/shop_week_saver.dart';
import 'package:nestprep/features/plan_week/ui/plan_week_screen.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import 'checkers_fakes_for_plan_week.dart';
import 'fake_checkers.dart';
import 'fake_live_location.dart';
import 'fake_lunch_variety.dart';
import 'fake_plan_week.dart';
import 'household_fixtures.dart';
import 'lunch_fixtures.dart';
import 'lunch_planning_harness.dart';
import 'plan_week_pnp_fixture.dart';
import 'pump_screen.dart';

/// [shop]'s own word for a link that has run out.
AppFailure linkExpiredAt(ProductRetailer shop) => switch (shop) {
  ProductRetailer.checkers => const CheckersFailure(
    CheckersProblem.linkExpired,
  ),
  ProductRetailer.pickNPay => const PnpFailure(PnpProblem.linkExpired),
  ProductRetailer.woolworths => const WoolworthsFailure(
    WoolworthsProblem.linkExpired,
  ),
};

/// [shop]'s own word for being down.
AppFailure shopDownAt(ProductRetailer shop) => switch (shop) {
  ProductRetailer.checkers => const CheckersFailure(
    CheckersProblem.checkersDown,
  ),
  ProductRetailer.pickNPay => const PnpFailure(PnpProblem.pnpDown),
  ProductRetailer.woolworths => const WoolworthsFailure(
    WoolworthsProblem.woolworthsDown,
  ),
};

/// *Plan my week* at [shop] with fakes behind every seam (lunch-box
/// ADR-0026, ADR-0027): every shop's catalogue, the shop choice, and every
/// shop's cart push — one yoghurt at [shop] for Lwazi, the child with a
/// peanut allergy, its contents said unless [isContentsKnown] is false.
final class PlanWeekShopFixture {
  PlanWeekShopFixture({
    this.shop = ProductRetailer.pickNPay,
    bool isContentsKnown = true,
  }) : yoghurt = _yoghurtAt(shop, isContentsKnown: isContentsKnown) {
    choice = LunchShopChoice(
      preference: preference,
      familyPreference: FakeRetailerPreference(),
      householdId: Fixtures.householdId,
    );
    carts = ShopCarts.over(pushers, householdId: Fixtures.householdId);
    catalogues[shop]!.byQuery['yoghurt'] = [yoghurt];
    builder.reply = LunchWeekReply(
      lunches: [
        ReplyLunch(
          childId: lwazi,
          day: 3,
          slot: LunchSlot.snack,
          ideaId: 'idea-1',
          productId: yoghurt.id,
        ),
      ],
      boxesPerPack: {yoghurt.id: 6},
      budgetCents: 30000,
      dropped: 0,
      callsLeft: 11,
    );
    controller = PlanWeekController(
      drafter: FakeLunchIdeaDrafter()
        ..reply = LunchIdeasReply(
          ideas: [
            LunchIdea(
              id: 'idea-1',
              slot: LunchSlot.snack,
              idea: 'Fruit yoghurt',
              searchTerm: 'yoghurt',
              why: '',
              childIds: const [lwazi],
              excluded: const [],
              origin: IdeaOrigin.drafted,
            ),
          ],
          budgetCents: 30000,
          callsLeft: 12,
        ),
      aisleSource: aisle,
      weekBuilder: builder,
      catalogues: planWeekCatalogues(
        catalogues[ProductRetailer.checkers]!,
        pickNPay: catalogues[ProductRetailer.pickNPay],
        woolworths: catalogues[ProductRetailer.woolworths],
      ),
      shopChoice: choice,
      shopsOn: () => shopsOn,
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
      variety: lunchVarietyChoice(Fixtures.householdId),
      householdId: Fixtures.householdId,
      week: LunchFixtures.week,
    );
    harness.board.addListener(
      () => controller.followBoard(harness.board.board),
    );
  }

  static const lwazi = LunchFixtures.lwaziId;
  static const pnpYoghurtCode = '000000000000539078_EA';

  final ProductRetailer shop;
  final RetailerProduct yoghurt;
  final harness = LunchPlanningHarness();
  final catalogues = {
    for (final shop in ProductRetailer.values) shop: FakeShopCatalogue(),
  };
  final pushers = {
    for (final shop in ProductRetailer.values) shop: FakeCartPusher(),
  };
  final aisle = FakeLunchAisleSource();
  final preference = FakeLunchShopPreference();
  final builder = FakeLunchWeekBuilder();
  late final LunchShopChoice choice;
  late final ShopCarts carts;
  late final PlanWeekController controller;
  var shopsOn = ProductRetailer.values;

  /// [shop]'s catalogue, and its cart push.
  FakeShopCatalogue get catalogue => catalogues[shop]!;
  FakeCartPusher get pusher => pushers[shop]!;

  static RetailerProduct _yoghurtAt(
    ProductRetailer shop, {
    required bool isContentsKnown,
  }) => switch (shop) {
    ProductRetailer.pickNPay when isContentsKnown => pnpProduct(
      'PnP yoghurt 6 x 100g',
      code: pnpYoghurtCode,
    ),
    _ => planWeekProduct(
      '${shop.code} yoghurt 6 x 100g',
      id: '${shop.code}-yoghurt',
      cents: 3499,
      ingredients: isContentsKnown ? 'Milk' : null,
      packCount: 6,
      retailer: shop,
    ),
  };

  Future<void> close() async {
    controller.dispose();
    carts.dispose();
    choice.dispose();
    await harness.close();
  }

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
        Provider<ShopCarts>.value(value: carts),
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

  Future<void> tapKey(WidgetTester tester, String key) async {
    final target = find.byKey(ValueKey(key));
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  /// [shop] chosen in the brief — when there is a choice — then each step's
  /// button up to [last].
  Future<void> run(WidgetTester tester, {String last = 'plan-week-use'}) async {
    await choose(tester);
    const steps = ['plan-week-ideas', 'plan-week-search', 'plan-week-use'];
    for (final step in steps.take(steps.indexOf(last) + 1)) {
      await tapKey(tester, step);
    }
  }

  /// [shop] chosen in the brief, when the brief offers a choice.
  Future<void> choose(WidgetTester tester) async {
    if (shopsOn.length > 1) await tapKey(tester, 'plan-week-shop-${shop.code}');
  }

  /// A button that reads the grocery list first: tap it, then answer the
  /// list with [items].
  Future<void> tapThenList(
    WidgetTester tester,
    String key, {
    List<GroceryItem> items = const [],
    bool settle = true,
  }) async {
    final target = find.byKey(ValueKey(key));
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(target);
    await tester.pump();
    harness.groceries.emitItems(items);
    if (settle) await tester.pumpAndSettle();
  }
}
