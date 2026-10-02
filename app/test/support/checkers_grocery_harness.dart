import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/checkers_link_route.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_place_resolver.dart';
import 'package:nestprep/features/add_to_checkers/state/checkers_link_controller.dart';
import 'package:nestprep/features/add_to_checkers/state/checkers_push_controller.dart';
import 'package:nestprep/features/add_to_checkers/state/product_match_controller.dart';
import 'package:nestprep/features/add_to_checkers/state/retailer_choice_controller.dart';
import 'package:nestprep/features/add_to_checkers/ui/checkers_link_screen.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/groceries/state/grocery_list_controller.dart';
import 'package:nestprep/features/groceries/ui/grocery_list_screen.dart';
import 'package:nestprep/shared/money/money.dart';
import 'package:provider/provider.dart';

import 'fake_checkers.dart';
import 'fake_feature_flag_source.dart';
import 'fake_live_location.dart';
import 'grocery_list_harness.dart';
import 'household_fixtures.dart';
import 'pump_screen.dart';

/// A product somebody picked, as the list reads it back.
const pickedMilk = ProductMatch(
  retailer: ProductRetailer.checkers,
  productId: '5d3af63bf434cf8420737dd6',
  articleCode: '10136729EA',
  unitOfMeasure: 'EA',
  name: 'Clover Fresh Full Cream Milk 2L',
  brand: 'Clover',
  price: Money(3799),
  pickedBy: Fixtures.samMemberId,
);

/// The grocery tab with the Checkers controllers beside the list's, as the
/// route builds it, over fakes: the catalogue, the callables and the phone.
/// The link screen is in the route table so *Add to Checkers* can go there.
final class CheckersGroceryHarness {
  CheckersGroceryHarness() {
    matches = ProductMatchController(
      catalogue: catalogue,
      placeResolver: CheckersPlaceResolver(
        locationSource: FakeLocationSource(),
        areaPreference: FakeCheckersAreaPreference(),
      ),
      groceryRepository: list.repository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      debounce: Duration.zero,
    );
    push = CheckersPushController(
      directory: directory,
      householdId: Fixtures.householdId,
    );
    retailers = RetailerChoiceController(
      preference: retailerPreference,
      householdId: Fixtures.householdId,
    );
    addTearDown(() {
      matches.dispose();
      push.dispose();
      retailers.dispose();
    });
  }

  final list = GroceryListHarness();
  final catalogue = FakeCheckersCatalogue()
    ..products = [
      checkersProduct('Clover Fresh Full Cream Milk 2L', oldCents: 4299),
      checkersProduct(
        'Darling Fresh Full Cream Milk 2L',
        id: '5db2b6a9280e5b57ebe9a222',
        brand: 'Darling',
        cents: 3299,
        isOnPromotion: true,
        isInStock: false,
      ),
    ];
  final directory = FakeCheckersDirectory();
  late final ProductMatchController matches;
  late final CheckersPushController push;
  final retailerPreference = FakeRetailerPreference();
  late final RetailerChoiceController retailers;

  Future<void> pump(
    WidgetTester tester, {
    bool isOn = true,
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) => pumpRouter(
    tester,
    router: GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => GroceryListScreen(onSelectTab: (_) {}),
        ),
        GoRoute(
          path: CheckersLinkRoute.path,
          builder: (context, state) => ChangeNotifierProvider(
            create: (_) => CheckersLinkController(directory: directory),
            child: const CheckersLinkScreen(returnWhenLinked: true),
          ),
        ),
      ],
    ),
    providers: [
      ChangeNotifierProvider<GroceryListController>.value(
        value: list.controller,
      ),
      list.plans.provider,
      ChangeNotifierProvider<ProductMatchController>.value(value: matches),
      ChangeNotifierProvider<CheckersPushController>.value(value: push),
      ChangeNotifierProvider<RetailerChoiceController>.value(value: retailers),
      featureFlagsProvider(defaultOn: isOn),
    ],
    brightness: brightness,
    textScale: scale,
  );
}
