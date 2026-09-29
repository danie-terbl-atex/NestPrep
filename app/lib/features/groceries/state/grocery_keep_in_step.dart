import 'dart:async';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../model/grocery_plan_changes.dart';

/// Applies what keep-in-step asks for, once per distinct change, without ever
/// looping (groceries ADR-0002).
///
/// Three things make an automatic writer dangerous, and this is where each is
/// handled:
///
/// - **A write in flight.** Offline, a batch never completes until the network
///   is back, but the cache already shows it; the same change is not sent
///   twice while it is pending.
/// - **A refusal.** The cache rolls a refused write back, the next emission
///   asks for the same change again, and a naive writer sends it for ever. A
///   change refused once is not retried; if the plans still ask for exactly it
///   on the next emission, the refusal is reported and it stops.
/// - **A race.** Two phones keeping the same list in step can both write the
///   same new item; the second is refused because the first got there. That
///   one clears itself — the next emission shows the item — so a first refusal
///   is logged and not shown to anybody.
final class GroceryKeepInStep {
  GroceryKeepInStep({required this._write, required this._report});

  final Future<void> Function(GroceryPlanChanges changes) _write;
  final void Function(AppFailure failure) _report;

  final _inFlight = <String>{};
  String? _refused;
  AppFailure? _refusal;

  /// Called on every emission with what the plans would change now.
  void consider(GroceryPlanChanges changes) {
    final signature = signatureOf(changes);
    if (changes.isEmpty) {
      _forgetRefusal();
      return;
    }
    if (_inFlight.contains(signature)) return;
    if (signature == _refused) {
      final refusal = _refusal;
      _forgetRefusal();
      // Asked for twice and refused twice: not a race. Say so, and stop until
      // something about the plans or the list changes.
      if (refusal != null) _report(refusal);
      _refused = signature;
      return;
    }
    _forgetRefusal();
    unawaited(_send(signature, changes));
  }

  Future<void> _send(String signature, GroceryPlanChanges changes) async {
    _inFlight.add(signature);
    try {
      await _write(changes);
    } on AppFailure catch (failure) {
      AppLog.failure(
        'keep the list in step',
        code: failure.runtimeType.toString(),
      );
      _refused = signature;
      _refusal = failure;
    } finally {
      _inFlight.remove(signature);
    }
  }

  void _forgetRefusal() {
    _refused = null;
    _refusal = null;
  }

  /// Which items a change touches and how — two passes asking for the same
  /// writes have the same signature.
  static String signatureOf(GroceryPlanChanges changes) => [
    for (final create in changes.creates)
      '+${create.id}|${create.quantity}|${create.note}',
    for (final refresh in changes.refreshes)
      '~${refresh.itemId}|${refresh.quantity}|${refresh.note}',
    for (final removal in changes.removals) '-$removal',
  ].join('\n');
}
