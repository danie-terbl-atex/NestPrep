import '../model/checkers_link_status.dart';
import '../model/checkers_push_result.dart';

/// The five Checkers callables (the Checkers build contract). The member's
/// Checkers session lives only on the server; the phone relays the mobile
/// number and the SMS code, and asks for a push. Each refusal arrives as an
/// `AppFailure` (`BE-04`).
abstract interface class CheckersDirectory {
  Future<CheckersLinkStatus> linkStatus();

  /// Asks Checkers to text a code to [mobile]. Answers the number masked.
  Future<String> requestOtp(String mobile);

  Future<CheckersLinkStatus> verifyOtp(String code);

  /// Puts the matched, unbought items among [itemIds] into the member's own
  /// Sixty60 cart. Cart only — never a slot, a checkout or a payment.
  Future<CheckersPushResult> pushToCart({
    required String householdId,
    required List<String> itemIds,
  });

  Future<void> unlink();
}
