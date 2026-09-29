import '../../subscriptions/model/premium_feature.dart';

/// Tells the server the paywall opened on [PremiumFeature] — the denominator
/// of conversion by trigger, and what a purchase that follows is attributed
/// to (product-analytics ADR-0002). Only the household and the trigger are
/// sent; who opened it the server works out from the token.
abstract interface class PaywallOpenRecorder {
  Future<void> recordPaywallOpened({
    required String householdId,
    required PremiumFeature trigger,
  });
}
