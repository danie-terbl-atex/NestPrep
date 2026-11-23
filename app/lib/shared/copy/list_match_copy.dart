import '../../features/groceries/model/product_match.dart';
import '../money/money.dart';
import 'checkers_copy.dart';

/// Every word the grocery list's step-by-step matching says (`FE-19`,
/// groceries ADR-0010).
abstract final class ListMatchCopy {
  static const title = 'Match your list';
  static const close = 'Close';
  static const previous = 'Previous item';

  static String step(int index, int total) => 'Item ${index + 1} of $total';
  static String allDone(int total) =>
      total == 1 ? 'Your 1 item is done' : 'All $total items done';
  static String picked(int count) => '$count picked';

  static const chooseHint = 'Tap the one you want.';
  static const nothingToPick = 'Nothing to pick here.';
  static const next = 'Next';
  static const skip = 'Skip';
  static const remove = 'Remove';
  static const keep = 'Keep it';
  static const carryOn = 'Carry on';

  static String emptyBody(ProductRetailer shop) =>
      '${CheckersCopy.retailerName(shop)} has nothing by that name near '
      'you. Skip it and it stays on your list, or remove it.';
  static const removedTitle = 'Coming off your list';
  static String removedBody(String item) =>
      '$item comes off your grocery list when you’re done here.';

  static String product(
    String name,
    String price, {
    required bool isSelected,
    required bool isBestMatch,
    required bool isInStock,
  }) => [
    name,
    price,
    if (isBestMatch) CheckersCopy.bestMatch,
    if (!isInStock) CheckersCopy.outOfStock,
    if (isSelected) 'selected',
  ].join(', ');

  static String summaryFigure(int picked, int total) => '$picked of $total';
  static String summaryMatched(ProductRetailer shop) =>
      'matched at ${CheckersCopy.retailerName(shop)}';
  static String estimate(Money total) => 'About ${total.display}, one of each.';
  static String skipped(int count) => count == 1
      ? '1 skipped. It stays on your list as it is.'
      : '$count skipped. They stay on your list as they are.';
  static String removed(int count) =>
      count == 1 ? '1 comes off your list.' : '$count come off your list.';
  static String toCart(ProductRetailer shop) =>
      'Add to my ${CheckersCopy.retailerName(shop)} cart';
  static const backToList = 'Back to my list';
}
