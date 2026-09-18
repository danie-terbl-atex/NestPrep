/// Every failure that reaches a controller or a screen is one of these. Copy is
/// chosen from the case in `AppCopy`, never from the underlying error's message
/// (`FE-09`, `ENG-09`).
sealed class AppFailure implements Exception {
  const AppFailure();
}

/// The rules said no.
final class PermissionDeniedFailure extends AppFailure {
  const PermissionDeniedFailure();
}

/// The backend cannot be reached and the cache had no answer.
final class UnavailableFailure extends AppFailure {
  const UnavailableFailure();
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure();
}

/// The signed-in session is no longer one the backend accepts — the account was
/// deleted or disabled, or the token was issued by a backend that has since
/// been replaced. Nothing the person can do except sign in again, so the app
/// signs them out rather than showing a read that will never succeed.
final class SessionExpiredFailure extends AppFailure {
  const SessionExpiredFailure();
}

/// Why a sign-in did not happen. Kept apart from the Firestore failures because
/// the person can act on most of these, and because `cancelled` is not a
/// failure at all — it is what backing out of the Google sheet looks like.
enum SignInProblem {
  /// The person closed the Google sheet. Say nothing.
  cancelled,

  /// Google signed the person in but handed back no ID token to give Firebase.
  noGoogleToken,

  /// The device could not reach Google or Firebase.
  networkUnavailable,

  /// The seeded emulator user's email or password is not what was typed.
  wrongCredentials,

  /// The account exists and has been turned off.
  accountDisabled,

  /// This build is not configured for Google sign-in — an unregistered SHA-1,
  /// a missing client id, the provider not enabled on the project. The person
  /// cannot fix it; it is on us (accounts ADR-0001).
  notConfigured,

  unknown,
}

final class SignInFailure extends AppFailure {
  const SignInFailure(this.problem);

  final SignInProblem problem;

  /// Backing out of the Google sheet is a choice, not something to apologise
  /// for, so the screen shows nothing.
  bool get isWorthShowing => problem != SignInProblem.cancelled;
}

/// Why a household call refused. Each one is a `reason` a Cloud Function put in
/// its error's details, because the gRPC code alone cannot tell three kinds of
/// "already exists" apart (household ADR-0002, `BE-04`).
enum HouseholdProblem {
  notSignedIn,
  notAMember,
  notAnAdmin,
  householdNotFound,
  memberNotFound,
  inviteNotFound,
  inviteExpired,
  inviteAlreadyUsed,
  memberAlreadyClaimed,
  alreadyInHousehold,
  lastAdmin,
  cannotRemoveSelf,

  /// The app sent something the Function would not accept — our bug.
  badRequest,

  /// A refusal this build does not know: a Function deployed after it.
  unrecognised,
}

final class HouseholdFailure extends AppFailure {
  const HouseholdFailure(this.problem);

  final HouseholdProblem problem;
}

/// Why something about a document did not happen.
///
/// Only the refusals the household vocabulary has no word for. "You are not in
/// this household" and "only an admin can do that" are the same sentence
/// whichever callable said them, so those stay `HouseholdProblem` and this
/// enum does not repeat them (documents ADR-0001).
enum DocumentProblem {
  /// The folder was deleted while somebody was looking at it.
  folderNotFound,

  /// A folder is deleted only once it is empty, because rules cannot count
  /// what is in one and an orphaned document is bytes nobody can see.
  folderNotEmpty,

  /// Past the 20 MiB the rules allow. Refused before the upload starts, so
  /// nobody waits for it.
  fileTooLarge,

  /// Not one of the types a household keeps.
  unsupportedType,

  /// Somebody stopped the upload. Not a fault, but the screen still says what
  /// became of the file.
  uploadCancelled,

  /// The file left the app and no viewer on the device took it. The document
  /// is fine; the phone is the problem, and the person can say so.
  cannotOpen,
}

final class DocumentFailure extends AppFailure {
  const DocumentFailure(this.problem);

  final DocumentProblem problem;
}

/// Anything not recognised. The cause is kept for logging, never for display.
final class UnknownFailure extends AppFailure {
  const UnknownFailure(this.cause);

  final Object cause;
}
