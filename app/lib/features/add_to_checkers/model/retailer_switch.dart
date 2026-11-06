import '../../../shared/flags/feature_flag.dart';
import '../../groceries/model/product_match.dart';

/// The switch each connected shop sits behind (foundation ADR-0014,
/// add-to-pnp ADR-0007, add-to-woolworths ADR-0001). A shop with none is not
/// connected and is never offered.
FeatureFlag? switchOf(ProductRetailer shop) => switch (shop) {
  ProductRetailer.checkers => FeatureFlag.addToCheckers,
  ProductRetailer.pickNPay => FeatureFlag.addToPnp,
  ProductRetailer.woolworths => FeatureFlag.addToWoolworths,
};

/// The connected shops whose switch [isOn] says is on, in their order.
List<ProductRetailer> shopsOn(bool Function(FeatureFlag flag) isOn) => [
  for (final shop in ProductRetailer.values)
    if (switchOf(shop) case final flag? when shop.isConnected && isOn(flag))
      shop,
];
