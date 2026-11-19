import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/add_to_checkers/model/retailer_switch.dart';
import '../features/groceries/model/product_match.dart';
import '../shared/flags/feature_flags_controller.dart';
import 'household_route.dart';
import 'shops_route.dart';

/// Turns a link screen away to *Your shops* once the switches say [shop] is
/// off here (shops ADR-0004).
GoRouterRedirect shopLinkRedirect(ProductRetailer shop) =>
    (context, state) => switch (context.read<FeatureFlagsController?>()) {
      final flags?
          when flags.hasAnswered && !shopsOn(flags.isOn).contains(shop) =>
        ShopsRoute.pathFor(HouseholdRoute.idFrom(state)),
      _ => null,
    };
