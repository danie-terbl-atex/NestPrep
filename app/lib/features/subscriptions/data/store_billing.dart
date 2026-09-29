import '../model/billing_store.dart';
import '../model/store_product.dart';
import '../model/store_update.dart';
import '../model/subscription_plan.dart';

/// The phone's own store — Google Play or the App Store — behind one
/// interface, so every controller and screen is tested against a fake and
/// never the plugin (`BE-09`, subscriptions ADR-0001).
abstract interface class StoreBilling {
  /// Which store this phone buys through, or null where there is none.
  BillingStore? get store;

  /// Everything the store says about purchases, including ones it redelivers
  /// from before — a purchase paid for while the app was closing arrives
  /// here on the next start, and is verified then.
  Stream<List<StoreUpdate>> get updates;

  Future<bool> isAvailable();

  /// The store's products for [productIds], with the store's own prices.
  /// Throws `SubscriptionFailure(productsNotFound)` when it knows none of
  /// them.
  Future<List<StoreProduct>> products(Map<SubscriptionPlan, String> productIds);

  /// Opens the store's own purchase sheet. What happens next arrives on
  /// [updates].
  Future<void> buy(StoreProduct product);

  /// Asks the store for everything this account has bought; each arrives on
  /// [updates] as a restore.
  Future<void> restore();

  /// Tells the store the purchase has been delivered. Only after the server
  /// has verified it: an unfinished purchase is redelivered, and on Google
  /// Play one never acknowledged is refunded after three days.
  Future<void> finish(StorePurchased purchase);

  /// Where the person manages or cancels the subscription in their store.
  Uri manageUrl(String? productId);
}
