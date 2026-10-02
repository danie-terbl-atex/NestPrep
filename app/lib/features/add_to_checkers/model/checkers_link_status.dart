import 'package:flutter/foundation.dart';

/// Whether the signed-in member's own Checkers account is linked, as
/// `checkersLinkStatus` answers it. The mobile number is masked by the server;
/// the phone never holds it whole after it is typed.
@immutable
final class CheckersLinkStatus {
  const CheckersLinkStatus({
    required this.isLinked,
    this.expiresAt,
    this.mobileMasked,
  });

  const CheckersLinkStatus.unlinked()
    : isLinked = false,
      expiresAt = null,
      mobileMasked = null;

  final bool isLinked;

  /// When Checkers' one-hour session runs out; there is no refresh.
  final DateTime? expiresAt;
  final String? mobileMasked;

  /// Linked and not yet run out at [now].
  bool isLiveAt(DateTime now) {
    final until = expiresAt;
    return isLinked && (until == null || until.isAfter(now));
  }
}
