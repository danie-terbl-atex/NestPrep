import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../shared/log/app_log.dart';
import '../../groceries/model/product_match.dart';
import 'lunch_shop_preference.dart';
import 'retailer_preference.dart';

/// A chosen shop in `flutter_secure_storage`, the way the Checkers area is
/// kept — the app's one key-value store on the phone, so no dependency. The
/// grocery screen's *Shop at* is kept under [groceryPrefix], *Plan my week*'s
/// shop under [lunchShopPrefix] (lunch-box ADR-0026).
final class SecureStorageRetailerPreference
    implements RetailerPreference, LunchShopPreference {
  SecureStorageRetailerPreference({
    FlutterSecureStorage? storage,
    this._prefix = groceryPrefix,
  }) : _storage = storage ?? const FlutterSecureStorage();

  static const groceryPrefix = 'nestprep.retailer.';
  static const lunchShopPrefix = 'nestprep.lunchShop.';

  final FlutterSecureStorage _storage;
  final String _prefix;

  @override
  Future<ProductRetailer?> read(String householdId) async {
    try {
      final code = await _storage.read(key: '$_prefix$householdId');
      return code == null ? null : ProductRetailer.fromCode(code);
    } on PlatformException catch (error) {
      // An unreadable choice is the same as none: the default shop is used,
      // and choosing again writes a fresh one.
      AppLog.failure('retailer read', code: error.code, error: error);
      return null;
    }
  }

  @override
  Future<void> write(String householdId, ProductRetailer retailer) async {
    try {
      await _storage.write(key: '$_prefix$householdId', value: retailer.code);
    } on PlatformException catch (error) {
      // The choice still applies for this run — the controller holds it.
      AppLog.failure('retailer write', code: error.code, error: error);
    }
  }
}
