/// A code a parent made for one kid profile, still waiting for a device
/// (accounts ADR-0003). Held only on the parent's screen while it is showing:
/// the code itself is never readable from Firestore, so closing the sheet is
/// the last anybody sees of it.
final class KidPairing {
  const KidPairing({
    required this.code,
    required this.memberId,
    required this.expiresAt,
  });

  final String code;
  final String memberId;

  /// When the code stops working, as a UTC instant (`ENG-21`).
  final DateTime expiresAt;

  /// How long is left at [now], never negative.
  Duration remainingAt(DateTime now) {
    final left = expiresAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  bool hasExpiredAt(DateTime now) => !now.isBefore(expiresAt);
}
