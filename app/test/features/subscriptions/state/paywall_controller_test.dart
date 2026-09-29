import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/subscriptions/model/paywall_offer.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/model/purchase_progress.dart';
import 'package:nestprep/features/subscriptions/model/subscription_offer.dart';
import 'package:nestprep/features/subscriptions/model/subscription_plan.dart';
import 'package:nestprep/features/subscriptions/state/paywall_controller.dart';
import 'package:nestprep/features/subscriptions/state/purchase_coordinator.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_subscriptions.dart';

/// What a paywall offers, in the store's own prices, and which plan it opens
/// on (subscriptions ADR-0001).
void main() {
  late FakeStoreBilling store;
  late FakeSubscriptionDirectory server;
  late PurchaseCoordinator coordinator;

  setUp(() {
    store = FakeStoreBilling();
    server = FakeSubscriptionDirectory();
    coordinator = PurchaseCoordinator(
      storeBilling: store,
      subscriptionDirectory: server,
    )..attach(householdId: 'h1', canBuy: true);
  });

  tearDown(() async {
    coordinator.dispose();
    await store.close();
  });

  Future<PaywallController> opened({
    PremiumFeature feature = PremiumFeature.additionalChild,
  }) async {
    final controller = PaywallController(
      subscriptionDirectory: server,
      storeBilling: store,
      purchaseCoordinator: coordinator,
      householdId: 'h1',
      feature: feature,
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);
    return controller;
  }

  PaywallOffer offerOf(PaywallController controller) =>
      switch (controller.offer) {
        AsyncData(:final value) => value,
        final other => throw StateError('not loaded: $other'),
      };

  test(
    'shows both plans at the store’s prices and opens on the suggested one',
    () async {
      final controller = await opened();
      final choice = offerOf(controller).choice!;
      expect(choice.products.map((p) => p.displayPrice), [
        r'R59.99',
        r'R599.99',
      ]);
      expect(controller.selected, SubscriptionPlan.yearly);
    },
  );

  test(
    'opens on the monthly plan for the cohort that is shown it first',
    () async {
      server.answer = const SubscriptionOffer(
        isAvailable: true,
        canBuy: true,
        cohort: 'b',
        featuredPlan: SubscriptionPlan.monthly,
        productIds: {
          SubscriptionPlan.monthly: 'nestprep_premium_monthly',
          SubscriptionPlan.yearly: 'nestprep_premium_yearly',
        },
      );
      expect((await opened()).selected, SubscriptionPlan.monthly);
    },
  );

  test(
    'is not on sale, and not an error, while nothing is configured',
    () async {
      server.answer = SubscriptionOffer.unavailable;
      final controller = await opened();
      expect(offerOf(controller).isOnSale, isFalse);
      expect(controller.selected, isNull);
    },
  );

  test('offers nothing to buy to somebody who may not', () async {
    server.answer = const SubscriptionOffer(
      isAvailable: true,
      canBuy: false,
      cohort: 'a',
      featuredPlan: SubscriptionPlan.yearly,
      productIds: {SubscriptionPlan.yearly: 'nestprep_premium_yearly'},
    );
    final controller = await opened();
    expect(offerOf(controller).isOnSale, isFalse);
    expect(offerOf(controller).offer.canBuy, isFalse);
  });

  test(
    'says so when this phone has no store, and loads again on retry',
    () async {
      store.available = false;
      final controller = await opened();
      expect(
        controller.offer,
        isA<AsyncFailure<PaywallOffer>>().having(
          (state) => state.failure,
          'failure',
          const SubscriptionFailure(SubscriptionProblem.storeNotAvailable),
        ),
      );
      store.available = true;
      await controller.load();
      expect(controller.offer, isA<AsyncData<PaywallOffer>>());
    },
  );

  test('says so when the store does not know the products yet', () async {
    store.catalogue = {};
    final controller = await opened();
    expect(controller.offer, isA<AsyncFailure<PaywallOffer>>());
  });

  test('buys the plan picked, for the feature it was opened on', () async {
    final controller = await opened(feature: PremiumFeature.prepList);
    controller.select(SubscriptionPlan.monthly);
    await controller.subscribe();
    expect(store.bought, [FakeStoreBilling.monthly]);

    store.report([purchased(productId: 'nestprep_premium_monthly')]);
    await Future<void>.delayed(Duration.zero);
    expect(server.verified.single.trigger, PremiumFeature.prepList);
    expect(controller.progress, isA<PurchaseSucceeded>());
  });

  test(
    'shows an outcome from before it opened at rest — it was not this one',
    () async {
      await coordinator.purchase(
        FakeStoreBilling.yearly,
        PremiumFeature.direct,
      );
      store.report([purchased()]);
      await Future<void>.delayed(Duration.zero);
      expect(coordinator.progress, isA<PurchaseSucceeded>());

      expect((await opened()).progress, isA<PurchaseIdle>());
    },
  );
}
