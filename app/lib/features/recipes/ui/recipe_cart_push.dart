import 'package:flutter/widgets.dart';

import '../../../app/checkers_link_route.dart';
import '../../../app/pnp_link_route.dart';
import '../../add_to_checkers/state/cart_push_controller.dart';
import '../../add_to_checkers/ui/cart_push_flow.dart';
import '../../groceries/model/product_match.dart';
import '../../plan_week/model/shop_list_entry.dart';

/// [entries] — a recipe's lines on the grocery list, matched at [shop] — into
/// the member's own cart there through the one cart-push flow, linking first
/// when there is no link (recipes ADR-0005, add-to-pnp ADR-0004). Pick n Pay
/// is sent the packs; Checkers takes one of each, as it always has.
Future<void> pushRecipeToCart(
  BuildContext context, {
  required ProductRetailer shop,
  required String householdId,
  required CartPushController push,
  required List<ShopListEntry> entries,
}) => CartPushFlow.run(
  context,
  shop: shop,
  push: push,
  itemNames: {for (final entry in entries) entry.itemId: entry.name},
  quantities: shop == ProductRetailer.pickNPay
      ? ShopListEntry.packsByItem(entries)
      : const {},
  links: switch (shop) {
    ProductRetailer.pickNPay => (
      manage: PnpLinkRoute.pathFor(householdId),
      returnWhenLinked: PnpLinkRoute.pathFor(
        householdId,
        returnWhenLinked: true,
      ),
    ),
    _ => (
      manage: CheckersLinkRoute.pathFor(householdId),
      returnWhenLinked: CheckersLinkRoute.pathFor(
        householdId,
        returnWhenLinked: true,
      ),
    ),
  },
);
