import 'package:flutter/widgets.dart';

import '../../../app/checkers_link_route.dart';
import '../../../app/pnp_link_route.dart';
import '../../groceries/model/grocery_item.dart';
import '../../groceries/model/product_match.dart';
import '../../plan_week/model/packs_in_quantity.dart';
import '../state/cart_push_controller.dart';
import 'cart_push_flow.dart';

/// [items] — unbought, matched at [shop] — into the member's own cart at that
/// shop through the one cart-push flow, linking first when needed (the
/// Checkers build contract, add-to-pnp ADR-0004, ADR-0007). Pick n Pay is
/// sent each item's packs, read from its quantity words; Checkers takes one
/// of each, as it always has.
Future<void> pushListToCart(
  BuildContext context, {
  required ProductRetailer shop,
  required String householdId,
  required CartPushController push,
  required List<GroceryItem> items,
}) => CartPushFlow.run(
  context,
  shop: shop,
  push: push,
  itemNames: {for (final item in items) item.id: item.name},
  quantities: shop == ProductRetailer.pickNPay
      ? {for (final item in items) item.id: packsInQuantity(item.quantity)}
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
