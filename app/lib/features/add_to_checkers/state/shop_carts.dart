import '../../groceries/model/product_match.dart';
import '../data/cart_pusher.dart';
import 'cart_push_controller.dart';

/// One cart push per connected shop (add-to-pnp ADR-0007): each the one
/// generic [CartPushController], over that shop's own callables, so a push
/// at one shop never waits on or shows another.
final class ShopCarts {
  ShopCarts(Map<ProductRetailer, CartPushController> byShop)
    : _byShop = Map.unmodifiable(byShop);

  ShopCarts.over(
    Map<ProductRetailer, CartPusher> pushers, {
    required String householdId,
  }) : this({
         for (final MapEntry(key: shop, value: pusher) in pushers.entries)
           shop: CartPushController(
             directory: pusher,
             householdId: householdId,
           ),
       });

  final Map<ProductRetailer, CartPushController> _byShop;

  CartPushController of(ProductRetailer shop) =>
      _byShop[shop] ?? (throw StateError('no cart for $shop'));

  void dispose() {
    for (final cart in _byShop.values) {
      cart.dispose();
    }
  }
}
