import '../../add_to_checkers/data/cart_pusher.dart';
import '../../add_to_checkers/model/cart_push_result.dart';
import '../model/woolworths_link_status.dart';
import '../model/woolworths_sign_in.dart';

/// The five Woolworths callables (add-to-woolworths ADR-0001). The phone
/// signs in to Woolworths itself and hands over only the refresh token; the
/// member's session lives on the server from then on. Each refusal arrives
/// as an `AppFailure` (`BE-04`).
abstract interface class WoolworthsDirectory implements CartPusher {
  Future<WoolworthsLinkStatus> linkStatus();

  /// Where the phone signs in.
  Future<WoolworthsCognito> startLink();

  Future<WoolworthsLinkStatus> completeLink({required String refreshToken});

  /// Puts the Woolworths-matched, unbought items among [itemIds] into the
  /// member's Woolies Dash cart, each line raised to at least its
  /// [quantities].
  @override
  Future<CartPushResult> pushToCart({
    required String householdId,
    required List<String> itemIds,
    Map<String, int> quantities = const {},
  });

  Future<void> unlink();
}
