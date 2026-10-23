import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../groceries/model/product_match.dart';
import '../state/cart_push_controller.dart';
import 'cart_push_sheet.dart';

/// Where the member manages and makes the shop's link, for the flow to
/// send them.
typedef CartLinkPaths = ({String manage, String returnWhenLinked});

/// A push into one shop's cart, end to end: the result sheet open from the
/// first moment; when the member's link has run out (or never was) the
/// sheet says so, *Link* sends them to link, and the same items are pushed
/// again once they have. *Add to Checkers* and *Add to my Pick n Pay cart*
/// are both this (add-to-pnp ADR-0004).
abstract final class CartPushFlow {
  static Future<void> run(
    BuildContext context, {
    required ProductRetailer shop,
    required CartPushController push,
    required Map<String, String> itemNames,
    required CartLinkPaths links,
    Map<String, int> quantities = const {},
  }) async {
    final router = GoRouter.of(context);
    var pushing = push.push(itemNames.keys.toList(), quantities: quantities);
    while (true) {
      if (!context.mounted) break;
      var wantsLink = false;
      await showCartPushSheet(
        context: context,
        shop: shop,
        controller: push,
        itemNames: itemNames,
        onLink: () => wantsLink = true,
        onManageLink: () => unawaited(router.push<void>(links.manage)),
      );
      await pushing;
      if (!wantsLink) break;
      final linked = await router.push<bool>(links.returnWhenLinked);
      if (linked != true) break;
      pushing = push.retry();
    }
    push.reset();
  }
}
