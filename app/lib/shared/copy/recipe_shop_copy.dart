import '../../features/groceries/model/product_match.dart';
import '../money/money.dart';
import 'checkers_copy.dart';

/// Every word *Add to grocer* says (`FE-19`, recipes ADR-0005): the card
/// under a planned recipe's ingredients, and the sheet that finds what the
/// recipe still needs at the shop.
abstract final class RecipeShopCopy {
  // ---- the card on the recipe page ----
  static const cardTitle = 'Shop for this recipe';
  static String cardBody(int count) => switch (count) {
    0 => 'Everything is ticked off, so there is nothing left to buy.',
    1 => 'We’ll find the 1 ingredient you haven’t ticked off at your shop.',
    _ =>
      'We’ll find the $count ingredients you haven’t ticked off at your '
          'shop. Tick off what you already have first.',
  };
  static const action = 'Add to grocer';
  static const premiumTag = 'Premium';

  // ---- the sheet ----
  static const sheetTitle = 'Add to grocer';
  static String searching(ProductRetailer shop, int done, int total) =>
      'Looking at ${CheckersCopy.retailerName(shop)}… $done of $total';
  static String found(ProductRetailer shop) =>
      'Found at ${CheckersCopy.retailerName(shop)}. Untick anything you '
      'don’t need, or tap Change for another product.';
  static String notFound(ProductRetailer shop) =>
      'Not found at ${CheckersCopy.retailerName(shop)}. It goes on your list '
      'by name.';
  static const failed =
      'This search didn’t work. It goes on your list by name.';
  static const change = 'Change';
  static String changeTitle(String ingredient) => 'Products for $ingredient';
  static String includeLabel(String ingredient, bool isIncluded) =>
      isIncluded ? '$ingredient, on the list' : '$ingredient, left off';
  static String estimate(Money total, ProductRetailer shop) =>
      'About ${total.display} at ${CheckersCopy.retailerName(shop)}, one of '
      'each';
  static String addToList(int count) => count == 1
      ? 'Add 1 to the grocery list'
      : 'Add $count to the grocery list';
  static String addToCart(ProductRetailer shop) =>
      'Add to my ${CheckersCopy.retailerName(shop)} cart';
  static String added(int count) => switch (count) {
    0 => 'All of it was on your grocery list already.',
    1 => '1 item added to your grocery list.',
    _ => '$count items added to your grocery list.',
  };
  static const nothingIncluded = 'Tick at least one item to add.';
  static const done = 'Done';
}
