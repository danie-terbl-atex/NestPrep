import 'dart:async';

import '../../../shared/log/best_effort.dart';
import '../../accounts/data/account_repository.dart';
import '../model/tour_version.dart';

/// Records on the account that this person has seen the welcome tour —
/// finishing and skipping alike — once per tour (welcome-tour ADR-0001).
final class TourSeenRecorder {
  TourSeenRecorder({
    required AccountRepository accountRepository,
    required this._signedInUid,
  }) : _accounts = accountRepository;

  final AccountRepository _accounts;

  /// The account the tour is recorded on, asked when it is recorded; empty
  /// when nobody is signed in, which the shell never lets reach here.
  final String Function() _signedInUid;

  /// Nobody waits on it: a write offline completes only when the connection
  /// is back (vault lesson on writes against an unreachable backend), and
  /// leaving the tour must not hang on that. A refusal is logged, never shown;
  /// what it costs is the tour once more next time.
  void markSeen() {
    final uid = _signedInUid();
    if (uid.isEmpty) return;
    unawaited(_record(uid));
  }

  /// Through `bestEffort`, which logs a refusal and never throws.
  Future<void> _record(String uid) => bestEffort(
    'welcome tour',
    code: 'mark seen',
    run: () => _accounts.markTourSeen(uid: uid, version: TourVersion.current),
  );
}
