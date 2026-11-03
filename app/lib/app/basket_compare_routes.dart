import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/add_to_checkers/data/checkers_area_preference.dart';
import '../features/add_to_checkers/data/checkers_place_resolver.dart';
import '../features/add_to_checkers/data/product_match_ranker.dart';
import '../features/add_to_checkers/data/retailer_catalogues.dart';
import '../features/add_to_checkers/model/retailer_switch.dart';
import '../features/basket_compare/state/basket_compare_controller.dart';
import '../features/basket_compare/ui/basket_compare_screen.dart';
import '../features/groceries/data/grocery_repository.dart';
import '../features/live_location/data/location_source.dart';
import '../shared/flags/feature_flags_controller.dart';
import 'basket_compare_route.dart';
import 'household_route.dart';
import 'viewer_member.dart';

/// *Compare shops* over the grocery list (basket-compare ADR-0001), at the
/// connected shops switched on.
GoRoute basketCompareRoute() => GoRoute(
  path: BasketCompareRoute.path,
  builder: (context, state) => ChangeNotifierProvider(
    create: (context) => BasketCompareController(
      catalogues: context.read<RetailerCatalogues>(),
      placeResolver: CheckersPlaceResolver(
        locationSource: context.read<LocationSource>(),
        areaPreference: context.read<CheckersAreaPreference>(),
      ),
      groceryRepository: context.read<GroceryRepository>(),
      householdId: HouseholdRoute.idFrom(state),
      memberId: viewerMemberIdOf(context),
      shops: shopsOn(context.read<FeatureFlagsController>().isOn),
      ranker: context.read<ProductMatchRanker>(),
    )..start(),
    child: const BasketCompareScreen(),
  ),
);
