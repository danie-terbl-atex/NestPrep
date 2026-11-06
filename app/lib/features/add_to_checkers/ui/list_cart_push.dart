import 'package:flutter/widgets.dart';

import '../../groceries/model/grocery_item.dart';
import '../../groceries/model/product_match.dart';
import '../../plan_week/model/packs_in_quantity.dart';
import '../state/cart_push_controller.dart';
import 'cart_push_flow.dart';
import 'shop_cart_links.dart';

/// [items] — unbought, matched at [shop] — into the member's own cart at that
/// shop through the one cart-push flow, linking first when needed (the
/// Checkers build contract, add-to-pnp ADR-0004, ADR-0007). A shop that takes
/// packs is sent each item's, read from its quantity words.
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
  quantities: takesPackQuantities(shop)
      ? {for (final item in items) item.id: packsInQuantity(item.quantity)}
      : const {},
  links: cartLinkPathsFor(shop, householdId),
);
