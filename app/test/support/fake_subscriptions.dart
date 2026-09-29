import 'dart:async';

import 'package:nestprep/features/subscriptions/data/entitlement_repository.dart';
import 'package:nestprep/features/subscriptions/data/store_billing.dart';
import 'package:nestprep/features/subscriptions/data/subscription_directory.dart';
import 'package:nestprep/features/subscriptions/model/billing_store.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/free_child.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/model/store_product.dart';
import 'package:nestprep/features/subscriptions/model/store_update.dart';
import 'package:nestprep/features/subscriptions/model/subscription_offer.dart';
import 'package:nestprep/features/subscriptions/model/subscription_plan.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// The phone's store, driven by hand (subscriptions ADR-0001): it answers
/// with the prices a test sets, records what was bought and finished, and a
/// test says what the store reports back by [report].
final class FakeStoreBilling implements StoreBilling {
  final _updates = StreamController<List<StoreUpdate>>.broadcast();

  @override
  BillingStore? store = BillingStore.playStore;

  bool available = true;

  /// What the store sells, by product id. Empty is "the store knows none".
  Map<String, StoreProduct> catalogue = {
    for (final product in [monthly, yearly]) product.productId: product,
  };

  /// Thrown by the next `buy`, the way a store that cannot start fails.
  AppFailure? failBuyWith;

  final bought = <StoreProduct>[];
  final finished = <StorePurchased>[];
  var restores = 0;

  static const monthly = StoreProduct(
    productId: 'nestprep_premium_monthly',
    plan: SubscriptionPlan.monthly,
    displayPrice: r'R59.99',
    priceMicros: 59990000,
    currencyCode: 'ZAR',
  );

  static const yearly = StoreProduct(
    productId: 'nestprep_premium_yearly',
    plan: SubscriptionPlan.yearly,
    displayPrice: r'R599.99',
    priceMicros: 599990000,
    currencyCode: 'ZAR',
  );

  void report(List<StoreUpdate> updates) => _updates.add(updates);

  Future<void> close() => _updates.close();

  @override
  Stream<List<StoreUpdate>> get updates => _updates.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<List<StoreProduct>> products(
    Map<SubscriptionPlan, String> productIds,
  ) async {
    final found = [for (final id in productIds.values) ?catalogue[id]];
    if (found.isEmpty) {
      throw const SubscriptionFailure(SubscriptionProblem.productsNotFound);
    }
    return found;
  }

  @override
  Future<void> buy(StoreProduct product) async {
    final failure = failBuyWith;
    if (failure != null) {
      failBuyWith = null;
      throw failure;
    }
    bought.add(product);
  }

  @override
  Future<void> restore() async => restores++;

  @override
  Future<void> finish(StorePurchased purchase) async => finished.add(purchase);

  @override
  Uri manageUrl(String? productId) =>
      Uri.https('play.google.com', '/store/account/subscriptions');
}

/// A purchase as the store reports it, paid for [productId].
StorePurchased purchased({
  String productId = 'nestprep_premium_yearly',
  String data = 'purchase-token-1',
  bool isRestore = false,
}) => StorePurchased(
  productId: productId,
  store: BillingStore.playStore,
  verificationData: data,
  isRestore: isRestore,
  key: data,
);

/// The subscriptions callables, answering as a test sets them.
final class FakeSubscriptionDirectory implements SubscriptionDirectory {
  SubscriptionOffer answer = onSale;

  /// Thrown by the next `offer`.
  AppFailure? failOfferWith;

  /// Thrown by `verify` while set; otherwise [verifiedAsPremium] is answered.
  AppFailure? failVerifyWith;
  bool verifiedAsPremium = true;

  /// Completes `verify` only when a test says so, to hold a purchase in the
  /// verifying state.
  Completer<void>? holdVerify;

  final verified = <({String data, PremiumFeature? trigger})>[];
  var offersAsked = 0;

  static const onSale = SubscriptionOffer(
    isAvailable: true,
    canBuy: true,
    cohort: 'a',
    featuredPlan: SubscriptionPlan.yearly,
    productIds: {
      SubscriptionPlan.monthly: 'nestprep_premium_monthly',
      SubscriptionPlan.yearly: 'nestprep_premium_yearly',
    },
  );

  @override
  Future<SubscriptionOffer> offer(String householdId) async {
    offersAsked++;
    final failure = failOfferWith;
    if (failure != null) {
      failOfferWith = null;
      throw failure;
    }
    return answer;
  }

  @override
  Future<bool> verify({
    required String householdId,
    required BillingStore store,
    required String verificationData,
    required PremiumFeature? trigger,
  }) async {
    verified.add((data: verificationData, trigger: trigger));
    await holdVerify?.future;
    final failure = failVerifyWith;
    if (failure != null) throw failure;
    return verifiedAsPremium;
  }
}

/// The household's entitlement document, emitted by hand. A new listener
/// hears the latest emission first, as a Firestore snapshot listener does.
final class FakeEntitlementRepository implements EntitlementRepository {
  /// No free-child record by default, as for a household that has not marked
  /// a child since the record began: every child is planned.
  FakeEntitlementRepository({Entitlement? initial, FreeChild? freeChild})
    : _latest = initial,
      _latestFreeChild = freeChild;

  Entitlement? _latest;
  FreeChild? _latestFreeChild;
  final _entitlement = StreamController<Entitlement>.broadcast();
  final _freeChild = StreamController<FreeChild?>.broadcast();

  void emitFreeChild(FreeChild? freeChild) {
    _latestFreeChild = freeChild;
    _freeChild.add(freeChild);
  }

  @override
  Stream<FreeChild?> watchFreeChild(String householdId) =>
      Stream.multi((listener) {
        listener.add(_latestFreeChild);
        final subscription = _freeChild.stream.listen(
          listener.add,
          onError: listener.addError,
        );
        listener.onCancel = subscription.cancel;
      });

  void emit(Entitlement entitlement) {
    _latest = entitlement;
    _entitlement.add(entitlement);
  }

  void fail(Object error) => _entitlement.addError(error);

  Future<void> close() async {
    await _entitlement.close();
    await _freeChild.close();
  }

  @override
  Stream<Entitlement> watchEntitlement(String householdId) =>
      Stream.multi((listener) {
        final latest = _latest;
        if (latest != null) listener.add(latest);
        final subscription = _entitlement.stream.listen(
          listener.add,
          onError: listener.addError,
        );
        listener.onCancel = subscription.cancel;
      });
}
