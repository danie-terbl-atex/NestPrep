import '../../live_location/model/coordinates.dart';
import '../model/woolworths_store.dart';
import 'woolworths_catalogue_parser.dart';
import 'woolworths_web_client.dart';

/// The store and price list Woolworths fulfils a point from, by
/// `validatePlace`, asked to about a kilometre — enough for Woolworths to
/// choose the store, no closer to where anybody lives — and remembered for
/// the run.
final class WoolworthsStoreFinder {
  WoolworthsStoreFinder(this._web);

  final WoolworthsWebClient _web;
  final _stores = <String, Future<WoolworthsStore>>{};

  Future<WoolworthsStore> storeFor(Coordinates near) {
    final latitude = near.latitude.toStringAsFixed(2);
    final longitude = near.longitude.toStringAsFixed(2);
    final key = '$latitude,$longitude';
    return _stores[key] ??= _remembered(key, latitude, longitude);
  }

  /// A lookup that fails is forgotten, so the next search asks again.
  Future<WoolworthsStore> _remembered(
    String key,
    String latitude,
    String longitude,
  ) async {
    try {
      return WoolworthsCatalogueParser.store(
        await _web.site('validatePlace', {
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
    } on Object {
      _forget(key);
      rethrow;
    }
  }

  // Not awaited: what it held is the future that just failed.
  void _forget(String key) => _stores.remove(key);
}
