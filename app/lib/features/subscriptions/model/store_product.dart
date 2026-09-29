import 'package:flutter/foundation.dart';

import 'subscription_plan.dart';

/// One plan as the phone's own store sells it (subscriptions ADR-0001). The
/// price is the store's, already formatted in the family's currency and
/// locale — NestPrep never writes a price down. The amount in millionths is
/// kept only to say how much the yearly plan saves, which is a proportion
/// and needs no currency (`ENG-20`).
@immutable
class StoreProduct {
  const StoreProduct({
    required this.productId,
    required this.plan,
    required this.displayPrice,
    required this.priceMicros,
    required this.currencyCode,
  });

  final String productId;
  final SubscriptionPlan plan;

  /// "R59,99", "$4.99" — exactly as the store wrote it.
  final String displayPrice;

  /// The price in millionths of the currency's unit, an integer.
  final int priceMicros;
  final String currencyCode;

  @override
  bool operator ==(Object other) =>
      other is StoreProduct &&
      other.productId == productId &&
      other.plan == plan &&
      other.displayPrice == displayPrice &&
      other.priceMicros == priceMicros &&
      other.currencyCode == currencyCode;

  @override
  int get hashCode =>
      Object.hash(productId, plan, displayPrice, priceMicros, currencyCode);
}
