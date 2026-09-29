part of 'app_failure.dart';

// ---- co-parenting: a child in two homes (household ADR-0004) ----

/// Why something between two homes did not happen. Each is a `reason` a
/// co-parenting callable puts in its error's details — the server's
/// `COPARENT_REFUSALS` is the other half, and a test reads both. "You are not
/// in this household" and "only an admin" stay the household's words.
enum CoParentProblem {
  notFamily,
  linkInviteNotFound,
  linkInviteExpired,
  linkInviteUsed,
  sameHousehold,
  childNotFound,
  childAlreadyLinked,
  linkNotFound,
  linkNotActive,
  notYourTurn,
  requestNotFound,
  requestAlreadyAnswered,
  tooManyRequests,
  dateOutOfRange,
}

final class CoParentFailure extends AppFailure {
  const CoParentFailure(this.problem);

  final CoParentProblem problem;
}
