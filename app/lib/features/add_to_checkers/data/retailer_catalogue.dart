import '../../live_location/model/coordinates.dart';
import '../model/retailer_product.dart';
import '../model/retailer_shelf.dart';

/// A shop's catalogue, searched straight from the phone with no sign-in:
/// Checkers Sixty60 (add-to-checkers ADR-0003) or Pick n Pay (add-to-pnp
/// ADR-0002). Every failure arrives as that shop's `AppFailure`, never as an
/// HTTP error.
abstract interface class RetailerCatalogue {
  /// Up to [limit] products for [query] from the store or stores that
  /// deliver to [near], best match first. Empty when the shop has nothing by
  /// that name.
  Future<List<RetailerProduct>> search({
    required String query,
    required Coordinates near,
    int limit = defaultLimit,
  });

  /// Up to [limit] products on [shelf] at the stores that serve [near], in
  /// the shop's own order (lunch-box ADR-0013, ADR-0026). Empty when the
  /// shelf holds nothing there.
  Future<List<RetailerProduct>> shelf({
    required RetailerShelf shelf,
    required Coordinates near,
    int limit = defaultLimit,
  });

  static const defaultLimit = 5;
}
