part of 'app_failure.dart';

/// Why deleting an account or downloading its data did not happen (accounts
/// ADR-0006). Each but [downloadFailed] and [shareUnavailable] is a `reason` an account-data callable
/// puts in its error's details; "sign in first" and "a kid sign-in cannot do
/// that" stay the household's words.
enum AccountDataProblem {
  /// Somebody joined or left a household since the preview was read, so what
  /// deleting would do is no longer what the person agreed to.
  deletionPlanChanged,

  /// The typed confirmation did not match. The screen never sends one that
  /// does not, so this is the server guarding what the client already does.
  deletionNotConfirmed,

  /// Three exports in an hour already.
  tooManyRequests,

  /// The export was written but its file could not be fetched in time.
  downloadFailed,

  /// The phone's share sheet would not open for the finished export.
  shareUnavailable,
}

final class AccountDataFailure extends AppFailure {
  const AccountDataFailure(this.problem);

  final AccountDataProblem problem;
}
