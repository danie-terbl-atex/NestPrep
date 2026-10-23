import '../model/cart_push_result.dart';

/// A shop that can put a household's matched grocery items into the
/// member's own cart — Checkers (the Checkers build contract) or Pick n Pay
/// (add-to-pnp ADR-0004). Cart only: never a slot, a checkout or a payment.
/// The server reads the items itself; the phone only names them.
abstract interface class CartPusher {
  /// Pushes [itemIds]; [quantities] is how many packs each is wanted as, by
  /// item id. A shop that adds one of each item (Checkers) ignores it.
  Future<CartPushResult> pushToCart({
    required String householdId,
    required List<String> itemIds,
    Map<String, int> quantities = const {},
  });
}
