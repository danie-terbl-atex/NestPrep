import '../../../shared/flags/feature_flag.dart';
import '../../groceries/model/product_match.dart';

/// Whether this build is for the testers, who keep every shop while the
/// store builds wait (shops ADR-0002). Never set on a build sent for review.
const testerShops = String.fromEnvironment(testerShopsDefineName) == 'on';

const testerShopsDefineName = 'NESTPREP_TESTER_SHOPS';

/// The switch each connected shop sits behind (foundation ADR-0014,
/// add-to-pnp ADR-0007, shops ADR-0002). A shop with none is not connected
/// and is never offered. Every list of shops, and so every shop's mark, is
/// made from these. A testers' build reads the switches builds up to 0.9.0
/// (14) read, so a shop waiting to go live stays with the people testing it.
FeatureFlag? switchOf(ProductRetailer shop, {bool forTesters = testerShops}) =>
    switch (shop) {
      ProductRetailer.checkers =>
        forTesters ? FeatureFlag.addToCheckers : FeatureFlag.checkersShop,
      ProductRetailer.pickNPay =>
        forTesters ? FeatureFlag.addToPnp : FeatureFlag.pnpShop,
      ProductRetailer.woolworths =>
        forTesters ? FeatureFlag.addToWoolworths : FeatureFlag.woolworthsShop,
    };

/// The connected shops whose switch [isOn] says is on, in their order.
List<ProductRetailer> shopsOn(bool Function(FeatureFlag flag) isOn) => [
  for (final shop in ProductRetailer.values)
    if (switchOf(shop) case final flag? when shop.isConnected && isOn(flag))
      shop,
];
