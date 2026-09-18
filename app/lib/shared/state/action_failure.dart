import 'package:flutter/foundation.dart';

import '../failure/app_failure.dart';

/// The last action that was refused, and the one way to run one.
///
/// Five controllers carried a byte-identical `dismissActionFailure`, and four
/// of them a byte-identical `_run`. That is `ENG-01`'s "two of anything is a
/// bug waiting for one of them to be fixed" — five times over. A change to how
/// a refusal is held, or a decision to log one, would have had to be made in
/// five places and would have been made in one.
///
/// This is deliberately *only* the shared part. `HouseholdController` guards
/// against a second action while one is in flight and answers whether the
/// action succeeded; it keeps its own runner and uses `recordFailure` from
/// here. `HouseholdGateController` is a different shape again — one screen,
/// one attempt — and shares nothing but the idea.
mixin ActionFailureHolder on ChangeNotifier {
  AppFailure? _actionFailure;

  /// What the last action was refused with, for the screen to turn into copy
  /// (`FE-09`). Null once it has been seen.
  AppFailure? get actionFailure => _actionFailure;

  void dismissActionFailure() {
    if (_actionFailure == null) return;
    _actionFailure = null;
    notifyListeners();
  }

  /// Runs an action, and keeps its refusal instead of throwing it at the
  /// screen. Anything that is not an `AppFailure` is a bug rather than a
  /// refusal, and is left to reach the zone and the crash report.
  @protected
  Future<void> runAction(Future<void> Function() action) async {
    _actionFailure = null;
    try {
      await action();
    } on AppFailure catch (failure) {
      recordFailure(failure);
    }
  }

  /// For a controller whose runner has more to do — see `HouseholdController`,
  /// which also has an in-flight guard and a result to report.
  @protected
  void recordFailure(AppFailure? failure) {
    _actionFailure = failure;
    notifyListeners();
  }

  /// Clears the held refusal without telling anybody, for a runner that is
  /// about to notify for its own reasons.
  @protected
  void clearFailureQuietly() => _actionFailure = null;
}
