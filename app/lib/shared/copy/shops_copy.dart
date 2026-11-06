/// Every word *Your shops* says (`FE-19`). Shops are named through
/// `CheckersCopy.retailerName`.
abstract final class ShopsCopy {
  // ---- the account centre's way in ----
  static const centreSection = 'Shopping';
  static const entry = 'Your shops';
  static const entryHint = 'Where you shop, and the accounts you linked';

  // ---- the page ----
  static const title = 'Your shops';
  static String subtitle(String household) => 'For $household';

  static const firstSection = 'Shop first at';
  static const firstBody =
      'The grocery list and recipes look at this shop first. It is kept on '
      'this phone, and you can change it any time.';

  static const accountsSection = 'Your accounts';
  static const linkingNote =
      'Linking your own account lets NestPrep put the grocery list into your '
      'cart. Nothing is bought: you finish and pay in the shop’s app.';
  static const signInNote =
      'You sign in to Pick n Pay and Woolworths with them, and NestPrep never '
      'sees your password. Checkers sends an SMS code, and its link lasts an '
      'hour.';

  static const checking = 'Checking…';
  static const notLinked = 'Not linked';
  static const linked = 'Linked';
  static String linkedTo(String account) => 'Linked to $account';
  static const link = 'Link';
  static const manage = 'Manage';

  static const noneOnTitle = 'No shops right now';
  static const noneOnBody =
      'Shopping at Checkers, Pick n Pay and Woolworths is switched off for '
      'now. The grocery list works as it always does.';

  static const notYoursTitle = 'Shops come with the grocery list';
  static const notYoursBody =
      'Linking a shop is for whoever adds to the grocery list in this '
      'household. Ask an admin if you need it.';
}
