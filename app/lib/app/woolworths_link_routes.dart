import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/add_to_woolworths/data/woolworths_account_sign_in.dart';
import '../features/add_to_woolworths/data/woolworths_directory.dart';
import '../features/add_to_woolworths/state/woolworths_link_controller.dart';
import '../features/add_to_woolworths/ui/woolworths_link_screen.dart';
import '../features/groceries/model/product_match.dart';
import '../features/subscriptions/model/premium_feature.dart';
import '../features/subscriptions/ui/premium_area.dart';
import '../shared/copy/woolworths_copy.dart';
import 'shop_link_redirect.dart';
import 'woolworths_link_route.dart';

/// Linking a Woolworths account (add-to-woolworths ADR-0001), in its own
/// file so the route table gains one line.
GoRoute woolworthsLinkRoute() => GoRoute(
  path: WoolworthsLinkRoute.path,
  redirect: shopLinkRedirect(ProductRetailer.woolworths),
  builder: (context, state) => PremiumArea(
    feature: PremiumFeature.shops,
    title: WoolworthsCopy.linkTitle,
    child: ChangeNotifierProvider(
      create: (context) => WoolworthsLinkController(
        directory: context.read<WoolworthsDirectory>(),
        signIn: context.read<WoolworthsAccountSignIn>(),
      ),
      child: WoolworthsLinkScreen(
        returnWhenLinked:
            state.uri.queryParameters[WoolworthsLinkRoute.returnParameter] ==
            '1',
      ),
    ),
  ),
);
