part of 'app_failure.dart';

// ---- Woolworths: the catalogue, the sign-in and the cart (add-to-woolworths ADR-0001) ----

/// Why a Woolworths catalogue read, sign-in, link or push did not happen. The
/// catalogue and sign-in problems are the phone's own — it talks to
/// Constructor, `woolworths.co.za` and Woolworths' Cognito itself; the rest
/// are the `reason` a Woolworths callable put in its details.
enum WoolworthsProblem {
  /// Woolworths does not deliver to where the search looked.
  noStoreNearby,

  /// Woolworths asked us to slow down (HTTP 429).
  catalogueBusy,

  /// The catalogue could not be reached, or answered with an error.
  catalogueUnreachable,

  /// The catalogue answered in a shape this build does not understand.
  catalogueChanged,

  /// Woolworths did not accept the email and password.
  wrongSignIn,

  /// The code Woolworths sent is not the one typed.
  wrongCode,

  /// The sign-in, or the code it sent, ran out before it was finished.
  signInExpired,

  /// Woolworths is refusing sign-ins from this account for a while.
  tooManyTries,

  /// The account needs something only the Woolworths app can do — a new
  /// password, a confirmed email, a kind of check NestPrep cannot answer.
  cannotLinkHere,

  /// Woolworths' sign-in could not be reached from the phone.
  signInUnreachable,

  /// The `addToWoolworths` switch is off on the server.
  featureOff,

  /// The member has not linked a Woolworths account.
  notLinked,

  /// Woolworths no longer accepts the member's link: they link again.
  linkExpired,

  /// The sign-in finished, but Woolworths would not let the server use it.
  linkRejected,

  /// Woolworths itself is not answering the server.
  woolworthsDown,

  /// Woolworths refused the cart call.
  cartRefused,

  /// The member's Woolies Dash cart has no delivery address, so it has no
  /// store to price or range anything at.
  noDeliveryAddress,
}

final class WoolworthsFailure extends AppFailure {
  const WoolworthsFailure(this.problem);

  final WoolworthsProblem problem;
}
