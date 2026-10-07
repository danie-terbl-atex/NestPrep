import 'package:flutter/foundation.dart';

import '../../../shared/state/action_failure.dart';
import '../data/household_directory.dart';
import 'pending_invite.dart';

/// The invite a tapped link brought in (household ADR-0005): what it offers,
/// then joining or not. Either way the pending code is spent, and the router
/// moves the person on.
final class JoinInviteController extends ChangeNotifier
    with ActionFailureHolder {
  JoinInviteController({
    required HouseholdDirectory householdDirectory,
    required PendingInvite pendingInvite,
  }) : _directory = householdDirectory,
       _pending = pendingInvite;

  final HouseholdDirectory _directory;
  final PendingInvite _pending;

  InvitePreview? _preview;
  bool _isBusy = false;

  InvitePreview? get preview => _preview;
  bool get isBusy => _isBusy;

  Future<void> load() async {
    final code = _pending.code;
    if (code == null) return;
    await _busy(() async => _preview = await _directory.previewInvite(code));
  }

  Future<void> join() async {
    final preview = _preview;
    if (preview == null || _isBusy) return;
    await _busy(() async {
      await _directory.redeemInvite(preview.code);
      _pending.clear();
    });
  }

  void notNow() => _pending.clear();

  Future<void> _busy(Future<void> Function() action) async {
    _isBusy = true;
    notifyListeners();
    await runAction(action);
    _isBusy = false;
    notifyListeners();
  }
}
