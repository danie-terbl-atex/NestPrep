import 'package:flutter/foundation.dart';

import 'plan_choice.dart';
import 'subscription_offer.dart';

/// What one paywall shows (subscriptions ADR-0001): the offer the server
/// makes this household, with the store's own price for each plan.
@immutable
class PaywallOffer {
  const PaywallOffer({required this.offer, required this.choice});

  final SubscriptionOffer offer;

  /// Null when premium is not on sale yet, or this viewer may not buy.
  final PlanChoice? choice;

  bool get isOnSale {
    final plans = choice;
    return plans != null && !plans.isEmpty;
  }
}
