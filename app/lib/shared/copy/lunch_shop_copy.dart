import '../../features/groceries/model/product_match.dart';
import 'checkers_copy.dart';

/// The shop in *Plan my week*'s brief (`FE-19`, lunch-box ADR-0026): which
/// shop, where it looks, and the choice between shops.
abstract final class LunchShopCopy {
  static const shopHeader = 'Shop';
  static String shopNear(ProductRetailer shop, String area) =>
      '${_storeName(shop)} near $area';
  static String shopNearYou(ProductRetailer shop) =>
      '${_storeName(shop)} near you';
  static String shopFinding(ProductRetailer shop) =>
      'Finding your nearest ${CheckersCopy.retailerName(shop)}…';
  static String shopOnly(ProductRetailer shop) =>
      '${CheckersCopy.retailerName(shop)} is the only shop for now.';
  static const changeArea = 'Change area';

  // ---- choosing the shop ----
  static const chooseShop =
      'Choose where to shop. The week is built from what that shop sells.';
  static String shopChoice(ProductRetailer shop) =>
      'Shop at ${CheckersCopy.retailerName(shop)}';

  static String _storeName(ProductRetailer shop) => switch (shop) {
    ProductRetailer.checkers => 'Checkers Sixty60',
    ProductRetailer.pickNPay => CheckersCopy.retailerName(shop),
    ProductRetailer.woolworths => 'Woolies Dash',
  };
}
