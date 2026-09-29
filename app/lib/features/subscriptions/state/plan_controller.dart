import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/links/external_link_opener.dart';
import '../../../shared/state/action_failure.dart';
import '../data/store_billing.dart';
import '../model/billing_store.dart';
import '../model/entitlement.dart';
import '../model/purchase_progress.dart';
import 'purchase_coordinator.dart';

/// The plan and billing screen's actions (subscriptions ADR-0001): restoring
/// a purchase, and sending the buyer to their store to change or cancel it.
/// What the plan *is* comes from the household's entitlement listener, not
/// from here (`FE-07`).
final class PlanController extends ChangeNotifier with ActionFailureHolder {
  PlanController({
    required StoreBilling storeBilling,
    required PurchaseCoordinator purchaseCoordinator,
    required ExternalLinkOpener linkOpener,
    required this.viewerMemberId,
  }) : _billing = storeBilling,
       _coordinator = purchaseCoordinator,
       _opener = linkOpener {
    _openedAt = _coordinator.generation;
    _coordinator.addListener(notifyListeners);
  }

  final StoreBilling _billing;
  final PurchaseCoordinator _coordinator;
  final ExternalLinkOpener _opener;

  /// The profile this person claimed, or null for somebody who claimed none.
  final String? viewerMemberId;

  late final int _openedAt;

  /// How the person's purchase or restore is going — at rest for an outcome
  /// that finished before this screen opened, which was somebody else's.
  PurchaseProgress get progress =>
      _coordinator.generation == _openedAt && !_coordinator.progress.isBusy
      ? const PurchaseIdle()
      : _coordinator.progress;
  BillingStore? get store => _billing.store;

  /// Only the buyer can change a subscription, and only from the store they
  /// bought it in — Apple and Google each keep their own.
  bool canManage(Entitlement entitlement) =>
      entitlement.managedByMemberId != null &&
      entitlement.managedByMemberId == viewerMemberId &&
      entitlement.store == _billing.store;

  Future<void> restore() => _coordinator.restore();

  void acknowledge() => _coordinator.acknowledge();

  Future<void> manage() => runAction(() async {
    if (!await _opener.open(_billing.manageUrl(null))) {
      throw const SubscriptionFailure(SubscriptionProblem.storeNotAvailable);
    }
  });

  @override
  void dispose() {
    _coordinator.removeListener(notifyListeners);
    super.dispose();
  }
}
