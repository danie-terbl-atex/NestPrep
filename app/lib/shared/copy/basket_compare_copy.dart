import '../../features/groceries/model/product_match.dart';
import '../money/money.dart';
import 'checkers_copy.dart';

/// Every word *Compare shops* says (basket-compare ADR-0001, `FE-19`). The
/// verdict is like for like, so the copy names "both shops" for two and
/// "every shop" for more.
abstract final class BasketCompareCopy {
  static const title = 'Compare shops';

  // ---- the way in, on the grocery list ----
  static const entryTitle = 'Compare prices across shops';
  static String entryBody(List<ProductRetailer> shops) =>
      'See whether ${_names(shops)} is cheaper for this list';

  // ---- while the shops answer ----
  static String checking(int settled, int total) =>
      'Checking prices… $settled of $total';
  static String checkingSemantics(int settled, int total) =>
      'Checking prices, $settled of $total ${_items(total)} done';

  // ---- the verdict ----
  static String cheapest(ProductRetailer shop) => '${_name(shop)} is cheapest';
  static String saving(Money saving, int count, int shopCount) =>
      'You save ${saving.display} on the $count ${_items(count)} '
      '${_have(shopCount)}';
  static String samePrice(int shopCount) =>
      shopCount == 2 ? 'Same price at both' : 'Same price at every shop';
  static String samePriceBody(Money total, int count, int shopCount) =>
      'The $count ${_items(count)} ${_have(shopCount)} '
      '${count == 1 ? 'costs' : 'cost'} ${total.display} at each.';
  static const noCommonTitle = 'No like-for-like price yet';
  static String noCommonBody(int shopCount) =>
      'Nothing on the list is ${_at(shopCount)} yet, so there is no fair '
      'comparison. Each shop’s total for what it has is below.';
  static const waitingTitle = 'Checking prices…';
  static const waitingBody =
      'The cheapest shop shows here as the prices come in.';
  static const soFar = 'So far. More prices are on the way.';

  // ---- each shop's basket ----
  static const totalsTitle = 'What each shop costs';
  static String foundOf(int found, int total) =>
      '$found of $total ${_items(total)}';
  static String notAvailable(int count) => '$count not available';
  static const cheapestTag = 'Cheapest';
  static String likeForLike(Money amount, int shopCount) =>
      '${amount.display} for the items ${_have(shopCount)}';
  static String split(Money total, Money less) =>
      'Split across shops: ${total.display}, ${less.display} less';
  static const splitNote =
      'Each item where it is cheapest. NestPrep fills one shop’s cart at a '
      'time, so this is for interest.';

  // ---- the items ----
  static String notEverywhereTitle(int shopCount) =>
      shopCount == 2 ? 'Not at both shops' : 'Not at every shop';
  static String everywhereTitle(int shopCount) =>
      shopCount == 2 ? 'At both shops' : 'At every shop';
  static const stillChecking = 'Still checking';
  static String leftOut(int count) => count == 1
      ? '1 more item on the list wasn’t compared.'
      : '$count more items on the list weren’t compared.';
  static String packs(int count) => '× $count';
  static String perPack(Money unit, int packs) => '$packs × ${unit.display}';
  static String was(Money oldPrice) => CheckersCopy.was(oldPrice);
  static const deal = CheckersCopy.deal;
  static const pickedEarlier = 'Price when picked';
  static const closest = 'Closest match';
  static String notAt(ProductRetailer shop) => 'Not at ${_name(shop)}';
  static String outOfStockAt(ProductRetailer shop) =>
      'Out of stock at ${_name(shop)}';
  static String unreachable(ProductRetailer shop) =>
      'Couldn’t reach ${_name(shop)}';
  static const retry = 'Try again';
  static String offerSemantics(
    ProductRetailer shop,
    String product,
    Money total,
  ) => '${_name(shop)}: $product, ${total.display}';
  static String checkingAt(ProductRetailer shop) => 'Checking ${_name(shop)}…';

  // ---- one shop for the whole list ----
  static const useTitle = 'Shop at one place';
  static const useBody =
      'Picks each item’s product at that shop. Then add them to its cart from '
      'the list.';
  static String useShop(ProductRetailer shop) =>
      'Use ${_name(shop)} for this list';
  static String confirmTitle(ProductRetailer shop) =>
      'Use ${_name(shop)} for this list?';
  static String confirmBody(ProductRetailer shop, int replaced) =>
      'This changes $replaced ${replaced == 1 ? 'pick' : 'picks'} to '
      '${_name(shop)}. Items ${_name(shop)} doesn’t have keep their pick.';
  static String confirmUse(ProductRetailer shop) => 'Use ${_name(shop)}';
  static const keepPicks = 'Keep my picks';

  // ---- the small print ----
  static String footer(String? area) =>
      'Prices from each shop ${area == null ? 'near you' : 'for $area'} right '
      'now. They can change at checkout. NestPrep isn’t affiliated with these '
      'shops.';

  // ---- nothing to compare ----
  static const emptyTitle = 'Nothing to compare';
  static const emptyBody =
      'Everything on the list is bought. Add something, then compare again.';

  static String _name(ProductRetailer shop) => CheckersCopy.retailerName(shop);

  static String _names(List<ProductRetailer> shops) {
    final names = shops.map(_name).toList();
    if (names.length < 2) return names.join();
    return '${names.sublist(0, names.length - 1).join(', ')} or ${names.last}';
  }

  static String _items(int count) => count == 1 ? 'item' : 'items';

  static String _have(int shopCount) =>
      shopCount == 2 ? 'both shops have' : 'every shop has';

  static String _at(int shopCount) =>
      shopCount == 2 ? 'at both shops' : 'at every shop';
}
