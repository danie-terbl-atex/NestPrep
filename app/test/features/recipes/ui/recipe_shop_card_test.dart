import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/data/retailer_catalogues.dart';
import 'package:nestprep/features/add_to_pnp/data/pnp_directory.dart';
import 'package:nestprep/features/groceries/data/grocery_repository.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/recipes/state/recipe_catalogue_controller.dart';
import 'package:nestprep/features/recipes/state/recipe_page_controller.dart';
import 'package:nestprep/features/recipes/ui/recipe_screen.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/state/household_entitlement.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_checkers.dart';
import '../../../support/fake_grocery_repository.dart';
import '../../../support/fake_pnp.dart';
import '../../../support/fake_subscriptions.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/recipe_fixtures.dart';
import '../../../support/recipe_harness.dart';

/// *Add to grocer* under a planned recipe's ingredients (recipes ADR-0005):
/// only once the recipe is on the week, marked premium for a free family,
/// and for a premium one a sheet that finds what is still needed at the shop
/// and puts it on the grocery list.
void main() {
  setUpAll(tz_data.initializeTimeZones);

  late RecipeHarness harness;
  late FakeCheckersCatalogue catalogue;
  late FakeGroceryRepository groceries;

  setUp(() {
    harness = RecipeHarness();
    catalogue = FakeCheckersCatalogue()
      ..products = [
        checkersProduct('Lean beef mince 1kg', id: 'm1', cents: 12999),
        checkersProduct('Beef mince 500g', id: 'm2', cents: 6999),
      ];
    groceries = FakeGroceryRepository();
  });

  tearDown(() async {
    await harness.close();
    await groceries.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    bool isPlanned = true,
    bool isPremium = true,
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    final width = scale > 1 ? 360.0 : 390.0;
    tester.view.physicalSize = Size(width * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final pnp = FakePnpDirectory();
    await pumpScreen(
      tester,
      ChangeNotifierProxyProvider<
        RecipeCatalogueController,
        RecipePageController
      >(
        create: (_) => RecipePageController(
          mealRepository: harness.meals,
          householdId: Fixtures.householdId,
          memberId: Fixtures.samMemberId,
          recipeId: 'bobotie',
          familySize: 4,
        ),
        update: (_, catalogue, page) => page!..followCatalogue(catalogue),
        child: RecipeScreen(onBack: () {}),
      ),
      providers: [
        ...harness.providers,
        ...fakeCheckersProviders(catalogue: catalogue),
        Provider<RetailerCatalogues>.value(
          value: RetailerCatalogues(checkers: catalogue, pickNPay: catalogue),
        ),
        Provider<PnpDirectory>.value(value: pnp),
        Provider<GroceryRepository>.value(value: groceries),
        if (isPremium)
          ChangeNotifierProvider<HouseholdEntitlement>(
            lazy: false,
            create: (_) => HouseholdEntitlement(
              entitlementRepository: FakeEntitlementRepository(
                initial: Entitlement(premiumUntil: DateTime.utc(2100)),
              ),
              householdId: Fixtures.householdId,
            ),
          ),
      ],
      brightness: brightness,
      textScale: scale,
    );
    harness.recipes.emitCatalogue(RecipeFixtures.catalogue);
    harness.meals.emitMeals([
      if (isPlanned)
        Meal.named(
          id: Meal.idForRecipe('bobotie'),
          name: 'Bobotie',
          addedBy: Fixtures.samMemberId,
        ),
    ]);
    await tester.pumpAndSettle();
  }

  Future<void> scrollToCard(WidgetTester tester) async {
    await tester.dragUntilVisible(
      find.text(RecipeShopCopy.action),
      find.byType(Scrollable).first,
      const Offset(0, -250),
    );
    await tester.ensureVisible(find.byKey(const ValueKey('recipe-shop-open')));
    await tester.pumpAndSettle();
  }

  testWidgets('is not offered until the recipe is on the week', (tester) async {
    await pump(tester, isPlanned: false);
    await tester.dragUntilVisible(
      find.text(RecipeCopy.stepsHeader),
      find.byType(Scrollable).first,
      const Offset(0, -250),
    );
    expect(find.text(RecipeShopCopy.cardTitle), findsNothing);
  });

  testWidgets('says it is premium to a free family', (tester) async {
    await pump(tester, isPremium: false);
    await scrollToCard(tester);

    expect(find.text(RecipeShopCopy.cardTitle), findsOneWidget);
    expect(find.text(RecipeShopCopy.premiumTag), findsOneWidget);
  });

  testWidgets('finds what is still needed and puts it on the list', (
    tester,
  ) async {
    await pump(tester);
    await scrollToCard(tester);
    expect(find.text(RecipeShopCopy.premiumTag), findsNothing);

    await tester.tap(find.byKey(const ValueKey('recipe-shop-open')));
    await tester.pumpAndSettle();

    expect(find.text(RecipeShopCopy.sheetTitle), findsWidgets);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byKey(const ValueKey('recipe-shop-0')), findsOneWidget);
    expect(find.text('Lean beef mince 1kg'), findsWidgets);
    expect(catalogue.searches.first.query, 'Beef mince');

    final add = find.byKey(const ValueKey('recipe-shop-list'));
    await tester.ensureVisible(add);
    await tester.tap(add);
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      groceries.emitItems(const []);
    }
    await tester.pumpAndSettle();

    expect(groceries.addedMatched, isNotEmpty);
    expect(groceries.addedMatched.first.name, 'Beef mince');
    expect(find.text(RecipeShopCopy.done), findsOneWidget);
  });

  testWidgets('fits at 200% text, 360 wide, in the dark', (tester) async {
    await pump(tester, brightness: Brightness.dark, scale: 2);
    await scrollToCard(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('recipe-shop-open')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
