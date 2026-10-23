import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../../add_to_checkers/model/checkers_area.dart';
import '../../live_location/model/coordinates.dart';
import 'pnp_catalogue_parser.dart';
import 'pnp_occ_client.dart';

/// Which Pick n Pay store prices a point (add-to-pnp ADR-0002 §2). PnP has
/// no "stores near here" that answers, so this does what its website does:
/// a throw-away anonymous cart, a delivery address on it, the cart's
/// `baseStore`, then the cart deleted. PnP insists the address is complete
/// in shape but chooses the store by its coordinates, so the street is a
/// placeholder and the town and postal code are the nearest area's.
/// Remembered per ~1 km for as long as the app runs; a failed lookup is not.
final class PnpStoreFinder {
  PnpStoreFinder(this._occ);

  static const _placeholderStreetNumber = '1';
  static const _placeholderStreet = 'Main Road';

  final PnpOccClient _occ;
  final _stores = <String, Future<String>>{};

  Future<String> storeFor(Coordinates near) {
    final key =
        '${near.latitude.toStringAsFixed(2)},'
        '${near.longitude.toStringAsFixed(2)}';
    return _stores[key] ??= _remembered(key, near);
  }

  /// A lookup that fails is forgotten, so the next search asks again.
  Future<String> _remembered(String key, Coordinates near) async {
    try {
      return await _lookUp(near);
    } on Object {
      _forgetStore(key);
      rethrow;
    }
  }

  Future<String> _lookUp(Coordinates near) async {
    final guid = PnpCatalogueParser.cartGuid(
      await _occ.post('/users/anonymous/carts', const {'fields': 'guid'}, {}),
    );
    if (guid == null) throw const PnpFailure(PnpProblem.catalogueChanged);
    final cartPath = '/users/anonymous/carts/$guid';
    try {
      final address = await _occ.send(
        'POST',
        '$cartPath/addresses/delivery',
        const {},
        body: _address(near),
      );
      if (address.status == 400) {
        throw const PnpFailure(PnpProblem.noStoreNearby);
      }
      if (address.status < 200 || address.status >= 300) {
        final status = address.status.toString();
        AppLog.failure('pnp store', code: status);
        throw const PnpFailure(PnpProblem.catalogueUnreachable);
      }
      final store = PnpCatalogueParser.storeCode(
        await _occ.get(cartPath, const {'fields': 'baseStore(uid)'}),
      );
      return store ?? (throw const PnpFailure(PnpProblem.catalogueChanged));
    } finally {
      await _forget(cartPath);
    }
  }

  /// The cart is PnP's to expire; deleting it is a courtesy, so a failure is
  /// logged and the store still answers.
  Future<void> _forget(String cartPath) async {
    try {
      await _occ.send('DELETE', cartPath, const {});
    } on PnpFailure catch (failure) {
      AppLog.failure('pnp store cart delete', code: failure.problem.name);
    }
  }

  static Map<String, Object?> _address(Coordinates near) {
    final area = CheckersArea.nearest(near);
    return {
      'streetnumber': _placeholderStreetNumber,
      'streetname': _placeholderStreet,
      'line2': '$_placeholderStreetNumber $_placeholderStreet',
      'district': area.label,
      'town': area.label,
      'postalCode': area.postalCode,
      // About a kilometre — enough for PnP to choose the store, no closer to
      // where anybody lives (add-to-pnp ADR-0002).
      'latitude': _roughly(near.latitude),
      'longitude': _roughly(near.longitude),
      'country': const {'isocode': 'ZA'},
      'defaultAddress': false,
    };
  }

  static double _roughly(double degrees) =>
      double.parse(degrees.toStringAsFixed(2));

  // Not awaited: what it held is the future that just failed.
  void _forgetStore(String key) => _stores.remove(key);
}
