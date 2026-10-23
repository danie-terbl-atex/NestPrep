import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_place_resolver.dart';
import 'package:nestprep/features/add_to_checkers/model/retailer_product.dart';
import 'package:nestprep/features/add_to_checkers/state/cart_push_controller.dart';
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
import 'package:nestprep/shared/money/money.dart';
import 'package:provider/provider.dart';

import 'fake_checkers.dart';
import 'fake_live_location.dart';
import 'fake_plan_week.dart';
import 'fake_pnp.dart';
import 'household_fixtures.dart';
import 'lunch_fixtures.dart';
import 'lunch_planning_harness.dart';
import 'pump_screen.dart';

/// A Pick n Pay product for a test, as `PnpCatalogueParser` would read it.
RetailerProduct pnpProduct(
  String name, {
  required String code,
  int cents = 3499,
}) => RetailerProduct(
  retailer: ProductRetailer.pickNPay,
  id: code,
  storeId: 'GC13',
  articleCode: code.split('_').first,
  unitOfMeasure: code.split('_').last,
  name: name,
  price: Money(cents),
  isOnPromotion: false,
  isInStock: true,
  isSoldByWeight: false,
  ingredientsText: 'Milk',
  packCount: 6,
);

/// *Plan my week* at Pick n Pay with fakes behind every seam (lunch-box
/// ADR-0026, ADR-0027): Pick n Pay and Checkers catalogues, the shop choice,
/// the PnP directory and the one cart push — shared by the PnP plan-week
/// tests.
final class PlanWeekPnpFixture {
  PlanWeekPnpFixture() {
    choice = LunchShopChoice(
      preference: preference,
      householdId: Fixtures.householdId,
    );
    push = CartPushController(
      directory: directory,
      householdId: Fixtures.householdId,
    );
    pnp.byQuery['yoghurt'] = [
      pnpProduct('PnP yoghurt 6 x 100g', code: yoghurtCode),
    ];
    builder.reply = LunchWeekReply(
      lunches: const [
        ReplyLunch(
          childId: lwazi,
          day: 3,
          slot: LunchSlot.snack,
          ideaId: 'idea-1',
          productId: yoghurtCode,
        ),
      ],
      boxesPerPack: const {yoghurtCode: 6},
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
      catalogues: planWeekCatalogues(checkers, pickNPay: pnp),
      shopChoice: choice,
      isPnpOn: () => isPnpOn,
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
    harness.board.addListener(
      () => controller.followBoard(harness.board.board),
    );
  }

  static const lwazi = LunchFixtures.lwaziId;
  static const yoghurtCode = '000000000000539078_EA';

  final harness = LunchPlanningHarness();
  final checkers = FakeShopCatalogue();
  final pnp = FakeShopCatalogue();
  final aisle = FakeLunchAisleSource();
  final preference = FakeLunchShopPreference();
  final directory = FakePnpDirectory();
  final builder = FakeLunchWeekBuilder();
  late final LunchShopChoice choice;
  late final CartPushController push;
  late final PlanWeekController controller;
  var isPnpOn = true;

  Future<void> close() async {
    controller.dispose();
    push.dispose();
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
        ChangeNotifierProvider<CartPushController>.value(value: push),
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

  /// The brief at Pick n Pay, tapping each step's button up to [last].
  Future<void> run(WidgetTester tester, {String last = 'plan-week-use'}) async {
    await tapKey(tester, 'plan-week-shop-pickNPay');
    const steps = ['plan-week-ideas', 'plan-week-search', 'plan-week-use'];
    for (final step in steps.take(steps.indexOf(last) + 1)) {
      await tapKey(tester, step);
    }
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
