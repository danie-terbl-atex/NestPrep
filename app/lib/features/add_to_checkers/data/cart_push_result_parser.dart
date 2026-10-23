import '../../../shared/money/money.dart';
import '../model/cart_push_result.dart';

/// Reads a cart push's answer (`checkersPushToCart`, `pnpPushToCart` — one
/// shape) into a typed result (`ENG-09`). Null when the answer is not the
/// shape the contract promises.
abstract final class CartPushResultParser {
  static CartPushResult? parse(Map<Object?, Object?> json) {
    if (json case {
      'added': final List<Object?> added,
      'skipped': final List<Object?> skipped,
      'cartItemCount': final int cartItemCount,
      'cartTotalCents': final int cartTotalCents,
    }) {
      return CartPushResult(
        added: [for (final line in added) ?_added(line)],
        skipped: [for (final line in skipped) ?_skipped(line)],
        cartItemCount: cartItemCount,
        cartTotal: Money(cartTotalCents),
      );
    }
    return null;
  }

  static CartAddedLine? _added(Object? json) => switch (json) {
    {
      'itemId': final String itemId,
      'productId': final String productId,
      'name': final String name,
      'priceCents': final int priceCents,
    } =>
      CartAddedLine(
        itemId: itemId,
        productId: productId,
        name: name,
        price: Money(priceCents),
      ),
    _ => null,
  };

  static CartSkippedLine? _skipped(Object? json) => switch (json) {
    {'itemId': final String itemId, 'reason': final String reason} =>
      CartSkippedLine(itemId: itemId, reason: CartSkipReason.fromCode(reason)),
    _ => null,
  };
}
