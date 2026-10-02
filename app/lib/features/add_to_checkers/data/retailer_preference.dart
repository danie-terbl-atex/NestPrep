import '../../groceries/model/product_match.dart';

/// The shop a member looks things up at, kept on this phone per household
/// (not in Firestore), beside the Checkers area: it only steers which shop
/// *Find at* asks, and no other member's phone needs it.
abstract interface class RetailerPreference {
  /// Null until somebody on this phone chooses one for [householdId].
  Future<ProductRetailer?> read(String householdId);

  Future<void> write(String householdId, ProductRetailer retailer);
}
