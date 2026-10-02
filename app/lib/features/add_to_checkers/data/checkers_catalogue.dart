import '../../live_location/model/coordinates.dart';
import '../model/checkers_product.dart';
import '../model/checkers_shelf.dart';

/// The Checkers Sixty60 catalogue, searched straight from the phone with no
/// Checkers sign-in (the Checkers build contract). Every failure arrives as
/// a `CheckersFailure`, never as an HTTP error.
abstract interface class CheckersCatalogue {
  /// Up to [limit] products for [query] from the one-hour-delivery stores
  /// that serve [near], best match first. Empty when Checkers has nothing by
  /// that name.
  Future<List<CheckersProduct>> search({
    required String query,
    required Coordinates near,
    int limit = defaultLimit,
  });

  /// Up to [limit] products on [shelf] at the stores that serve [near], the
  /// best sellers first (lunch-box ADR-0013). Empty when the shelf holds
  /// nothing there.
  Future<List<CheckersProduct>> shelf({
    required CheckersShelf shelf,
    required Coordinates near,
    int limit = defaultLimit,
  });

  static const defaultLimit = 5;
}
