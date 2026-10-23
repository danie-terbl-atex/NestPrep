import '../../groceries/model/product_match.dart';
import 'cart_push_controller.dart';

/// One cart push per connected shop for the grocery list (add-to-pnp
/// ADR-0007): each the one generic [CartPushController], over that shop's
/// own callables, so a push at one shop never waits on or shows the other.
final class ShopCarts {
  const ShopCarts({required this.checkers, required this.pickNPay});

  final CartPushController checkers;
  final CartPushController pickNPay;

  /// [shop]'s push. A shop that is not connected has none.
  CartPushController of(ProductRetailer shop) => switch (shop) {
    ProductRetailer.checkers => checkers,
    ProductRetailer.pickNPay => pickNPay,
    ProductRetailer.woolworths => throw StateError('no cart for $shop'),
  };

  void dispose() {
    checkers.dispose();
    pickNPay.dispose();
  }
}
