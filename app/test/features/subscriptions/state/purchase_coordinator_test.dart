import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/model/purchase_progress.dart';
import 'package:nestprep/features/subscriptions/model/store_update.dart';
import 'package:nestprep/features/subscriptions/state/purchase_coordinator.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_subscriptions.dart';

/// Every purchase the store reports is verified by the server before it is
/// finished, and only the one the person asked for is shown as theirs
/// (subscriptions ADR-0001).
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
      restoreSettle: const Duration(milliseconds: 20),
    );
  });

  tearDown(() async {
    coordinator.dispose();
    await store.close();
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  /// Longer than the store's quiet time, after which a restore is over.
  Future<void> quiet() =>
      Future<void>.delayed(const Duration(milliseconds: 60));

  group('a purchase the person started', () {
    setUp(() => coordinator.attach(householdId: 'h1', canBuy: true));

    test('is verified with what opened the paywall, then finished', () async {
      await coordinator.purchase(
        FakeStoreBilling.yearly,
        PremiumFeature.additionalChild,
      );
      expect(coordinator.progress, isA<PurchaseInStore>());
      expect(store.bought, [FakeStoreBilling.yearly]);

      store.report([purchased()]);
      await settle();

      expect(server.verified.single.trigger, PremiumFeature.additionalChild);
      expect(store.finished, [purchased()]);
      expect(coordinator.progress, isA<PurchaseSucceeded>());
    });

    test(
      'is never finished when the server refuses it, so the store keeps it',
      () async {
        server.failVerifyWith = const SubscriptionFailure(
          SubscriptionProblem.storeUnreachable,
        );
        await coordinator.purchase(
          FakeStoreBilling.yearly,
          PremiumFeature.direct,
        );
        store.report([purchased()]);
        await settle();

        expect(store.finished, isEmpty);
        final progress = coordinator.progress;
        expect(progress, isA<PurchaseFailed>());
        expect(
          (progress as PurchaseFailed).failure,
          const SubscriptionFailure(SubscriptionProblem.storeUnreachable),
        );
      },
    );

    test('closing the store’s sheet is not a failure', () async {
      await coordinator.purchase(
        FakeStoreBilling.yearly,
        PremiumFeature.direct,
      );
      store.report([
        const StoreCancelled(productId: 'nestprep_premium_yearly'),
      ]);
      await settle();
      expect(coordinator.progress, isA<PurchaseIdle>());
    });

    test('a payment waiting on a parent’s approval is said so', () async {
      await coordinator.purchase(
        FakeStoreBilling.yearly,
        PremiumFeature.direct,
      );
      store.report([const StorePending(productId: 'nestprep_premium_yearly')]);
      await settle();
      expect(coordinator.progress, isA<PurchaseAwaitingApproval>());
    });

    test(
      'a store that could not take the payment fails in our words',
      () async {
        await coordinator.purchase(
          FakeStoreBilling.yearly,
          PremiumFeature.direct,
        );
        store.report([const StoreFailed(productId: 'nestprep_premium_yearly')]);
        await settle();
        final progress = coordinator.progress;
        expect(
          progress is PurchaseFailed &&
              progress.failure ==
                  const SubscriptionFailure(SubscriptionProblem.purchaseFailed),
          isTrue,
        );
      },
    );

    test('a second tap while one is running does nothing', () async {
      await coordinator.purchase(
        FakeStoreBilling.yearly,
        PremiumFeature.direct,
      );
      await coordinator.purchase(
        FakeStoreBilling.monthly,
        PremiumFeature.direct,
      );
      expect(store.bought, [FakeStoreBilling.yearly]);
    });
  });

  group('a purchase the store redelivers', () {
    test(
      'waits, unfinished, until a household is open, then is verified',
      () async {
        store.report([purchased()]);
        await settle();
        expect(server.verified, isEmpty);
        expect(store.finished, isEmpty);

        coordinator.attach(householdId: 'h1', canBuy: true);
        await settle();

        // Paid for before the app closed: a purchase, counted as `direct`.
        expect(server.verified.single.trigger, PremiumFeature.direct);
        expect(store.finished, hasLength(1));
        // It was nobody's tap on this screen, so nothing is announced.
        expect(coordinator.progress, isA<PurchaseIdle>());
      },
    );

    test('waits for a parent when a helper is the one signed in', () async {
      coordinator.attach(householdId: 'h1', canBuy: false);
      store.report([purchased()]);
      await settle();
      expect(server.verified, isEmpty);
    });
  });

  group('a restore', () {
    setUp(() => coordinator.attach(householdId: 'h1', canBuy: true));

    test(
      'verifies each purchase found without counting it as a conversion',
      () async {
        await coordinator.restore();
        expect(store.restores, 1);
        store.report([purchased(isRestore: true)]);
        await quiet();

        expect(server.verified.single.trigger, isNull);
        expect(coordinator.progress, isA<PurchaseSucceeded>());
      },
    );

    test('that finds nothing says so, once the store has been quiet', () async {
      await coordinator.restore();
      expect(coordinator.progress, isA<PurchaseVerifying>());
      await quiet();

      final progress = coordinator.progress;
      expect(
        progress is PurchaseFailed &&
            progress.failure ==
                const SubscriptionFailure(SubscriptionProblem.nothingToRestore),
        isTrue,
      );
    });

    test(
      'that finds only an ended subscription does not call it premium',
      () async {
        server.verifiedAsPremium = false;
        await coordinator.restore();
        store.report([purchased(isRestore: true)]);
        await quiet();
        expect(coordinator.progress, isA<PurchaseFailed>());
        // Verified and recorded all the same: the store may let it go now.
        expect(store.finished, hasLength(1));
      },
    );
  });

  test(
    'every change of progress is counted, so a screen opened later can tell',
    () async {
      coordinator.attach(householdId: 'h1', canBuy: true);
      final before = coordinator.generation;
      await coordinator.purchase(
        FakeStoreBilling.yearly,
        PremiumFeature.direct,
      );
      expect(coordinator.generation, greaterThan(before));
    },
  );
}
