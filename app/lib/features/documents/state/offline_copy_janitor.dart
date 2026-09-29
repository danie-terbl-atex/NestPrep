import 'dart:async';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../../shared/log/app_log.dart';
import '../../accounts/model/session.dart';
import '../../accounts/state/session_controller.dart';
import '../data/offline_copy_store.dart';

/// Deletes offline copies the moment the person holding them stops being
/// allowed them (documents ADR-0007) — app-wide, because signing out and
/// leaving a household happen outside Documents.
///
/// - **Signed out, or on a kid's tablet:** every copy and key on the phone.
/// - **Signed in:** every other account's copies and keys, then this
///   account's copies from households it no longer belongs to.
/// - **The switch turned off** — by the document, not by a release build's
///   default before it has answered: every copy on the phone.
///
/// It runs on every change, so a crash in the middle of a sign-out is
/// finished at the next launch. Revoked grants and deleted documents are the
/// offline screen's to notice, because only the server can say.
final class OfflineCopyJanitor {
  OfflineCopyJanitor({
    required this._store,
    required this._session,
    required this._flags,
  }) {
    _session.addListener(_sweep);
    _flags.addListener(_sweep);
    _sweep();
  }

  final OfflineCopyStore _store;
  final SessionController _session;
  final FeatureFlagsController _flags;
  Future<void> _running = Future.value();

  /// The last sweep, for a test to wait on.
  Future<void> get settled => _running;

  void _sweep() {
    final session = _session.session;
    // Only a switch the document has actually turned off deletes anything:
    // before it answers, a release build's default is off, and every launch
    // would otherwise sweep the phone clean.
    final isOn =
        !_flags.hasAnswered || _flags.isOn(FeatureFlag.documentOfflineCopies);
    // Switched off, nothing needs to be known about who is signed in.
    if (isOn && session is AsyncLoading<Session>) return;
    _running = _running.then((_) => _sweepFor(session, isOn: isOn));
  }

  Future<void> _sweepFor(
    AsyncState<Session> session, {
    required bool isOn,
  }) async {
    try {
      if (!isOn) {
        await _store.keepOnly(null);
        return;
      }
      switch (session) {
        case AsyncData(value: SignedIn(:final uid, :final account)):
          await _store.keepOnly(uid);
          final households = account.householdIds.toSet();
          final copies = await _store.list(uid);
          await _store.remove(uid, [
            for (final copy in copies)
              if (!households.contains(copy.householdId)) copy,
          ]);
        case AsyncData(value: SignedOut() || KidSignedIn()):
          await _store.keepOnly(null);
        case AsyncLoading() || AsyncFailure():
          return;
      }
    } on AppFailure catch (failure) {
      // Nobody is waiting on a sweep, and it runs again on the next change;
      // the keystore or the disk refusing is logged where it can be seen.
      AppLog.failure(
        'offline copies sweep',
        code: failure.runtimeType.toString(),
        error: failure,
      );
    }
  }

  void dispose() {
    _session.removeListener(_sweep);
    _flags.removeListener(_sweep);
  }
}
