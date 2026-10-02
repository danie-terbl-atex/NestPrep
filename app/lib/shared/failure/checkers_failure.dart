part of 'app_failure.dart';

// ---- product matches and Add to Checkers (the Checkers build contract) ----

/// Why a Checkers product search, link or push did not happen. The catalogue
/// problems are the phone's own; the rest are the `reason` a Checkers
/// callable put in its details.
enum CheckersProblem {
  /// No Sixty60 store delivers to where the search looked.
  noStoreNearby,

  /// Checkers asked us to slow down (HTTP 429).
  catalogueBusy,

  /// The catalogue could not be reached, or answered with an error.
  catalogueUnreachable,

  /// The catalogue answered in a shape this build does not understand.
  catalogueChanged,

  /// The mobile number is not a South African one.
  badMobile,

  /// Too many codes asked for in a short time.
  otpRateLimited,

  /// Checkers itself is not answering the server.
  checkersDown,

  /// A code was entered with no code sent — it expired, or was never asked
  /// for.
  noPendingOtp,

  /// The code typed is not the one Checkers sent.
  wrongCode,

  /// The member's Checkers session has run out (it lasts an hour), or they
  /// never linked. Linking again is the way on.
  linkExpired,

  /// No Sixty60 store delivers to the address on the member's own Checkers
  /// account, so nothing can go into its cart.
  noStoreForAccount,

  /// The `addToCheckers` switch is off on the server.
  featureOff,
}

final class CheckersFailure extends AppFailure {
  const CheckersFailure(this.problem);

  final CheckersProblem problem;
}
