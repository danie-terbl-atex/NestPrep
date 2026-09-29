import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../data/store_billing.dart';
import '../data/subscription_directory.dart';
import '../model/premium_feature.dart';
import '../model/purchase_progress.dart';
import '../model/store_product.dart';
import '../model/store_update.dart';

/// Every purchase the phone's store reports, carried to the server to be
/// verified — and only then finished (subscriptions ADR-0001).
///
/// App-wide, because the store redelivers a purchase that was paid for but
/// never finished — the app closed, the network dropped — and it must be
/// verified whichever screen is open. Until a household is [attach]ed such a
/// purchase waits here, unfinished, so the store keeps it safe.
///
/// It holds no premium state of its own (`FE-07`): whether the household has
/// premium is the entitlement document, which arrives through its listener.
/// This only says how the person's own purchase or restore is going.
final class PurchaseCoordinator extends ChangeNotifier {
  PurchaseCoordinator({
    required StoreBilling storeBilling,
    required SubscriptionDirectory subscriptionDirectory,
    this.restoreSettle = const Duration(seconds: 4),
  }) : _billing = storeBilling,
       _directory = subscriptionDirectory {
    _subscription = _billing.updates.listen(
      _onUpdates,
      onError: (Object error) =>
          AppLog.failure('store updates', code: 'stream', error: error),
    );
  }

  final StoreBilling _billing;
  final SubscriptionDirectory _directory;

  /// A restore has no "done" from the store; it is over once the store has
  /// been quiet this long.
  final Duration restoreSettle;
  late final StreamSubscription<List<StoreUpdate>> _subscription;

  String? _householdId;
  bool _canBuy = false;
  final _waiting = <StorePurchased>[];

  PurchaseProgress _progress = const PurchaseIdle();
  PremiumFeature? _trigger;
  _Session _session = _Session.none;
  Timer? _restoreTimer;
  bool _restoreFoundPremium = false;
  AppFailure? _restoreFailure;

  PurchaseProgress get progress => _progress;

  /// Counts every change of [progress], so a screen opened after an outcome
  /// can tell that outcome is not its own and show it at rest.
  int get generation => _generation;
  int _generation = 0;

  /// The household purchases are verified for: the one on screen. A kid,
  /// helper or carer [canBuy] nothing, so a purchase that reaches their
  /// phone waits for a parent's.
  void attach({required String householdId, required bool canBuy}) {
    if (_householdId == householdId && _canBuy == canBuy) return;
    _householdId = householdId;
    _canBuy = canBuy;
    if (!canBuy || _waiting.isEmpty) return;
    final waiting = [..._waiting];
    _waiting.clear();
    for (final purchase in waiting) {
      unawaited(_verify(purchase));
    }
  }

  /// Opens the store's purchase sheet for [product]; [trigger] is what the
  /// person reached for, counted once the purchase is verified.
  Future<void> purchase(StoreProduct product, PremiumFeature trigger) async {
    if (_progress.isBusy) return;
    _trigger = trigger;
    _session = _Session.purchase;
    _publish(const PurchaseInStore());
    try {
      await _billing.buy(product);
    } on AppFailure catch (failure) {
      _end(PurchaseFailed(failure));
    }
  }

  /// Asks the store for what this account bought before; each one it finds
  /// is verified as a restore. Nothing found in a few seconds is said so.
  Future<void> restore() async {
    if (_progress.isBusy) return;
    _session = _Session.restore;
    _restoreFoundPremium = false;
    _restoreFailure = null;
    _publish(const PurchaseVerifying(isRestore: true));
    try {
      await _billing.restore();
      _settleRestoreSoon();
    } on AppFailure catch (failure) {
      _end(PurchaseFailed(failure));
    }
  }

  /// Back to rest once the screen has shown the outcome.
  void acknowledge() {
    if (_progress.isBusy) return;
    _publish(const PurchaseIdle());
  }

  void _onUpdates(List<StoreUpdate> updates) {
    for (final update in updates) {
      switch (update) {
        case StorePurchased():
          unawaited(_verify(update));
        case StorePending() when _session == _Session.purchase:
          _end(const PurchaseAwaitingApproval());
        case StoreCancelled() when _session == _Session.purchase:
          _end(const PurchaseIdle());
        case StoreFailed() when _session == _Session.purchase:
          _end(
            const PurchaseFailed(
              SubscriptionFailure(SubscriptionProblem.purchaseFailed),
            ),
          );
        case StorePending() || StoreCancelled() || StoreFailed():
          break;
      }
    }
  }

  Future<void> _verify(StorePurchased purchase) async {
    final householdId = _householdId;
    if (householdId == null || !_canBuy) {
      _waiting.add(purchase);
      return;
    }
    final isTheOneAskedFor =
        _session == _Session.purchase && !purchase.isRestore;
    if (isTheOneAskedFor) _publish(const PurchaseVerifying(isRestore: false));
    _restoreTimer?.cancel();
    try {
      final isPremium = await _directory.verify(
        householdId: householdId,
        store: purchase.store,
        verificationData: purchase.verificationData,
        trigger: purchase.isRestore
            ? null
            : (_trigger ?? PremiumFeature.direct),
      );
      // Finished only now: an unfinished purchase is redelivered, which is
      // what saves one the server could not verify this time.
      await _billing.finish(purchase);
      _afterVerified(isPremium: isPremium, isTheOneAskedFor: isTheOneAskedFor);
    } on AppFailure catch (failure) {
      _afterRefused(failure, isTheOneAskedFor: isTheOneAskedFor);
    }
  }

  void _afterVerified({
    required bool isPremium,
    required bool isTheOneAskedFor,
  }) {
    if (isTheOneAskedFor) {
      _end(const PurchaseSucceeded());
    } else if (_session == _Session.restore) {
      _restoreFoundPremium = _restoreFoundPremium || isPremium;
      _settleRestoreSoon();
    }
  }

  void _afterRefused(AppFailure failure, {required bool isTheOneAskedFor}) {
    AppLog.failure('verify purchase', code: failure.runtimeType.toString());
    if (isTheOneAskedFor) {
      _end(PurchaseFailed(failure));
    } else if (_session == _Session.restore) {
      _restoreFailure ??= failure;
      _settleRestoreSoon();
    }
  }

  void _settleRestoreSoon() {
    _restoreTimer?.cancel();
    _restoreTimer = Timer(restoreSettle, () {
      if (_session != _Session.restore) return;
      _end(
        _restoreFoundPremium
            ? const PurchaseSucceeded()
            : PurchaseFailed(
                _restoreFailure ??
                    const SubscriptionFailure(
                      SubscriptionProblem.nothingToRestore,
                    ),
              ),
      );
    });
  }

  void _end(PurchaseProgress outcome) {
    _session = _Session.none;
    _trigger = null;
    _restoreTimer?.cancel();
    _publish(outcome);
  }

  void _publish(PurchaseProgress progress) {
    _progress = progress;
    _generation += 1;
    notifyListeners();
  }

  @override
  void dispose() {
    _restoreTimer?.cancel();
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

enum _Session { none, purchase, restore }
