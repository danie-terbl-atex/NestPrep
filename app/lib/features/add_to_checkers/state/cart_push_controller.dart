import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../data/cart_pusher.dart';
import '../model/cart_push_state.dart';

/// One push at a time into the member's own cart at one shop: *Add to
/// Checkers* from the grocery list (the Checkers build contract), *Add to my
/// Pick n Pay cart* from *Plan my week* (add-to-pnp ADR-0004).
///
/// The server decides what goes in — it reads the items itself and trusts
/// nothing the phone says about products (`BE-03`); the phone only names the
/// items. When the link has run out the state says so, the screen sends the
/// member to link again, and [retry] pushes the same items once they have.
final class CartPushController extends ChangeNotifier {
  CartPushController({required CartPusher directory, required this.householdId})
    : _shop = directory;

  final CartPusher _shop;
  final String householdId;

  CartPushState _state = const CartPushIdle();
  List<String> _itemIds = const [];
  Map<String, int> _quantities = const {};
  var _isDisposed = false;

  CartPushState get state => _state;

  bool get isPushing => _state is CartPushing;

  Future<void> push(
    List<String> itemIds, {
    Map<String, int> quantities = const {},
  }) async {
    if (isPushing || itemIds.isEmpty) return;
    _itemIds = List.unmodifiable(itemIds);
    _quantities = Map.unmodifiable(quantities);
    await _push();
  }

  /// Pushes the last items again — after linking, or after a failure.
  Future<void> retry() async {
    if (isPushing || _itemIds.isEmpty) return;
    await _push();
  }

  /// The sheet has closed; the next push starts clean.
  void reset() {
    if (isPushing) return;
    _state = const CartPushIdle();
    notifyListeners();
  }

  Future<void> _push() async {
    _set(const CartPushing());
    try {
      final result = await _shop.pushToCart(
        householdId: householdId,
        itemIds: _itemIds,
        quantities: _quantities,
      );
      _set(CartPushed(result));
    } on AppFailure catch (failure) {
      _set(
        _needsLink(failure)
            ? const CartPushNeedsLink()
            : CartPushFailed(failure),
      );
    }
  }

  static bool _needsLink(AppFailure failure) => switch (failure) {
    CheckersFailure(problem: CheckersProblem.linkExpired) ||
    PnpFailure(problem: PnpProblem.linkExpired) ||
    WoolworthsFailure(
      problem: WoolworthsProblem.linkExpired || WoolworthsProblem.notLinked,
    ) => true,
    _ => false,
  };

  void _set(CartPushState state) {
    if (_isDisposed) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
