import 'package:flutter/widgets.dart';

import '../../../app/pnp_link_route.dart';
import '../../add_to_checkers/state/cart_push_controller.dart';
import '../../add_to_checkers/ui/cart_push_flow.dart';
import '../../groceries/model/product_match.dart';
import '../model/shop_list_entry.dart';

/// [entries] — items on the grocery list matched at Pick n Pay, with their
/// packs — into the member's own Pick n Pay cart through the one cart-push
/// flow, linking first when there is no link (add-to-pnp ADR-0004). Shared
/// by the done step and the brief (lunch-box ADR-0026 §6, ADR-0027).
Future<void> pushToPnpCart(
  BuildContext context, {
  required String householdId,
  required CartPushController push,
  required List<ShopListEntry> entries,
}) => CartPushFlow.run(
  context,
  shop: ProductRetailer.pickNPay,
  push: push,
  itemNames: {for (final entry in entries) entry.itemId: entry.name},
  quantities: ShopListEntry.packsByItem(entries),
  links: (
    manage: PnpLinkRoute.pathFor(householdId),
    returnWhenLinked: PnpLinkRoute.pathFor(householdId, returnWhenLinked: true),
  ),
);
