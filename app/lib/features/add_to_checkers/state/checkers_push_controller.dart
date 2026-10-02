import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../data/checkers_directory.dart';
import '../model/checkers_push_state.dart';

/// *Add to Checkers* from the grocery list: one push at a time into the
/// member's own Sixty60 cart (the Checkers build contract).
///
/// The server decides what goes in — it reads the items itself and trusts
/// nothing the phone says about products (`BE-03`); the phone only names the
/// items. When the link has run out the state says so, the screen sends the
/// member to link again, and [retry] pushes the same items once they have.
final class CheckersPushController extends ChangeNotifier {
  CheckersPushController({
    required CheckersDirectory directory,
    required this.householdId,
  }) : _checkers = directory;

  final CheckersDirectory _checkers;
  final String householdId;

  CheckersPushState _state = const CheckersPushIdle();
  List<String> _itemIds = const [];
  var _isDisposed = false;

  CheckersPushState get state => _state;

  bool get isPushing => _state is CheckersPushing;

  Future<void> push(List<String> itemIds) async {
    if (isPushing || itemIds.isEmpty) return;
    _itemIds = List.unmodifiable(itemIds);
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
    _state = const CheckersPushIdle();
    notifyListeners();
  }

  Future<void> _push() async {
    _set(const CheckersPushing());
    try {
      final result = await _checkers.pushToCart(
        householdId: householdId,
        itemIds: _itemIds,
      );
      _set(CheckersPushed(result));
    } on AppFailure catch (failure) {
      _set(switch (failure) {
        CheckersFailure(problem: CheckersProblem.linkExpired) =>
          const CheckersPushNeedsLink(),
        _ => CheckersPushFailed(failure),
      });
    }
  }

  void _set(CheckersPushState state) {
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
