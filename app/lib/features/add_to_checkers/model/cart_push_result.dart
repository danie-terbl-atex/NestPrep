import 'package:flutter/foundation.dart';

import '../../../shared/money/money.dart';

/// Why the server left an item out of the cart.
enum CartSkipReason {
  noMatch('no-match'),
  outOfStock('out-of-stock'),
  notFound('not-found'),
  weighedItem('weighed-item'),

  /// The cart would pass its item cap (Pick n Pay, add-to-pnp ADR-0004).
  cartFull('cart-full'),

  /// The shop had fewer than the week needs (Pick n Pay, add-to-pnp ADR-0004).
  lowStock('low-stock'),

  /// The shop limits how many one order may hold (Pick n Pay).
  maxQuantity('max-quantity'),

  /// The shop turned that one line down; the rest still went in (Pick n Pay).
  shopRefused('shop-refused'),

  /// A reason this build does not know: a Function deployed after it.
  unrecognised('');

  const CartSkipReason(this.code);

  final String code;

  static CartSkipReason fromCode(String code) =>
      values.where((reason) => reason.code == code).firstOrNull ?? unrecognised;
}

@immutable
final class CartAddedLine {
  const CartAddedLine({
    required this.itemId,
    required this.productId,
    required this.name,
    required this.price,
  });

  final String itemId;
  final String productId;
  final String name;
  final Money price;
}

@immutable
final class CartSkippedLine {
  const CartSkippedLine({required this.itemId, required this.reason});

  final String itemId;
  final CartSkipReason reason;
}

/// What a cart push (`checkersPushToCart`, `pnpPushToCart`) did: what went
/// into the member's cart, what did not and why, and the cart as the shop
/// counts it afterwards.
@immutable
final class CartPushResult {
  const CartPushResult({
    required this.added,
    required this.skipped,
    required this.cartItemCount,
    required this.cartTotal,
  });

  final List<CartAddedLine> added;
  final List<CartSkippedLine> skipped;
  final int cartItemCount;
  final Money cartTotal;

  bool get addedNothing => added.isEmpty;
}
