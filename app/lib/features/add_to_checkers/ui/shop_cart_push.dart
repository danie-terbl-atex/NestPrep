import 'package:flutter/widgets.dart';

import '../../groceries/model/product_match.dart';
import '../../plan_week/model/shop_list_entry.dart';
import '../state/cart_push_controller.dart';
import 'cart_push_flow.dart';
import 'shop_cart_links.dart';

/// [entries] — lines on the grocery list matched at [shop] — into the
/// member's own cart there through the one cart-push flow, linking first
/// when there is no link (add-to-pnp ADR-0004, ADR-0007). A shop that takes
/// packs is sent them. Shared by a recipe's *Add to grocer* (recipes
/// ADR-0005) and *Plan my week*'s done step and brief (lunch-box ADR-0026
/// §6, ADR-0027).
Future<void> pushToShopCart(
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
  quantities: takesPackQuantities(shop)
      ? ShopListEntry.packsByItem(entries)
      : const {},
  links: cartLinkPathsFor(shop, householdId),
);
