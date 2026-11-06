import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/add_to_checkers/data/checkers_directory.dart';
import '../features/add_to_checkers/data/match_as_you_type_preference.dart';
import '../features/add_to_checkers/data/retailer_preference.dart';
import '../features/add_to_checkers/model/retailer_switch.dart';
import '../features/add_to_checkers/state/retailer_choice_controller.dart';
import '../features/add_to_pnp/data/pnp_directory.dart';
import '../features/add_to_woolworths/data/woolworths_directory.dart';
import '../features/household/model/household_area.dart';
import '../features/household/model/household_view.dart';
import '../features/shops/state/shops_controller.dart';
import '../features/shops/ui/shops_screen.dart';
import '../shared/flags/feature_flags_controller.dart';
import 'household_route.dart';
import 'shops_route.dart';

/// *Your shops*, in its own file so the route table gains one line. A member
/// who may not add to the grocery list is asked about no shop at all.
GoRoute shopsRoute() => GoRoute(
  path: ShopsRoute.path,
  builder: (context, state) {
    final householdId = HouseholdRoute.idFrom(state);
    final flags = context.read<FeatureFlagsController>();
    final canShop = context.read<HouseholdView>().permissions.canEdit(
      HouseholdArea.groceries,
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ShopsController(
            checkers: context.read<CheckersDirectory>(),
            pnp: context.read<PnpDirectory>(),
            woolworths: context.read<WoolworthsDirectory>(),
            shopsOn: canShop ? () => shopsOn(flags.isOn) : () => const [],
            switches: flags,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => RetailerChoiceController(
            preference: context.read<RetailerPreference>(),
            matchAsYouType: context.read<MatchAsYouTypePreference>(),
            householdId: householdId,
            shopsOn: () => shopsOn(flags.isOn),
          ),
        ),
      ],
      child: const ShopsScreen(),
    );
  },
);
