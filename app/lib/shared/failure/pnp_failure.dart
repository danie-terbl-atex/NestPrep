part of 'app_failure.dart';

// ---- Pick n Pay: the catalogue, the link and the cart (add-to-pnp ADR-0001) ----

/// Why a Pick n Pay catalogue read, link or push did not happen. The
/// catalogue problems are the phone's own; the rest are the `reason` a PnP
/// callable put in its details.
enum PnpProblem {
  /// Pick n Pay does not deliver to where the search looked.
  noStoreNearby,

  /// Pick n Pay asked us to slow down (HTTP 429).
  catalogueBusy,

  /// The catalogue could not be reached, or answered with an error.
  catalogueUnreachable,

  /// The catalogue answered in a shape this build does not understand.
  catalogueChanged,

  /// The `addToPnp` switch is off on the server.
  featureOff,

  /// A sign-in finished with no link started, or one that ran out.
  noPendingLink,

  /// Pick n Pay did not accept the sign-in, or it was not the one started.
  linkRefused,

  /// The member backed out of Pick n Pay's sign-in page.
  linkCancelled,

  /// The member's Pick n Pay link has run out, or never was.
  linkExpired,

  /// Pick n Pay itself is not answering the server.
  pnpDown,

  /// The member's Pick n Pay cart has no delivery address, so it has no
  /// store to price or range anything at.
  noDeliveryAddress,
}

final class PnpFailure extends AppFailure {
  const PnpFailure(this.problem);

  final PnpProblem problem;
}
