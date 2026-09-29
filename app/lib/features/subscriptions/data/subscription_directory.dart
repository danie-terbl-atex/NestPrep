import '../model/billing_store.dart';
import '../model/premium_feature.dart';
import '../model/subscription_offer.dart';

/// The subscriptions callables (subscriptions ADR-0001). A purchase becomes
/// premium only here, on the server, after the store has vouched for it —
/// the client never writes its own entitlement. Each refusal arrives as an
/// `AppFailure`, never an SDK error (`BE-04`).
abstract interface class SubscriptionDirectory {
  Future<SubscriptionOffer> offer(String householdId);

  /// Hands the server what the store gave the phone. [trigger] is what opened
  /// the paywall, for a purchase; null for a restore, which is never counted
  /// as a conversion. Answers whether the household now has premium.
  Future<bool> verify({
    required String householdId,
    required BillingStore store,
    required String verificationData,
    required PremiumFeature? trigger,
  });
}
