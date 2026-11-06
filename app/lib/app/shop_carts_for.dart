import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../features/add_to_checkers/data/checkers_directory.dart';
import '../features/add_to_checkers/state/shop_carts.dart';
import '../features/add_to_pnp/data/pnp_directory.dart';
import '../features/add_to_woolworths/data/woolworths_directory.dart';
import '../features/groceries/model/product_match.dart';

/// Every connected shop's cart push for [householdId], over its callables
/// in the app-wide graph. The caller disposes them.
ShopCarts shopCartsFor(BuildContext context, String householdId) =>
    ShopCarts.over({
      ProductRetailer.checkers: context.read<CheckersDirectory>(),
      ProductRetailer.pickNPay: context.read<PnpDirectory>(),
      ProductRetailer.woolworths: context.read<WoolworthsDirectory>(),
    }, householdId: householdId);
