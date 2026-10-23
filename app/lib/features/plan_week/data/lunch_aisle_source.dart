import '../../groceries/model/product_match.dart';
import '../model/aisle_shelf.dart';

/// Which shelves of a shop's lunchbox aisle to read (lunch-box ADR-0013,
/// ADR-0026). Behind an interface so a test decides without Firestore
/// (`FE-20`).
abstract interface class LunchAisleSource {
  /// [shop]'s shelves to read now — never empty: NestPrep's own list for
  /// that shop when nothing else says otherwise.
  Future<List<AisleShelf>> shelves(ProductRetailer shop);
}
