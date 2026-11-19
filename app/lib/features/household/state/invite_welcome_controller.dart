import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../data/household_directory.dart';
import 'pending_invite.dart';

/// The first step for somebody holding an invite before they have an account
/// (household ADR-0011): what the invite offers, or why it cannot be used.
///
/// The preview only decorates the way in. A refusal that says the invite is
/// dead stops it here, before an account is made for nothing; any other
/// failure — offline, rate limited, a Function not yet deployed — leaves the
/// way in open with general words.
final class InviteWelcomeController extends ChangeNotifier {
  InviteWelcomeController({
    required HouseholdDirectory householdDirectory,
    required PendingInvite pendingInvite,
  }) : _directory = householdDirectory,
       _pending = pendingInvite;

  static const _deadInvite = {
    HouseholdProblem.inviteNotFound,
    HouseholdProblem.inviteExpired,
    HouseholdProblem.inviteAlreadyUsed,
    HouseholdProblem.memberAlreadyClaimed,
    HouseholdProblem.householdNotFound,
    HouseholdProblem.memberNotFound,
  };

  final HouseholdDirectory _directory;
  final PendingInvite _pending;

  bool _isChecking = true;
  bool _isDisposed = false;
  InvitePreview? _preview;
  HouseholdProblem? _refusal;

  bool get isChecking => _isChecking;
  InvitePreview? get preview => _preview;
  HouseholdProblem? get refusal => _refusal;

  Future<void> load() async {
    final code = _pending.code;
    if (code != null) {
      try {
        _preview = await _directory.previewInvite(code);
      } on HouseholdFailure catch (failure) {
        if (_deadInvite.contains(failure.problem)) {
          _refusal = failure.problem;
        } else {
          AppLog.failure('invite preview', code: failure.problem.name);
        }
      } on AppFailure catch (failure) {
        AppLog.failure('invite preview', code: 'unreadable', error: failure);
      }
    }
    _isChecking = false;
    // The person may have tapped Not now while the preview was in flight.
    if (!_isDisposed) notifyListeners();
  }

  void notNow() => _pending.clear();

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
