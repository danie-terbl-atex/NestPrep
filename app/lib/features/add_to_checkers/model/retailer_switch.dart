import '../../../shared/flags/feature_flag.dart';
import '../../groceries/model/product_match.dart';

/// The switch each connected shop sits behind (foundation ADR-0014,
/// add-to-pnp ADR-0007, shops ADR-0002). A shop with none is not connected
/// and is never offered. Every list of shops, and so every shop's mark, is
/// made from these.
FeatureFlag? switchOf(ProductRetailer shop) => switch (shop) {
  ProductRetailer.checkers => FeatureFlag.checkersShop,
  ProductRetailer.pickNPay => FeatureFlag.addToPnp,
  ProductRetailer.woolworths => FeatureFlag.woolworthsShop,
};

/// The connected shops whose switch [isOn] says is on, in their order.
List<ProductRetailer> shopsOn(bool Function(FeatureFlag flag) isOn) => [
  for (final shop in ProductRetailer.values)
    if (switchOf(shop) case final flag? when shop.isConnected && isOn(flag))
      shop,
];
