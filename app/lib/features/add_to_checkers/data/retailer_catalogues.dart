import '../../groceries/model/product_match.dart';
import 'retailer_catalogue.dart';

/// Each connected shop's catalogue (lunch-box ADR-0026, add-to-pnp ADR-0007):
/// one memory of stores and searches per shop for the run, read by *Plan my
/// week* and by the grocery list's matches alike.
final class RetailerCatalogues {
  const RetailerCatalogues({required this.checkers, required this.pickNPay});

  final RetailerCatalogue checkers;
  final RetailerCatalogue pickNPay;

  /// [shop]'s catalogue. A shop that is not connected has none, and is
  /// never offered (`ProductRetailer.isConnected`).
  RetailerCatalogue of(ProductRetailer shop) => switch (shop) {
    ProductRetailer.checkers => checkers,
    ProductRetailer.pickNPay => pickNPay,
    ProductRetailer.woolworths => throw StateError('no catalogue for $shop'),
  };
}
