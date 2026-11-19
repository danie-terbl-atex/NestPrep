import 'package:flutter/foundation.dart';
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

  test(
    'Pick n Pay waits like the others in a store build (shops ADR-0003)',
    () {
      expect(switchOf(ProductRetailer.pickNPay), FeatureFlag.pnpShop);
      expect(
        offered({
          'addToPnp': true,
          'pnpShop': false,
          'checkersShop': false,
          'woolworthsShop': false,
        }),
        isEmpty,
      );
    },
  );

  test('a testers\' build keeps each shop on the switch older builds read', () {
    expect(
      switchOf(ProductRetailer.checkers, forTesters: true),
      FeatureFlag.addToCheckers,
    );
    expect(
      switchOf(ProductRetailer.woolworths, forTesters: true),
      FeatureFlag.addToWoolworths,
    );
    expect(
      switchOf(ProductRetailer.pickNPay, forTesters: true),
      FeatureFlag.addToPnp,
    );
    expect(testerShops, isFalse);
  });

  test('each shop comes back with its own switch', () {
    expect(offered({'checkersShop': true, 'woolworthsShop': false}), [
      ProductRetailer.checkers,
      ProductRetailer.pickNPay,
    ]);
    expect(switchOf(ProductRetailer.woolworths), FeatureFlag.woolworthsShop);
  });

  test('before the document has loaded, a waiting shop is not offered', () {
    const loading = FeatureFlags.defaults(
      defaultOn: true,
      holdsBackWaiting: true,
    );
    expect(shopsOn(loading.isOn), isEmpty);
    expect(loading.isOn(FeatureFlag.lunchPantry), isTrue);
  });

  test('referral codes wait the same way, and come back when turned on', () {
    const loading = FeatureFlags.defaults(
      defaultOn: true,
      holdsBackWaiting: true,
    );
    expect(loading.isOn(FeatureFlag.referralRewards), isFalse);
    final on = FeatureFlags.fromFields(
      {'referralRewards': true},
      defaultOn: true,
      holdsBackWaiting: true,
    );
    expect(on.isOn(FeatureFlag.referralRewards), isTrue);
  });

  test('and the document can turn it on', () {
    final flags = FeatureFlags.fromFields(
      {'checkersShop': true},
      defaultOn: true,
      holdsBackWaiting: true,
    );
    expect(shopsOn(flags.isOn), [ProductRetailer.checkers]);
  });

  final connected = ProductRetailer.debugSwitchOverride;

  group('a shop switched off on one platform', () {
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      ProductRetailer.debugSwitchOverride = connected;
    });

    const allOn = {'checkersShop': true, 'pnpShop': true, 'woolworthsShop': true};

    test('is gone there and stays on the other', () {
      ProductRetailer.debugSwitchOverride = (shop, platform) =>
          !(shop == ProductRetailer.woolworths &&
              platform == TargetPlatform.iOS);

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(offered(allOn), [
        ProductRetailer.checkers,
        ProductRetailer.pickNPay,
      ]);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(offered(allOn), ProductRetailer.values);
    });

    test('and its cloud switch on never brings it back', () {
      ProductRetailer.debugSwitchOverride = (shop, platform) =>
          shop != ProductRetailer.checkers;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(
        offered(const {
          'checkersShop': true,
          'pnpShop': false,
          'woolworthsShop': false,
        }),
        isEmpty,
      );
    });
  });

  group('each platform reads only its own switch in source', () {
    setUp(() => ProductRetailer.debugSwitchOverride = null);
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      ProductRetailer.debugSwitchOverride = connected;
    });

    for (final (platform, ownSwitch) in [
      (TargetPlatform.iOS, (ProductRetailer shop) => shop.onIos),
      (TargetPlatform.android, (ProductRetailer shop) => shop.onAndroid),
    ]) {
      test(platform.name, () {
        debugDefaultTargetPlatformOverride = platform;
        for (final shop in ProductRetailer.values) {
          expect(shop.isConnected, ownSwitch(shop), reason: shop.code);
        }
        expect(
          offered(const {
            'checkersShop': true,
            'pnpShop': true,
            'woolworthsShop': true,
          }),
          ProductRetailer.values.where(ownSwitch),
        );
      });
    }
  });
}
