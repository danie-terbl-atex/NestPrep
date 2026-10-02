import '../../../shared/money/money.dart';
import '../model/checkers_push_result.dart';

/// Reads `checkersPushToCart`'s answer into a typed result (`ENG-09`). Null
/// when the answer is not the shape the contract promises.
abstract final class CheckersPushResultParser {
  static CheckersPushResult? parse(Map<Object?, Object?> json) {
    if (json case {
      'added': final List<Object?> added,
      'skipped': final List<Object?> skipped,
      'cartItemCount': final int cartItemCount,
      'cartTotalCents': final int cartTotalCents,
    }) {
      return CheckersPushResult(
        added: [for (final line in added) ?_added(line)],
        skipped: [for (final line in skipped) ?_skipped(line)],
        cartItemCount: cartItemCount,
        cartTotal: Money(cartTotalCents),
      );
    }
    return null;
  }

  static CheckersAddedLine? _added(Object? json) => switch (json) {
    {
      'itemId': final String itemId,
      'productId': final String productId,
      'name': final String name,
      'priceCents': final int priceCents,
    } =>
      CheckersAddedLine(
        itemId: itemId,
        productId: productId,
        name: name,
        price: Money(priceCents),
      ),
    _ => null,
  };

  static CheckersSkippedLine? _skipped(Object? json) => switch (json) {
    {'itemId': final String itemId, 'reason': final String reason} =>
      CheckersSkippedLine(
        itemId: itemId,
        reason: CheckersSkipReason.fromCode(reason),
      ),
    _ => null,
  };
}
