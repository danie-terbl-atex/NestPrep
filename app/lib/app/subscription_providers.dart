import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/family_profiles/data/callable_child_profile_directory.dart';
import '../features/family_profiles/data/child_profile_directory.dart';
import '../features/subscriptions/data/callable_subscription_directory.dart';
import '../features/subscriptions/data/entitlement_repository.dart';
import '../features/subscriptions/data/firestore_entitlement_repository.dart';
import '../features/subscriptions/data/in_app_purchase_store_billing.dart';
import '../features/subscriptions/data/store_billing.dart';
import '../features/subscriptions/data/subscription_directory.dart';
import '../features/subscriptions/state/purchase_coordinator.dart';

/// Subscriptions' part of the app-wide graph (subscriptions ADR-0001): the
/// store, the callables, the entitlement listener's repository, marking a
/// child — and the coordinator that carries every purchase to the server.
///
/// The coordinator is not lazy: the store redelivers a purchase that was
/// paid for and never finished, and it has to be listening when it does.
/// Its own list, spread into `appProviders`, so the shared file changes by
/// one line.
List<SingleChildWidget> subscriptionProviders() => [
  Provider<StoreBilling>(create: (context) => InAppPurchaseStoreBilling()),
  Provider<SubscriptionDirectory>(
    create: (context) =>
        CallableSubscriptionDirectory(context.read<FirebaseFunctions>()),
  ),
  Provider<EntitlementRepository>(
    create: (context) =>
        FirestoreEntitlementRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<ChildProfileDirectory>(
    create: (context) =>
        CallableChildProfileDirectory(context.read<FirebaseFunctions>()),
  ),
  ChangeNotifierProvider<PurchaseCoordinator>(
    lazy: false,
    create: (context) => PurchaseCoordinator(
      storeBilling: context.read<StoreBilling>(),
      subscriptionDirectory: context.read<SubscriptionDirectory>(),
    ),
  ),
];
