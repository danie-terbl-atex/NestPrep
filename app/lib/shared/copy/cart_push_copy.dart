import '../../features/groceries/model/product_match.dart';
import '../money/money.dart';
import 'checkers_copy.dart';

/// Every word a cart push says, for any shop (`FE-19`): *Add to Checkers*
/// from the grocery list, *Add to my Pick n Pay cart* from *Plan my week*
/// (add-to-pnp ADR-0004). The shop is named in words.
abstract final class CartPushCopy {
  static String title(ProductRetailer shop) => 'Add to ${_name(shop)}';
  static String addToMyCart(ProductRetailer shop) =>
      'Add to my ${_name(shop)} cart';
  static String pushing(ProductRetailer shop) =>
      'Adding to your ${_name(shop)} cart…';
  static const emptyTitle = 'Nothing was added';
  static const emptyBody =
      'None of these could go in your cart right now. The reasons are below.';
  static String addedCount(int count) =>
      count == 1 ? '1 item added' : '$count items added';
  static String skippedCount(int count) =>
      count == 1 ? '1 item not added' : '$count items not added';
  static String cartSummary(int items, Money total) =>
      'Your cart now has $items ${items == 1 ? 'item' : 'items'} · '
      '${total.display}';
  static String finishIn(ProductRetailer shop) => switch (shop) {
    ProductRetailer.checkers =>
      'Finish and pay in the Checkers Sixty60 app. NestPrep never checks out '
          'for you.',
    ProductRetailer.woolworths =>
      'Finish and pay in the Woolies Dash app. NestPrep never checks out for '
          'you.',
    _ =>
      'Finish and pay in the ${_name(shop)} app or website. NestPrep never '
          'checks out for you.',
  };
  static String skipNoMatch(ProductRetailer shop) =>
      'No ${_name(shop)} product picked';
  static const skipOutOfStock = 'Out of stock at your store';
  static String skipNotFound(ProductRetailer shop) =>
      '${_name(shop)} no longer has this product at your store';
  static String skipWeighed(ProductRetailer shop) =>
      'Sold by weight — add it in the ${_name(shop)} app so you choose how '
      'much';
  static String skipCartFull(ProductRetailer shop) =>
      'Your ${_name(shop)} cart has no room for more items';
  static String skipLowStock(ProductRetailer shop) =>
      '${_name(shop)} does not have enough of this right now';
  static String skipMaxQuantity(ProductRetailer shop) =>
      '${_name(shop)} limits how many of these one order can hold';
  static String skipShopRefused(ProductRetailer shop) =>
      '${_name(shop)} would not add this one — add it in their app';
  static const skipUnknown = 'Could not be added';
  static String needsLink(ProductRetailer shop) => switch (shop) {
    ProductRetailer.checkers =>
      'Your Checkers link has run out. Link again to carry on.',
    _ => 'Link your ${_name(shop)} account to add to your cart.',
  };
  static String link(ProductRetailer shop) => 'Link ${_name(shop)}';
  static String manageLink(ProductRetailer shop) => '${_name(shop)} account';
  static const done = 'Done';
  static const retry = 'Try again';

  static String _name(ProductRetailer shop) => CheckersCopy.retailerName(shop);
}
