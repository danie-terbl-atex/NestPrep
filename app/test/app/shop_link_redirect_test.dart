import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/checkers_link_route.dart';
import 'package:nestprep/app/checkers_link_routes.dart';
import 'package:nestprep/app/pnp_link_route.dart';
import 'package:nestprep/app/pnp_link_routes.dart';
import 'package:nestprep/app/shops_route.dart';
import 'package:nestprep/app/woolworths_link_route.dart';
import 'package:nestprep/app/woolworths_link_routes.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';

import '../support/household_fixtures.dart';
import '../support/pump_screen.dart';
import '../support/test_flags.dart';

void main() {
  const h = Fixtures.householdId;
  final links = {
    ProductRetailer.checkers: (CheckersLinkRoute.pathFor(h), checkersLinkRoute),
    ProductRetailer.pickNPay: (PnpLinkRoute.pathFor(h), pnpLinkRoute),
    ProductRetailer.woolworths: (
      WoolworthsLinkRoute.pathFor(h),
      woolworthsLinkRoute,
    ),
  };

  for (final MapEntry(key: shop, value: (path, route)) in links.entries) {
    testWidgets('linking ${shop.code} turns back to Your shops while it is '
        'switched off on this platform, its cloud switch on or not', (
      tester,
    ) async {
      final connected = ProductRetailer.debugSwitchOverride;
      ProductRetailer.debugSwitchOverride = (each, platform) =>
          each == shop ? ShopSwitch.off : ShopSwitch.cloud;
      addTearDown(() => ProductRetailer.debugSwitchOverride = connected);
      final flags = testFlagsController(TestFlags.on);
      addTearDown(flags.dispose);
      await tester.pump();
      final router = GoRouter(
        initialLocation: path,
        routes: [
          GoRoute(
            path: ShopsRoute.path,
            builder: (context, state) => const Text('your shops'),
          ),
          route(),
        ],
      );
      addTearDown(router.dispose);

      await pumpRouter(
        tester,
        router: router,
        providers: [
          ChangeNotifierProvider<FeatureFlagsController>.value(value: flags),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('your shops'), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        ShopsRoute.pathFor(h),
      );
    });
  }
}
