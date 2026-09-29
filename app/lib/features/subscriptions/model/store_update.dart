import 'package:flutter/foundation.dart';

import 'billing_store.dart';

/// Something the phone's store said about a purchase, in NestPrep's words
/// rather than the plugin's (subscriptions ADR-0001). Only
/// `InAppPurchaseStoreBilling` sees the plugin's types.
sealed class StoreUpdate {
  const StoreUpdate({required this.productId});

  final String productId;
}

/// Paid for — or, with [isRestore], found again on a new phone. It is not
/// premium until the server has verified [verificationData] with the store.
@immutable
final class StorePurchased extends StoreUpdate {
  const StorePurchased({
    required super.productId,
    required this.store,
    required this.verificationData,
    required this.isRestore,
    required this.key,
  });

  final BillingStore store;

  /// Google's purchase token, or Apple's signed transaction.
  final String verificationData;
  final bool isRestore;

  /// How the store adapter finds this purchase again to finish it.
  final String key;

  @override
  bool operator ==(Object other) =>
      other is StorePurchased &&
      other.productId == productId &&
      other.store == store &&
      other.verificationData == verificationData &&
      other.isRestore == isRestore &&
      other.key == key;

  @override
  int get hashCode =>
      Object.hash(productId, store, verificationData, isRestore, key);
}

/// Waiting on somebody else: a parent's approval (Ask to Buy, Family Link) or
/// a payment method that settles later. Nothing to verify yet.
final class StorePending extends StoreUpdate {
  const StorePending({required super.productId});
}

/// The person closed the store's sheet. Not a failure.
final class StoreCancelled extends StoreUpdate {
  const StoreCancelled({required super.productId});
}

/// The store could not take the payment. Its own message is never shown
/// (`FE-09`).
final class StoreFailed extends StoreUpdate {
  const StoreFailed({required super.productId});
}
