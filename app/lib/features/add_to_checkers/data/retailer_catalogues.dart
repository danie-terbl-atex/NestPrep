import '../../groceries/model/product_match.dart';
import 'retailer_catalogue.dart';

/// Each connected shop's catalogue (lunch-box ADR-0026, add-to-pnp ADR-0007):
/// one memory of stores and searches per shop for the run, read by *Plan my
/// week* and by the grocery list's matches alike.
final class RetailerCatalogues {
  RetailerCatalogues(Map<ProductRetailer, RetailerCatalogue> byShop)
    : _byShop = Map.unmodifiable(byShop);

  final Map<ProductRetailer, RetailerCatalogue> _byShop;

  RetailerCatalogue of(ProductRetailer shop) =>
      _byShop[shop] ?? (throw StateError('no catalogue for $shop'));
}
