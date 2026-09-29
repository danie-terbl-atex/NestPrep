import 'package:flutter/foundation.dart';

import 'subscription_plan.dart';

/// What premium this household is offered, as `getSubscriptionOffer` answers
/// (subscriptions ADR-0001): whether it is on sale at all, whether this
/// viewer may buy it, the store product for each plan, and which plan the
/// pricing test shows first. No price: the store says that, in the family's
/// own currency.
@immutable
class SubscriptionOffer {
  const SubscriptionOffer({
    required this.isAvailable,
    required this.canBuy,
    required this.cohort,
    required this.featuredPlan,
    required this.productIds,
  });

  /// Nothing configured on the server yet — premium is not on sale.
  static const unavailable = SubscriptionOffer(
    isAvailable: false,
    canBuy: false,
    cohort: 'a',
    featuredPlan: SubscriptionPlan.yearly,
    productIds: {},
  );

  final bool isAvailable;

  /// Family may buy; a helper or carer is told what premium is and who can.
  final bool canBuy;

  /// The pricing test's cohort, `a` or `b`.
  final String cohort;
  final SubscriptionPlan featuredPlan;
  final Map<SubscriptionPlan, String> productIds;

  @override
  bool operator ==(Object other) =>
      other is SubscriptionOffer &&
      other.isAvailable == isAvailable &&
      other.canBuy == canBuy &&
      other.cohort == cohort &&
      other.featuredPlan == featuredPlan &&
      mapEquals(other.productIds, productIds);

  @override
  int get hashCode => Object.hash(
    isAvailable,
    canBuy,
    cohort,
    featuredPlan,
    Object.hashAllUnordered(productIds.entries.map((e) => (e.key, e.value))),
  );
}
