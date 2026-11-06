import 'package:flutter/foundation.dart';

/// Whether the signed-in member's own Woolworths account is linked, as
/// `woolworthsLinkStatus` answers it. The tokens stay on the server; the
/// phone only hears yes or no, since when, and the account's email masked
/// (add-to-woolworths ADR-0001).
@immutable
final class WoolworthsLinkStatus {
  const WoolworthsLinkStatus({
    required this.isLinked,
    this.linkedAt,
    this.emailMasked,
  });

  const WoolworthsLinkStatus.unlinked()
    : isLinked = false,
      linkedAt = null,
      emailMasked = null;

  final bool isLinked;
  final DateTime? linkedAt;

  /// `d***@a***.io`: which account, without saying it.
  final String? emailMasked;
}
