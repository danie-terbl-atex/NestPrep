import '../../add_to_checkers/data/cart_pusher.dart';
import '../../add_to_checkers/model/cart_push_result.dart';
import '../model/pnp_link_status.dart';

/// The five Pick n Pay callables (add-to-pnp ADR-0003, ADR-0004). The
/// member's tokens live only on the server: the phone opens the sign-in page
/// the server names, relays the code it hands back, and asks for a push.
/// Each refusal arrives as an `AppFailure` (`BE-04`).
abstract interface class PnpDirectory implements CartPusher {
  Future<PnpLinkStatus> linkStatus();

  /// Starts a link: the Pick n Pay sign-in page to open.
  Future<Uri> startLink();

  /// Finishes the link with what the sign-in page handed back.
  Future<PnpLinkStatus> completeLink({
    required String code,
    required String state,
  });

  /// Puts the Pick n Pay-matched, unbought items among [itemIds] into the
  /// member's own cart, each line raised to at least its [quantities].
  @override
  Future<CartPushResult> pushToCart({
    required String householdId,
    required List<String> itemIds,
    Map<String, int> quantities = const {},
  });

  Future<void> unlink();
}
