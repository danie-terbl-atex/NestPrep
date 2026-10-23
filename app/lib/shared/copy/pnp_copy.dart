import '../failure/app_failure.dart';

/// Every word linking Pick n Pay and adding a lunch week to its cart says
/// (`FE-19`, add-to-pnp ADR-0001, ADR-0003). `AppCopy.failure` reaches
/// [problem] through one line.
abstract final class PnpCopy {
  // ---- the done step of Plan my week ----
  static const addToMyCart = 'Add to my Pick n Pay cart';

  // ---- linking ----
  static const linkTitle = 'Link Pick n Pay';
  static const linkIntro =
      'Link your own Pick n Pay account so NestPrep can put a lunch week into '
      'your cart. You finish and pay in the Pick n Pay app or website.';
  static const passwordNote =
      'You sign in on Pick n Pay’s own page. NestPrep never sees your '
      'password.';
  static const notAffiliated =
      'NestPrep is not affiliated with or endorsed by Pick n Pay.';
  static const signIn = 'Sign in to Pick n Pay';
  static const signInPageTitle = 'Pick n Pay sign-in';
  static const closeSignIn = 'Close the sign-in page';
  static const linkedTitle = 'Pick n Pay is linked';
  static String linkedSince(String date) => 'Linked since $date.';
  static const linkedBody =
      'NestPrep can add a lunch week to your Pick n Pay cart until you unlink.';
  static const unlink = 'Unlink Pick n Pay';

  // ---- Pick n Pay's sign-in page, inside the app ----
  static const signInPageFailedTitle = 'The sign-in page did not open';
  static const signInPageFailed =
      'Pick n Pay’s sign-in page could not be reached. Check your connection '
      'and try again.';
  static const signInPageRetry = 'Try again';
  static const signInPageElsewhere =
      'Do that on the Pick n Pay website or app, then come back here to sign '
      'in.';
  static const signInPageNoticeDismiss = 'OK';

  static String problem(PnpProblem problem) => switch (problem) {
    PnpProblem.noStoreNearby =>
      'Pick n Pay does not deliver there. Try another area, or plan at '
          'Checkers.',
    PnpProblem.catalogueBusy =>
      'Pick n Pay is busy. Give it a minute, then try again.',
    PnpProblem.catalogueUnreachable =>
      'NestPrep cannot reach Pick n Pay right now. Check your connection.',
    PnpProblem.catalogueChanged =>
      'Pick n Pay answered in a way NestPrep does not understand yet. '
          'Update NestPrep, or try again later.',
    PnpProblem.featureOff =>
      'Pick n Pay is not switched on for NestPrep right now.',
    PnpProblem.noPendingLink =>
      'That sign-in took too long. Start again from Sign in.',
    PnpProblem.linkRefused =>
      'Pick n Pay did not accept that sign-in. Try signing in again.',
    PnpProblem.linkCancelled =>
      'You left the Pick n Pay sign-in before it finished. Nothing was '
          'linked.',
    PnpProblem.linkExpired =>
      'Your Pick n Pay link has run out. Link again to carry on.',
    PnpProblem.pnpDown =>
      'Pick n Pay is not answering right now. Try again in a little while.',
    PnpProblem.noDeliveryAddress =>
      'Set a delivery address in your Pick n Pay app or website, then try '
          'again.',
  };
}
