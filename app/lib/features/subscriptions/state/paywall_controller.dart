import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../data/store_billing.dart';
import '../data/subscription_directory.dart';
import '../model/billing_store.dart';
import '../model/paywall_offer.dart';
import '../model/plan_choice.dart';
import '../model/premium_feature.dart';
import '../model/purchase_progress.dart';
import '../model/subscription_offer.dart';
import '../model/subscription_plan.dart';
import 'purchase_coordinator.dart';

/// The paywall's controller: loading the offer and the store's prices, the
/// plan the person has picked, and — through the app-wide
/// [PurchaseCoordinator] — how their purchase or restore is going. It lives
/// as long as the sheet (foundation ADR-0006).
final class PaywallController extends ChangeNotifier {
  PaywallController({
    required SubscriptionDirectory subscriptionDirectory,
    required StoreBilling storeBilling,
    required PurchaseCoordinator purchaseCoordinator,
    required this.householdId,
    required this.feature,
  }) : _directory = subscriptionDirectory,
       _billing = storeBilling,
       _coordinator = purchaseCoordinator {
    _openedAt = _coordinator.generation;
    _coordinator.addListener(notifyListeners);
    unawaited(load());
  }

  final SubscriptionDirectory _directory;
  final StoreBilling _billing;
  final PurchaseCoordinator _coordinator;
  final String householdId;
  final PremiumFeature feature;

  AsyncState<PaywallOffer> _offer = const AsyncLoading();
  SubscriptionPlan? _selected;

  AsyncState<PaywallOffer> get offer => _offer;
  SubscriptionPlan? get selected => _selected;
  late final int _openedAt;

  /// How the person's purchase or restore is going — at rest for an outcome
  /// that finished before this screen opened, which was somebody else's.
  PurchaseProgress get progress =>
      _coordinator.generation == _openedAt && !_coordinator.progress.isBusy
      ? const PurchaseIdle()
      : _coordinator.progress;
  BillingStore? get store => _billing.store;

  Future<void> load() async {
    _offer = const AsyncLoading();
    notifyListeners();
    try {
      final offer = await _directory.offer(householdId);
      _offer = AsyncData(
        PaywallOffer(offer: offer, choice: await _choiceFor(offer)),
      );
      _selected = switch (_offer) {
        AsyncData(value: PaywallOffer(:final choice?)) when !choice.isEmpty =>
          choice.initialPlan,
        _ => null,
      };
    } on AppFailure catch (failure) {
      _offer = AsyncFailure(failure);
    }
    notifyListeners();
  }

  Future<PlanChoice?> _choiceFor(SubscriptionOffer offer) async {
    if (!offer.isAvailable || !offer.canBuy) return null;
    if (!await _billing.isAvailable()) {
      throw const SubscriptionFailure(SubscriptionProblem.storeNotAvailable);
    }
    return PlanChoice(
      products: await _billing.products(offer.productIds),
      featured: offer.featuredPlan,
    );
  }

  void select(SubscriptionPlan plan) {
    if (_coordinator.progress.isBusy || _selected == plan) return;
    _selected = plan;
    notifyListeners();
  }

  Future<void> subscribe() async {
    final plan = _selected;
    final product = switch (_offer) {
      AsyncData(value: PaywallOffer(:final choice?)) when plan != null =>
        choice.productFor(plan),
      _ => null,
    };
    if (product == null) return;
    await _coordinator.purchase(product, feature);
  }

  Future<void> restore() => _coordinator.restore();

  /// The outcome has been seen; back to rest.
  void acknowledge() => _coordinator.acknowledge();

  @override
  void dispose() {
    _coordinator.removeListener(notifyListeners);
    super.dispose();
  }
}
