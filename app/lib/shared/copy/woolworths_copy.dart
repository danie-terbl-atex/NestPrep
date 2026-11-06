import '../failure/app_failure.dart';

/// Every word linking Woolworths says (`FE-19`, add-to-woolworths ADR-0001).
/// `AppCopy.failure` reaches [problem] through one line.
abstract final class WoolworthsCopy {
  // ---- linking ----
  static const linkTitle = 'Link Woolworths';
  static const linkIntro =
      'Link your own Woolworths account so NestPrep can put the list into '
      'your Woolies Dash cart. You finish and pay in the Woolies Dash app.';
  static const passwordNote =
      'Your email and password go from this phone straight to Woolworths. '
      'NestPrep never sees or keeps your password.';
  static const notAffiliated =
      'NestPrep is not affiliated with or endorsed by Woolworths.';
  static const emailLabel = 'Woolworths email';
  static const passwordLabel = 'Woolworths password';
  static const signIn = 'Sign in to Woolworths';
  static String codeSentTo(String where) => 'Woolworths sent a code to $where.';
  static const codeSent = 'Woolworths sent you a code.';
  static const codeLabel = 'Code from Woolworths';
  static const verify = 'Link account';
  static const startOver = 'Use a different account';
  static const linkedTitle = 'Woolworths is linked';
  static String linkedAs(String email) => 'Linked to $email.';
  static String linkedSince(String date) => 'Linked since $date.';
  static const linkedBody =
      'NestPrep can add the list to your Woolies Dash cart until you unlink.';
  static const unlink = 'Unlink Woolworths';

  static String problem(WoolworthsProblem problem) => switch (problem) {
    WoolworthsProblem.noStoreNearby =>
      'Woolworths does not deliver there. Try another area.',
    WoolworthsProblem.catalogueBusy =>
      'Woolworths is busy. Give it a minute, then try again.',
    WoolworthsProblem.catalogueUnreachable =>
      'NestPrep cannot reach Woolworths right now. Check your connection.',
    WoolworthsProblem.catalogueChanged =>
      'Woolworths answered in a way NestPrep does not understand yet. '
          'Update NestPrep, or try again later.',
    WoolworthsProblem.wrongSignIn =>
      'That email or password is not right for Woolworths.',
    WoolworthsProblem.wrongCode => 'That code is not right. Check it again.',
    WoolworthsProblem.signInExpired =>
      'That sign-in took too long. Sign in again.',
    WoolworthsProblem.tooManyTries =>
      'Too many tries. Wait a few minutes, then try again.',
    WoolworthsProblem.cannotLinkHere =>
      'This account needs something only the Woolworths app can do. Sign in '
          'there first, then come back to link.',
    WoolworthsProblem.signInUnreachable =>
      'NestPrep cannot reach the Woolworths sign-in right now. Check your '
          'connection.',
    WoolworthsProblem.featureOff =>
      'Woolworths is not switched on for NestPrep right now.',
    WoolworthsProblem.notLinked =>
      'Link your Woolworths account to add to your cart.',
    WoolworthsProblem.linkExpired =>
      'Your Woolworths link has run out. Link again to carry on.',
    WoolworthsProblem.linkRejected =>
      'Woolworths did not accept that sign-in. Try signing in again.',
    WoolworthsProblem.woolworthsDown =>
      'Woolworths is not answering right now. Try again in a little while.',
    WoolworthsProblem.cartRefused =>
      'Woolworths would not add to your cart right now. Try again, or add '
          'the items in the Woolies Dash app.',
    WoolworthsProblem.noDeliveryAddress =>
      'Set a delivery address in your Woolies Dash app, then try again.',
  };
}
