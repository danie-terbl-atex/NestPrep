import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/product_analytics/data/paywall_open_recorder.dart';
import 'package:nestprep/features/subscriptions/data/entitlement_repository.dart';
import 'package:nestprep/features/subscriptions/data/store_billing.dart';
import 'package:nestprep/features/subscriptions/data/subscription_directory.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/state/household_entitlement.dart';
import 'package:nestprep/features/subscriptions/state/purchase_coordinator.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'fake_paywall_open_recorder.dart';
import 'fake_subscriptions.dart';
import 'household_fixtures.dart';

/// Everything premium needs above a screen, as the app's providers and the
/// household shell give it (subscriptions ADR-0001): the store and the
/// callables faked, the coordinator real, and the household's entitlement
/// set to [entitlement].
final class SubscriptionHarness {
  SubscriptionHarness({Entitlement entitlement = Entitlement.free})
    : entitlements = FakeEntitlementRepository(initial: entitlement) {
    coordinator = PurchaseCoordinator(
      storeBilling: store,
      subscriptionDirectory: server,
      restoreSettle: const Duration(milliseconds: 20),
    )..attach(householdId: Fixtures.householdId, canBuy: true);
    addTearDown(() async {
      coordinator.dispose();
      await store.close();
      await entitlements.close();
    });
  }

  final store = FakeStoreBilling();
  final server = FakeSubscriptionDirectory();
  final FakeEntitlementRepository entitlements;
  late final PurchaseCoordinator coordinator;

  /// Every paywall opening the app tells the server about
  /// (product-analytics ADR-0002).
  final paywallOpens = FakePaywallOpenRecorder();

  List<SingleChildWidget> get providers => [
    Provider<PaywallOpenRecorder>.value(value: paywallOpens),
    Provider<StoreBilling>.value(value: store),
    Provider<SubscriptionDirectory>.value(value: server),
    Provider<EntitlementRepository>.value(value: entitlements),
    ChangeNotifierProvider<PurchaseCoordinator>.value(value: coordinator),
    ChangeNotifierProvider<HouseholdEntitlement>(
      create: (_) => HouseholdEntitlement(
        entitlementRepository: entitlements,
        householdId: Fixtures.householdId,
      ),
    ),
  ];
}
