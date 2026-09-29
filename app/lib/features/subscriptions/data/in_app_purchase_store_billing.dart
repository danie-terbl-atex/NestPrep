import 'dart:io';

import 'package:flutter/services.dart';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../../../shared/log/best_effort.dart';
import '../model/billing_store.dart';
import '../model/store_product.dart';
import '../model/store_update.dart';
import '../model/subscription_plan.dart';
import 'store_billing.dart';

/// Google Play Billing and StoreKit 2 through the Flutter team's own
/// `in_app_purchase` plugin (subscriptions ADR-0001). The only file that
/// sees the plugin's types; everything past it speaks [StoreUpdate].
final class InAppPurchaseStoreBilling implements StoreBilling {
  InAppPurchaseStoreBilling({InAppPurchase? plugin})
    : _plugin = plugin ?? InAppPurchase.instance;

  final InAppPurchase _plugin;

  /// Purchases the store has handed over and not yet been told are finished,
  /// by [StorePurchased.key].
  final _unfinished = <String, PurchaseDetails>{};

  static const androidPackage = 'io.nullstate.nestprep';

  @override
  BillingStore? get store => switch (Platform.operatingSystem) {
    'android' => BillingStore.playStore,
    'ios' => BillingStore.appStore,
    _ => null,
  };

  @override
  Stream<List<StoreUpdate>> get updates =>
      _plugin.purchaseStream.map((purchases) => [...purchases.map(_updateOf)]);

  @override
  Future<bool> isAvailable() async {
    if (store == null) return false;
    return _plugin.isAvailable();
  }

  @override
  Future<List<StoreProduct>> products(
    Map<SubscriptionPlan, String> productIds,
  ) async {
    final planById = {
      for (final entry in productIds.entries) entry.value: entry.key,
    };
    final response = await _storeCall(
      'store products',
      SubscriptionProblem.storeNotAvailable,
      () => _plugin.queryProductDetails(planById.keys.toSet()),
    );
    final found = <String, ProductDetails>{};
    for (final details in response.productDetails) {
      // Google lists a subscription once per offer; the base plan is the
      // price a family pays every period, so it wins over an introductory
      // offer.
      if (!found.containsKey(details.id) || _isBasePlan(details)) {
        found[details.id] = details;
      }
    }
    if (found.isEmpty) {
      AppLog.failure('store products', code: 'not found');
      throw const SubscriptionFailure(SubscriptionProblem.productsNotFound);
    }
    return [
      for (final details in found.values)
        if (planById[details.id] case final plan?)
          StoreProduct(
            productId: details.id,
            plan: plan,
            displayPrice: details.price,
            // The store's own amount, to the micro-unit, as an integer at the
            // edge (`ENG-20`).
            priceMicros: (details.rawPrice * 1000000).round(),
            currencyCode: details.currencyCode,
          ),
    ];
  }

  @override
  Future<void> buy(StoreProduct product) async {
    final response = await _storeCall(
      'store product',
      SubscriptionProblem.storeNotAvailable,
      () => _plugin.queryProductDetails({product.productId}),
    );
    final details = response.productDetails
        .where((candidate) => candidate.id == product.productId)
        .fold<ProductDetails?>(
          null,
          (best, next) => best == null || _isBasePlan(next) ? next : best,
        );
    if (details == null) {
      throw const SubscriptionFailure(SubscriptionProblem.productsNotFound);
    }
    final started = await _storeCall(
      'store purchase',
      SubscriptionProblem.purchaseFailed,
      () => _plugin.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      ),
    );
    if (!started) {
      throw const SubscriptionFailure(SubscriptionProblem.purchaseFailed);
    }
  }

  @override
  Future<void> restore() => _storeCall(
    'store restore',
    SubscriptionProblem.storeNotAvailable,
    _plugin.restorePurchases,
  );

  @override
  Future<void> finish(StorePurchased purchase) async {
    final details = _unfinished.remove(purchase.key);
    if (details != null && details.pendingCompletePurchase) {
      // The server has already verified and recorded it, and on Google Play
      // acknowledged it too; a store that will not take "finished" now
      // redelivers it, and verifying it again changes nothing. So this is
      // said in the log and not to the person, who has premium.
      await bestEffort(
        'store finish',
        code: 'redelivered',
        run: () => _plugin.completePurchase(details),
      );
    }
  }

  @override
  Uri manageUrl(String? productId) => switch (store) {
    BillingStore.playStore => Uri.https(
      'play.google.com',
      '/store/account/subscriptions',
      {'package': androidPackage, 'sku': ?productId},
    ),
    _ => Uri.https('apps.apple.com', '/account/subscriptions'),
  };

  /// A plugin call, with the platform's own exception turned into ours at
  /// the edge (`FE-09`): the store's words are logged and never shown.
  static Future<T> _storeCall<T>(
    String operation,
    SubscriptionProblem problem,
    Future<T> Function() call,
  ) async {
    try {
      return await call();
    } on PlatformException catch (error) {
      AppLog.failure(operation, code: error.code, error: error);
      throw SubscriptionFailure(problem);
    }
  }

  StoreUpdate _updateOf(PurchaseDetails details) {
    final productId = details.productID;
    return switch (details.status) {
      PurchaseStatus.pending => StorePending(productId: productId),
      PurchaseStatus.canceled => StoreCancelled(productId: productId),
      PurchaseStatus.error => _failed(details),
      PurchaseStatus.purchased ||
      PurchaseStatus.restored => _purchased(details),
    };
  }

  StoreUpdate _failed(PurchaseDetails details) {
    AppLog.failure('store purchase', code: details.error?.code ?? 'unknown');
    return StoreFailed(productId: details.productID);
  }

  StoreUpdate _purchased(PurchaseDetails details) {
    final key =
        details.purchaseID ?? details.verificationData.serverVerificationData;
    _unfinished[key] = details;
    return StorePurchased(
      productId: details.productID,
      store: store ?? BillingStore.playStore,
      verificationData: details.verificationData.serverVerificationData,
      isRestore: details.status == PurchaseStatus.restored,
      key: key,
    );
  }

  static bool _isBasePlan(ProductDetails details) {
    if (details is! GooglePlayProductDetails) return true;
    final index = details.subscriptionIndex;
    final offers = details.productDetails.subscriptionOfferDetails;
    if (index == null || offers == null || index >= offers.length) return true;
    return offers[index].offerId == null;
  }
}
