import '../../features/groceries/model/product_match.dart';
import 'checkers_copy.dart';

/// *Plan my week* when there is nothing new to plan, and the cart reached
/// again from the brief (`FE-19`, lunch-box ADR-0027).
abstract final class PlanWeekAgainCopy {
  // ---- a week with nothing new ----
  static String nothingNewBody(ProductRetailer shop) =>
      'Every compartment you chose is planned already for this week, or '
      'nothing kept fits. Go back to the brief to choose other compartments, '
      'children or ideas — or to send the ${CheckersCopy.retailerName(shop)} '
      'items already on your list to your cart.';
  static const backToBrief = 'Back to the brief';

  // ---- the cart from the list ----
  static String listCartTitle(ProductRetailer shop) =>
      '${CheckersCopy.retailerName(shop)} items on your list';
  static String listCartBody(ProductRetailer shop) =>
      'Planned a week already? Send its ${CheckersCopy.retailerName(shop)} '
      'items on your grocery list to your cart — again, if it did not work '
      'the first time.';
  static String listCartAction(ProductRetailer shop) =>
      'Add them to my ${CheckersCopy.retailerName(shop)} cart';
  static String listCartNone(ProductRetailer shop) =>
      'No ${CheckersCopy.retailerName(shop)} items are waiting on your list.';
}
