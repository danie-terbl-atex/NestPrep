import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/model/retailer_switch.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/flags/feature_flag.dart';
import 'package:nestprep/shared/flags/feature_flags.dart';

/// Which shops a build offers (shops ADR-0002): Checkers and Woolworths each
/// follow their own new switch, and the switches older builds read no longer
/// decide anything here.
void main() {
  List<ProductRetailer> offered(Map<String, Object?> fields) =>
      shopsOn(FeatureFlags.fromFields(fields, defaultOn: true).isOn);

  test('only Pick n Pay is offered while the other two wait to go live', () {
    expect(offered({'checkersShop': false, 'woolworthsShop': false}), [
      ProductRetailer.pickNPay,
    ]);
  });

  test('the switches older builds read change nothing in this one', () {
    expect(
      offered({
        'addToCheckers': true,
        'addToWoolworths': true,
        'checkersShop': false,
        'woolworthsShop': false,
      }),
      [ProductRetailer.pickNPay],
    );
    expect(
      offered({'addToCheckers': false, 'addToWoolworths': false}),
      ProductRetailer.values.where((shop) => shop.isConnected),
    );
  });

  test('each shop comes back with its own switch', () {
    expect(offered({'checkersShop': true, 'woolworthsShop': false}), [
      ProductRetailer.checkers,
      ProductRetailer.pickNPay,
    ]);
    expect(switchOf(ProductRetailer.woolworths), FeatureFlag.woolworthsShop);
  });
}
