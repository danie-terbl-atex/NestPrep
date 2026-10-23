import '../../features/groceries/model/product_match.dart';
import '../failure/app_failure.dart';
import '../money/money.dart';

/// Every word the Checkers product matches and *Add to Checkers* say
/// (`FE-19`) — beside `AppCopy` like the other features' words.
/// `AppCopy.failure` reaches [problem] through one line.
abstract final class CheckersCopy {
  // ---- product matches, under an item ----
  static String findAt(ProductRetailer retailer) =>
      'Find at ${retailerName(retailer)}';

  // ---- the shop picker, above the list ----
  static String shopAtRetailer(ProductRetailer retailer) =>
      'Shop at ${retailerName(retailer)}';
  static String comingSoon(List<ProductRetailer> retailers) =>
      '${retailers.map(retailerName).join(' and ')} coming soon';
  static String retailerName(ProductRetailer retailer) => switch (retailer) {
    ProductRetailer.checkers => 'Checkers',
    ProductRetailer.pickNPay => 'Pick n Pay',
    ProductRetailer.woolworths => 'Woolworths',
  };
  static String retailerSoon(ProductRetailer retailer) =>
      '${retailerName(retailer)}, coming soon';
  static String matchesTitle(ProductRetailer shop, String itemName) =>
      'At ${retailerName(shop)}: $itemName';
  static String matchesLoading(ProductRetailer shop) =>
      'Looking at ${retailerName(shop)}…';
  static String matchesEmptyTitle(ProductRetailer shop) =>
      'Nothing close at ${retailerName(shop)}';
  static String matchesEmptyBody(ProductRetailer shop) =>
      '${retailerName(shop)} has nothing by that name near you. The item is '
      'on the list either way.';
  static const closeMatches = 'Close';
  static const pick = 'Pick';
  static const outOfStock = 'Out of stock';
  static const deal = 'Deal';
  static const bestMatch = 'Best match';
  static String was(Money oldPrice) => 'was ${oldPrice.display}';
  static String price(Money price, {required bool perKilogram}) =>
      perKilogram ? '${price.display}/kg' : price.display;
  static const changeMatch = 'Change product';
  static const clearMatch = 'Remove product';
  static String matchedSemantics(ProductRetailer shop, String productName) =>
      '${retailerName(shop)} product: $productName';

  // ---- where the matches come from ----
  static const nearYou = 'Near you';
  static String nearArea(String area) => 'Near $area';
  static const changeArea = 'Change area';
  static const areaTitle = 'Your shopping area';
  static const areaBody =
      'NestPrep uses your location for this only if you already let it. '
      'Otherwise, choose the city you shop in.';

  // ---- the cart actions on the list (add-to-pnp ADR-0007) ----
  static String readyToAdd(ProductRetailer shop, int count) => count == 1
      ? '1 item has a ${retailerName(shop)} product'
      : '$count items have a ${retailerName(shop)} product';
  static String addCountTo(ProductRetailer shop, int count) =>
      'Add $count to ${retailerName(shop)}';
  static String notMatched(int count) =>
      count == 1 ? '1 item not matched' : '$count items not matched';

  // ---- linking ----
  static const linkTitle = 'Link Checkers';
  static const linkIntro =
      'Link your own Checkers Sixty60 account so NestPrep can put the list '
      'into your cart. You finish and pay in the Checkers app.';
  static const linkHourNote =
      'Checkers keeps the link for one hour. After that, NestPrep asks for a '
      'new code before adding again.';
  static const notAffiliated =
      'NestPrep is not affiliated with or endorsed by Checkers or Shoprite.';
  static const mobileLabel = 'Mobile number';
  static const mobileHint = '082 123 4567';
  static const sendCode = 'Send code';
  static String codeSentTo(String masked) =>
      'Checkers sent a code by SMS to $masked.';
  static const codeLabel = 'Code from the SMS';
  static const verify = 'Link account';
  static const changeNumber = 'Use a different number';
  static const linkedTitle = 'Checkers is linked';
  static String linkedBody(String masked, String until) =>
      'Linked to $masked until $until.';
  static const unlink = 'Unlink Checkers';
  static const retry = 'Try again';

  static String problem(CheckersProblem problem) => switch (problem) {
    CheckersProblem.noStoreNearby =>
      'No Checkers Sixty60 store delivers there. Try another area.',
    CheckersProblem.catalogueBusy =>
      'Checkers is busy. Give it a minute, then try again.',
    CheckersProblem.catalogueUnreachable =>
      'NestPrep cannot reach Checkers right now. Check your connection.',
    CheckersProblem.catalogueChanged =>
      'Checkers answered in a way NestPrep does not understand yet. '
          'Update NestPrep, or try again later.',
    CheckersProblem.badMobile =>
      'That does not look like a South African mobile number.',
    CheckersProblem.otpRateLimited =>
      'Too many codes asked for. Wait fifteen minutes, then try again.',
    CheckersProblem.checkersDown =>
      'Checkers is not answering right now. Try again in a little while.',
    CheckersProblem.noPendingOtp => 'That code has expired. Ask for a new one.',
    CheckersProblem.wrongCode => 'That code is not right. Check the SMS.',
    CheckersProblem.linkExpired =>
      'Your Checkers link has run out. Link again to carry on.',
    CheckersProblem.noStoreForAccount =>
      'No Checkers Sixty60 store delivers to the address on your Checkers '
          'account. Change it in the Checkers app, then try again.',
    CheckersProblem.featureOff =>
      'Add to Checkers is not switched on for NestPrep right now.',
  };
}
