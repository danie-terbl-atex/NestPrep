import '../model/cart_push_result.dart';
import '../model/checkers_link_status.dart';
import 'cart_pusher.dart';

/// The five Checkers callables (the Checkers build contract). The member's
/// Checkers session lives only on the server; the phone relays the mobile
/// number and the SMS code, and asks for a push. Each refusal arrives as an
/// `AppFailure` (`BE-04`).
abstract interface class CheckersDirectory implements CartPusher {
  Future<CheckersLinkStatus> linkStatus();

  /// Asks Checkers to text a code to [mobile]. Answers the number masked.
  Future<String> requestOtp(String mobile);

  Future<CheckersLinkStatus> verifyOtp(String code);

  /// Puts the matched, unbought items among [itemIds] into the member's own
  /// Sixty60 cart, one of each item. Cart only — never a slot, a checkout or
  /// a payment.
  @override
  Future<CartPushResult> pushToCart({
    required String householdId,
    required List<String> itemIds,
    Map<String, int> quantities = const {},
  });

  Future<void> unlink();
}
