import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/checkers_link_route.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_place_resolver.dart';
import 'package:nestprep/features/add_to_checkers/data/retailer_catalogues.dart';
import 'package:nestprep/features/add_to_checkers/model/retailer_switch.dart';
import 'package:nestprep/features/add_to_checkers/state/cart_push_controller.dart';
import 'package:nestprep/features/add_to_checkers/state/checkers_link_controller.dart';
import 'package:nestprep/features/add_to_checkers/state/product_finder.dart';
import 'package:nestprep/features/add_to_checkers/state/product_match_controller.dart';
import 'package:nestprep/features/add_to_checkers/state/product_type_ahead_controller.dart';
import 'package:nestprep/features/add_to_checkers/state/retailer_choice_controller.dart';
import 'package:nestprep/features/add_to_checkers/state/shop_carts.dart';
import 'package:nestprep/features/add_to_checkers/ui/checkers_link_screen.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/groceries/state/grocery_list_controller.dart';
import 'package:nestprep/features/groceries/ui/grocery_list_screen.dart';
import 'package:nestprep/shared/flags/feature_flag.dart';
import 'package:nestprep/shared/flags/feature_flags.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:nestprep/shared/money/money.dart';
import 'package:provider/provider.dart';

import 'fake_checkers.dart';
import 'fake_feature_flag_source.dart';
import 'fake_live_location.dart';
import 'fake_plan_week.dart';
import 'fake_pnp.dart';
import 'fake_woolworths.dart';
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
    finder = ProductFinder(
      catalogues: RetailerCatalogues({
        ProductRetailer.checkers: catalogue,
        ProductRetailer.pickNPay: pnpCatalogue,
        ProductRetailer.woolworths: woolworthsCatalogue,
      }),
      placeResolver: CheckersPlaceResolver(
        locationSource: FakeLocationSource(),
        areaPreference: FakeCheckersAreaPreference(),
      ),
      householdId: Fixtures.householdId,
      ranker: ranker,
    );
    matches = ProductMatchController(
      finder: finder,
      groceryRepository: list.repository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      debounce: Duration.zero,
    );
    typeAhead = ProductTypeAheadController(
      finder: finder,
      debounce: Duration.zero,
    );
    push = CartPushController(
      directory: directory,
      householdId: Fixtures.householdId,
    );
    pnpPush = CartPushController(
      directory: pnpDirectory,
      householdId: Fixtures.householdId,
    );
    woolworthsPush = CartPushController(
      directory: woolworthsDirectory,
      householdId: Fixtures.householdId,
    );
    retailers = RetailerChoiceController(
      preference: retailerPreference,
      matchAsYouType: retailerPreference,
      householdId: Fixtures.householdId,
      shopsOn: () => shopsOn(flags.isOn),
    );
    addTearDown(() {
      matches.dispose();
      typeAhead.dispose();
      retailers.dispose();
      carts.dispose();
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
  final pnpCatalogue = FakeShopCatalogue();
  final pnpDirectory = FakePnpDirectory();
  final woolworthsCatalogue = FakeShopCatalogue();
  final woolworthsDirectory = FakeWoolworthsDirectory();
  late final ProductFinder finder;
  late final ProductMatchController matches;
  late final ProductTypeAheadController typeAhead;

  /// Ranks nothing unless a test gives it fits.
  final ranker = FakeProductMatchRanker();

  /// The Checkers cart push.
  late final CartPushController push;
  late final CartPushController pnpPush;
  late final CartPushController woolworthsPush;

  late final carts = ShopCarts({
    ProductRetailer.checkers: push,
    ProductRetailer.pickNPay: pnpPush,
    ProductRetailer.woolworths: woolworthsPush,
  });

  /// The switches the pumped screen sees; set by [pump].
  FeatureFlags flags = TestFlags.on;
  final retailerPreference = FakeRetailerPreference();
  late final RetailerChoiceController retailers;

  /// [isOn] every switch, less those in [off].
  Future<void> pump(
    WidgetTester tester, {
    bool isOn = true,
    Set<FeatureFlag> off = const {},
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) {
    flags = FeatureFlags(
      defaultOn: isOn,
      stored: {for (final flag in off) flag: false},
    );
    return _pump(tester, brightness: brightness, scale: scale);
  }

  Future<void> _pump(
    WidgetTester tester, {
    required Brightness brightness,
    required double scale,
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
      ChangeNotifierProvider<ProductTypeAheadController>.value(
        value: typeAhead,
      ),
      Provider<ShopCarts>.value(value: carts),
      ChangeNotifierProvider<RetailerChoiceController>.value(value: retailers),
      ChangeNotifierProvider<FeatureFlagsController>(
        create: (_) => testFlagsController(flags),
      ),
    ],
    brightness: brightness,
    textScale: scale,
  );
}
