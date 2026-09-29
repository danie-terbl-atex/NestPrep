import 'package:flutter/foundation.dart';

import 'store_product.dart';
import 'subscription_plan.dart';

/// The plans a paywall shows, in order, with the one the pricing test puts
/// first (subscriptions ADR-0001). Built from the server's offer and the
/// store's products, so a plan the store does not know is simply absent.
@immutable
class PlanChoice {
  PlanChoice({required List<StoreProduct> products, required this.featured})
    : products = List<StoreProduct>.unmodifiable(
        <StoreProduct>[...products]
          ..sort((a, b) => a.plan.index.compareTo(b.plan.index)),
      );

  /// Monthly then yearly.
  final List<StoreProduct> products;

  /// The plan selected when the paywall opens.
  final SubscriptionPlan featured;

  bool get isEmpty => products.isEmpty;

  StoreProduct? productFor(SubscriptionPlan plan) =>
      products.where((product) => product.plan == plan).firstOrNull;

  /// The plan to select first: the featured one, or whichever exists.
  SubscriptionPlan get initialPlan =>
      productFor(featured) != null ? featured : products.first.plan;

  /// How much a year of the yearly plan saves against twelve months, as a
  /// whole percentage — or null when either plan is missing, they are in
  /// different currencies, or it saves nothing. A proportion of two store
  /// prices, so no currency is ever formatted here (`ENG-20`).
  int? get yearlySavingPercent {
    final monthly = productFor(SubscriptionPlan.monthly);
    final yearly = productFor(SubscriptionPlan.yearly);
    if (monthly == null || yearly == null) return null;
    if (monthly.currencyCode != yearly.currencyCode) return null;
    final twelveMonths = monthly.priceMicros * 12;
    if (twelveMonths <= 0 || yearly.priceMicros >= twelveMonths) return null;
    final percent = ((twelveMonths - yearly.priceMicros) * 100) ~/ twelveMonths;
    return percent > 0 ? percent : null;
  }
}
