import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/basket_compare_route.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_place_resolver.dart';
import 'package:nestprep/features/add_to_checkers/data/retailer_catalogues.dart';
import 'package:nestprep/features/basket_compare/state/basket_compare_controller.dart';
import 'package:nestprep/features/basket_compare/ui/basket_compare_screen.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/basket_compare_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/basket_compare_fixture.dart';
import '../../../support/checkers_grocery_harness.dart';
import '../../../support/fake_checkers.dart';
import '../../../support/fake_grocery_repository.dart';
import '../../../support/fake_live_location.dart';
import '../../../support/fake_plan_week.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/plan_week_pnp_fixture.dart';
import '../../../support/pump_screen.dart';

/// *Compare shops* over its controller and fakes, pushed over the grocery
/// list as the route does (basket-compare ADR-0001).
void main() {
  const listText = 'the grocery list';

  late FakeShopCatalogue checkersShop;
  late FakeShopCatalogue pnpShop;
  late FakeGroceryRepository groceries;
  late BasketCompareController controller;

  setUp(() {
    checkersShop = FakeShopCatalogue()
      ..byQuery['milk'] = [checkersProduct('Clover Fresh Full Cream Milk 2L')]
      ..byQuery['hummus'] = [
        checkersProduct('Roasted Red Pepper Hummus 250g', id: 'hummus'),
      ];
    pnpShop = FakeShopCatalogue()
      ..byQuery['milk'] = [
        pnpProduct('PnP Full Cream Milk 2L', code: '1_EA', cents: 3299),
      ];
    groceries = FakeGroceryRepository();
    controller = BasketCompareController(
      catalogues: RetailerCatalogues({
        ProductRetailer.checkers: checkersShop,
        ProductRetailer.pickNPay: pnpShop,
      }),
      placeResolver: CheckersPlaceResolver(
        locationSource: FakeLocationSource(),
        areaPreference: FakeCheckersAreaPreference(),
      ),
      groceryRepository: groceries,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      shops: bothShops,
    );
    addTearDown(() async {
      controller.dispose();
      await groceries.close();
    });
  });

  Future<void> open(
    WidgetTester tester, {
    HouseholdView? view,
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    controller.start();
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const Text(listText)),
        GoRoute(
          path: BasketCompareRoute.path,
          builder: (context, state) =>
              ChangeNotifierProvider<BasketCompareController>.value(
                value: controller,
                child: const BasketCompareScreen(),
              ),
        ),
      ],
    );
    await pumpRouter(
      tester,
      router: router,
      providers: const [],
      view: view,
      brightness: brightness,
      textScale: scale,
    );
    unawaited(router.push(BasketCompareRoute.pathFor(Fixtures.householdId)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    groceries.emitItems([
      const GroceryItem(
        id: 'milk',
        name: 'milk',
        addedBy: Fixtures.samMemberId,
        productMatch: pickedMilk,
      ),
      const GroceryItem(
        id: 'hummus',
        name: 'hummus',
        addedBy: Fixtures.samMemberId,
      ),
    ]);
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final target = find.byKey(ValueKey(key));
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('shows the verdict and what Pick n Pay does not have', (
    tester,
  ) async {
    await open(tester);
    expect(find.text(BasketCompareCopy.title), findsOneWidget);
    expect(find.text(BasketCompareCopy.cheapest(pnp)), findsOneWidget);
    expect(find.text(BasketCompareCopy.notAt(pnp)), findsOneWidget);
  });

  testWidgets('using a shop asks before replacing a pick, writes the shop\'s '
      'products and goes back to the list', (tester) async {
    await open(tester);
    await tapKey(tester, 'use-pickNPay');
    expect(find.text(BasketCompareCopy.confirmBody(pnp, 1)), findsOneWidget);
    await tester.tap(find.text(BasketCompareCopy.confirmUse(pnp)));
    await tester.pumpAndSettle();

    expect(groceries.matchesSet.single.itemId, 'milk');
    expect(groceries.matchesSet.single.match.retailer, pnp);
    expect(find.text(listText), findsOneWidget);
  });

  testWidgets('keeping the picks writes nothing and stays', (tester) async {
    await open(tester);
    await tapKey(tester, 'use-pickNPay');
    await tester.tap(find.text(BasketCompareCopy.keepPicks));
    await tester.pumpAndSettle();

    expect(groceries.matchesSet, isEmpty);
    expect(find.text(BasketCompareCopy.title), findsOneWidget);
  });

  testWidgets('a refused write shows copy and stays', (tester) async {
    await open(tester);
    groceries.failWritesWith = const PermissionDeniedFailure();
    await tapKey(tester, 'use-checkers');

    await tester.scrollUntilVisible(
      find.text(AppCopy.failure(const PermissionDeniedFailure())),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(listText), findsNothing);
  });

  testWidgets('somebody who may only read the list compares but cannot use', (
    tester,
  ) async {
    await open(
      tester,
      view: Fixtures.helperView(AccessGrant.uniform(AccessLevel.view)),
    );
    expect(find.text(BasketCompareCopy.cheapest(pnp)), findsOneWidget);
    expect(find.text(BasketCompareCopy.useTitle), findsNothing);
    expect(find.byKey(const ValueKey('use-pickNPay')), findsNothing);
  });

  testWidgets('fits a 360-wide phone at 200% text in the dark', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await open(tester, brightness: Brightness.dark, scale: 2);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -4000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
