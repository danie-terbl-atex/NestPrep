import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_link_status.dart';
import 'package:nestprep/features/add_to_pnp/data/pnp_directory.dart';
import 'package:nestprep/features/add_to_pnp/model/pnp_link_status.dart';
import 'package:nestprep/features/add_to_woolworths/model/woolworths_link_status.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/shops/model/shop_link.dart';
import 'package:nestprep/features/shops/state/shops_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_checkers.dart';
import '../../../support/fake_pnp.dart';
import '../../../support/fake_woolworths.dart';
import '../../../support/held_pnp_directory.dart';

void main() {
  final now = DateTime.utc(2026, 11, 5, 9);

  late FakeCheckersDirectory checkers;
  late FakePnpDirectory pnp;
  late FakeWoolworthsDirectory woolworths;

  setUp(() {
    checkers = FakeCheckersDirectory();
    pnp = FakePnpDirectory();
    woolworths = FakeWoolworthsDirectory();
  });

  ShopsController controllerFor(
    List<ProductRetailer> shops, {
    PnpDirectory? pnpDirectory,
    Listenable? switches,
  }) {
    final controller = ShopsController(
      checkers: checkers,
      pnp: pnpDirectory ?? pnp,
      woolworths: woolworths,
      shopsOn: () => shops,
      switches: switches,
      now: () => now,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('each shop answers linked, with the account it names', () async {
    checkers.status = CheckersLinkStatus(
      isLinked: true,
      expiresAt: now.add(const Duration(minutes: 30)),
      mobileMasked: '082***4567',
    );
    pnp.status = PnpLinkStatus(isLinked: true, linkedAt: now);
    woolworths.status = WoolworthsLinkStatus(
      isLinked: true,
      linkedAt: now,
      emailMasked: 'd***@a***.io',
    );
    final controller = controllerFor(ProductRetailer.values);
    await settle();

    expect(
      controller.linkAt(ProductRetailer.checkers),
      isA<AsyncData<ShopLink>>().having(
        (state) => state.value,
        'value',
        const ShopLink(isLinked: true, account: '082***4567'),
      ),
    );
    expect(
      controller.linkAt(ProductRetailer.pickNPay),
      isA<AsyncData<ShopLink>>().having(
        (state) => state.value,
        'value',
        const ShopLink(isLinked: true),
      ),
    );
    expect(
      controller.linkAt(ProductRetailer.woolworths),
      isA<AsyncData<ShopLink>>().having(
        (state) => state.value,
        'value',
        const ShopLink(isLinked: true, account: 'd***@a***.io'),
      ),
    );
  });

  test('a shop with no link answers not linked', () async {
    final controller = controllerFor(ProductRetailer.values);
    await settle();
    for (final shop in ProductRetailer.values) {
      expect(
        controller.linkAt(shop),
        isA<AsyncData<ShopLink>>().having(
          (state) => state.value,
          'value',
          const ShopLink.unlinked(),
        ),
      );
    }
  });

  test('a Checkers link that has run out is not linked', () async {
    checkers.status = CheckersLinkStatus(
      isLinked: true,
      expiresAt: now.subtract(const Duration(minutes: 1)),
      mobileMasked: '082***4567',
    );
    final controller = controllerFor(const [ProductRetailer.checkers]);
    await settle();
    expect(
      controller.linkAt(ProductRetailer.checkers),
      isA<AsyncData<ShopLink>>().having(
        (state) => state.value,
        'value',
        const ShopLink.unlinked(),
      ),
    );
  });

  test(
    'one shop failing hides none of the others, and a retry recovers',
    () async {
      woolworths.statusFailure = const UnavailableFailure();
      final controller = controllerFor(ProductRetailer.values);
      await settle();

      expect(
        controller.linkAt(ProductRetailer.woolworths),
        isA<AsyncFailure<ShopLink>>(),
      );
      expect(
        controller.linkAt(ProductRetailer.checkers),
        isA<AsyncData<ShopLink>>(),
      );
      expect(
        controller.linkAt(ProductRetailer.pickNPay),
        isA<AsyncData<ShopLink>>(),
      );

      woolworths.statusFailure = null;
      final retry = controller.refresh(ProductRetailer.woolworths);
      expect(
        controller.linkAt(ProductRetailer.woolworths),
        isA<AsyncLoading<ShopLink>>(),
      );
      await retry;
      expect(
        controller.linkAt(ProductRetailer.woolworths),
        isA<AsyncData<ShopLink>>(),
      );
    },
  );

  test('a slow shop is loading while the others have answered', () async {
    final held = HeldPnpDirectory();
    final controller = controllerFor(
      ProductRetailer.values,
      pnpDirectory: held,
    );
    await settle();
    expect(
      controller.linkAt(ProductRetailer.pickNPay),
      isA<AsyncLoading<ShopLink>>(),
    );
    expect(
      controller.linkAt(ProductRetailer.checkers),
      isA<AsyncData<ShopLink>>(),
    );
    held.answer.complete(const PnpLinkStatus.unlinked());
    await settle();
    expect(
      controller.linkAt(ProductRetailer.pickNPay),
      isA<AsyncData<ShopLink>>(),
    );
  });

  test('a refresh keeps what is known until the answer arrives', () async {
    final controller = controllerFor(const [ProductRetailer.woolworths]);
    await settle();
    woolworths.status = WoolworthsLinkStatus(
      isLinked: true,
      linkedAt: now,
      emailMasked: 'd***@a***.io',
    );
    final refresh = controller.refresh(ProductRetailer.woolworths);
    expect(
      controller.linkAt(ProductRetailer.woolworths),
      isA<AsyncData<ShopLink>>().having(
        (state) => state.value.isLinked,
        'isLinked',
        isFalse,
      ),
    );
    await refresh;
    expect(
      controller.linkAt(ProductRetailer.woolworths),
      isA<AsyncData<ShopLink>>().having(
        (state) => state.value.isLinked,
        'isLinked',
        isTrue,
      ),
    );
  });

  test('a shop not on the page is never asked', () async {
    final held = HeldPnpDirectory();
    controllerFor(const [ProductRetailer.checkers], pnpDirectory: held);
    await settle();
    expect(held.reads, 0);
  });

  test('a shop switched on while the page is open is read then', () async {
    final held = HeldPnpDirectory();
    final shops = [ProductRetailer.checkers];
    final switches = ValueNotifier(0);
    addTearDown(switches.dispose);
    final controller = controllerFor(
      shops,
      pnpDirectory: held,
      switches: switches,
    );
    await settle();
    expect(held.reads, 0);

    shops.add(ProductRetailer.pickNPay);
    switches.value++;
    expect(controller.shops, shops);
    expect(held.reads, 1);
    held.answer.complete(const PnpLinkStatus.unlinked());
    await settle();
    expect(
      controller.linkAt(ProductRetailer.pickNPay),
      isA<AsyncData<ShopLink>>(),
    );

    switches.value++;
    expect(held.reads, 1);
  });
}
