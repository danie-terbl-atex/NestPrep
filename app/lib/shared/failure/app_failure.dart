import '../../features/subscriptions/model/premium_feature.dart';

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

/// Why a sign-in, a registration or a password reset did not happen. Kept apart
/// from the Firestore failures because the person can act on most of these, and
/// because `cancelled` is not a failure at all — it is what backing out of the
/// Google sheet looks like.
///
/// One enum covers all three because registering is signing in for the first
/// time and a reset is how somebody gets back to signing in; splitting them
/// would mean three copies of `networkUnavailable` (accounts ADR-0002).
enum SignInProblem {
  /// The person closed the Google sheet. Say nothing.
  cancelled,

  /// Google signed the person in but handed back no ID token to give Firebase.
  noGoogleToken,

  /// The device could not reach Google or Firebase.
  networkUnavailable,

  /// The email or password is not what was typed. Firebase's email-enumeration
  /// protection is on, so `wrong-password` and `user-not-found` are
  /// indistinguishable here on purpose — telling somebody which half was wrong
  /// tells a stranger which addresses have accounts (accounts ADR-0002).
  wrongCredentials,

  /// Registering an address that already has an account. Not fatal: the way
  /// out is the other button, or a reset.
  emailAlreadyRegistered,

  /// The password is shorter or simpler than the project's policy allows.
  weakPassword,

  /// Firebase is rate-limiting this address or device after repeated attempts.
  /// Waiting is the only cure, so the copy says so rather than inviting a retry.
  tooManyAttempts,

  /// This address already has an account under the *other* provider. The person
  /// signs in the way they did last time, and the new credential is linked onto
  /// that uid rather than forking a second one (accounts ADR-0002).
  needsLinking,

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

  /// Creating or joining a household with an address nobody has proved. Only a
  /// password account can be in this state — a Google credential arrives
  /// verified (accounts ADR-0002).
  emailNotVerified,

  /// A kid device asked for something only an adult's account may do. The kid
  /// app never offers one, so this is the server refusing what the screen
  /// already does not show (accounts ADR-0003).
  kidAccount,

  /// A grant asked for on a parent or an admin, who already see everything
  /// (household ADR-0003).
  familyHasFullAccess,

  /// The app sent something the Function would not accept — our bug.
  badRequest,

  /// A refusal this build does not know: a Function deployed after it.
  unrecognised,
}

final class HouseholdFailure extends AppFailure {
  const HouseholdFailure(this.problem);

  final HouseholdProblem problem;
}

/// Why this device is not reporting where it is. Kept apart from the Firestore
/// failures because none of these is the backend saying no — every one of them
/// is something the person holding the phone decided, or can undo, and nobody
/// else in the household can answer for them (live-location ADR-0002).
enum LocationProblem {
  /// Asked, and refused this time. Asking again is allowed.
  permissionRefused,

  /// Refused in a way only the settings screen can undo.
  permissionRefusedForever,

  /// Location is switched off on the device itself, for every app.
  switchedOff,

  /// A share that had started stopped producing positions.
  reportingStopped,
}

final class LocationFailure extends AppFailure {
  const LocationFailure(this.problem);

  final LocationProblem problem;
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

  /// A personal vault nobody shared with this person (documents ADR-0002).
  vaultNotShared,

  /// The document was deleted while somebody was opening it.
  documentNotFound,

  /// The scanner could not start or finish on this phone.
  scanFailed,

  /// The person refused the camera, which the scanner needs.
  cameraRefused,

  /// The bytes arrived but are not a PDF or picture the app can draw.
  cannotRender,

  // ---- documents V2: shared links and offline copies (documents ADR-0006,
  // ADR-0007). The first five are reasons `createDocumentShare` and
  // `revokeDocumentShare` give; the last three are the phone's own.

  /// The capability is switched off (foundation ADR-0014).
  featureOff,

  /// Only the family, or a vault's owner, sends a document outside the
  /// household.
  notAllowedToShare,

  /// The shift a link was to end with has already ended.
  shiftNotOpen,

  /// The household already has as many live links as it may.
  tooManyShares,

  /// The link was removed while somebody was stopping it.
  shareNotFound,

  /// This phone already keeps as many offline copies as it may.
  offlineLimitReached,

  /// An offline copy could not be read back — changed on disk, or its key
  /// is gone. It is removed rather than shown.
  offlineCopyUnreadable,

  /// This phone would not give NestPrep a safe place for its key.
  offlineStorageUnavailable,
}

final class DocumentFailure extends AppFailure {
  const DocumentFailure(this.problem);

  final DocumentProblem problem;
}

/// Why a kid sign-in did not happen, or stopped (accounts ADR-0003). Kept
/// apart from the household refusals because half of them are read by a child
/// holding a tablet, and they get words written for that person.
///
/// Every one but [deviceDisconnected] is a `reason` a kid sign-in callable
/// puts in its error's details; that one is the client's own, for a device
/// whose reads the rules have started refusing because a parent signed it out.
enum KidSignInProblem {
  /// The profile is claimed by somebody, or is not a child's.
  notEligible,

  /// The profile already has as many devices as it may.
  tooManyDevices,

  /// The code typed is not a live code — mistyped, already used, or retired.
  codeNotFound,

  /// The code was right and has run out.
  codeExpired,

  /// A parent tried to sign out a device that is already signed out.
  deviceNotFound,

  /// The server cannot mint a sign-in right now. Ours, not the child's.
  signInUnavailable,

  /// A parent signed this device out, or removed the profile it was.
  deviceDisconnected,
}

final class KidSignInFailure extends AppFailure {
  const KidSignInFailure(this.problem);

  final KidSignInProblem problem;
}

/// Why a connected-calendar action did not happen (calendar ADR-0003). The
/// server's `CALENDAR_SYNC_REFUSALS` is the other half, and a test reads both.
/// Membership refusals stay `HouseholdProblem`, as they do for documents.
enum CalendarSyncProblem {
  /// The household's `calendar` grant does not reach this far — a helper who
  /// may look at the week asked to connect a calendar (household ADR-0003).
  calendarNotShared,

  /// Only the person who connected it, or an admin, may sync or remove it.
  notYourConnection,

  /// It was disconnected while somebody was looking at it.
  connectionNotFound,

  /// Google or Outlook is not set up on this deployment yet.
  providerNotConfigured,

  /// What was pasted is not a calendar link NestPrep can read.
  notACalendarLink,

  /// The link could not be reached just now.
  calendarLinkUnreachable,

  /// Nothing on the phone would open the provider's sign-in page.
  couldNotOpenBrowser,
}

final class CalendarSyncFailure extends AppFailure {
  const CalendarSyncFailure(this.problem);

  final CalendarSyncProblem problem;
}

// ---- todos phase 2: chores that earn kids stars (todos ADR-0003) ----

/// Why a parent's review of a chore or a reward did not happen. Each is a
/// `reason` `reviewChore` or `settleReward` put in its error's details;
/// "you are not in this household" stays the household's word for it.
enum PointsProblem {
  /// A helper, a carer or a claimed kid asked: stars are family's to give.
  notFamily,

  /// The chore is no longer waiting — it was unticked, or never needed a look.
  claimNotFound,

  /// The request is gone.
  requestNotFound,

  /// Somebody else already approved, sent back, handed over or declined it.
  alreadySettled,
}

final class PointsFailure extends AppFailure {
  const PointsFailure(this.problem);

  final PointsProblem problem;
}

// ---- home-care (home-care ADR-0001, ADR-0003) ----

/// Why a cleaning job's photo or hand-in did not happen (home-care
/// ADR-0001, ADR-0003) — each one something the person holding the phone can
/// act on. Refusals by the rules stay `PermissionDeniedFailure`.
enum HomeCareProblem {
  /// The person refused the camera, or the photo library.
  cameraRefused,

  /// The picture chosen is not one the app can read.
  photoUnreadable,

  /// Even compressed, the photo is past what the rules keep.
  photoTooLarge,

  /// A job handed in with a step not ticked. The rules refuse it too; this
  /// is the same answer before the upload rather than after.
  stepsNotDone,
}

final class HomeCareFailure extends AppFailure {
  const HomeCareFailure(this.problem);

  final HomeCareProblem problem;
}

// ---- lunch-box (lunch-box ADR-0001) ----

/// Why a lunch box change did not happen. The rules are what refuse an
/// unsafe box; the app checks first so the person hears why, in words about
/// the child rather than about permissions.
enum LunchProblem {
  /// Something in it is not safe for this child — an allergen, or a nut when
  /// nuts are ruled out for them. Caught before anything is written.
  unsafeForChild,

  /// The rules refused a box change the app thought was safe: the child's
  /// rules most likely changed on another phone a moment ago.
  refusedByRules,

  /// A child already has as many go-to boxes as they may keep.
  tooManyFavourites,

  /// A go-to box's name is longer than the rules keep.
  nameTooLong,
}

final class LunchFailure extends AppFailure {
  const LunchFailure(this.problem);

  final LunchProblem problem;
}

// ---- subscriptions (subscriptions ADR-0001) ----

/// Why buying or restoring premium did not happen. The server's
/// `SUBSCRIPTION_REFUSALS` is the other half, and a test reads both;
/// membership refusals stay `HouseholdProblem`. The last four are the phone's
/// own, never a Function's.
enum SubscriptionProblem {
  /// A kid, helper or carer asked to buy. Family pays.
  onlyFamilyCanBuy,

  /// No store products are configured yet: premium is not on sale.
  premiumUnavailable,

  /// The store's own server could not be asked. The purchase is kept on the
  /// phone and verified again later — nothing is lost.
  storeUnreachable,

  /// What the store handed over did not verify.
  purchaseNotValid,

  /// That store subscription is already another household's premium.
  purchaseInUseElsewhere,

  /// This phone has no store to buy through — an emulator without Play, a
  /// region without billing.
  storeNotAvailable,

  /// The store does not know the products yet (not created, or not live).
  productsNotFound,

  /// The store could not take the payment. Its own words are never shown.
  purchaseFailed,

  /// Restoring found nothing this store account bought.
  nothingToRestore,
}

final class SubscriptionFailure extends AppFailure {
  const SubscriptionFailure(this.problem);

  final SubscriptionProblem problem;
}

/// The free tier's limit, reached — a second child on a free household. Not
/// an error to apologise for: the screen that meets it offers premium, opened
/// on [feature].
final class PremiumRequiredFailure extends AppFailure {
  const PremiumRequiredFailure(this.feature);

  final PremiumFeature feature;
}

// ---- referrals: give a month, get a month (subscriptions ADR-0002) ----

/// Why sharing or entering a referral code did not happen. The server's
/// `REFERRAL_REFUSALS` is the other half, and `referral_contract_test.dart`
/// reads both; membership refusals stay `HouseholdProblem`.
enum ReferralProblem {
  /// Switched off in `appConfig/flags` (foundation ADR-0014).
  referralsOff,

  /// A helper, carer or kid asked. Referring is the family's.
  onlyFamilyCanRefer,
  referralCodeNotFound,

  /// The household's own code, or one from a household somebody here is in.
  ownReferralCode,
  alreadyRedeemed,

  /// A code is entered in the household's first seven days.
  tooLateToRedeem,
  tooManyRedemptions,
}

final class ReferralFailure extends AppFailure {
  const ReferralFailure(this.problem);

  final ReferralProblem problem;
}

/// Anything not recognised. The cause is kept for logging, never for display.
final class UnknownFailure extends AppFailure {
  const UnknownFailure(this.cause);

  final Object cause;
}

// ---- nanny hub (nanny-hub ADR-0002, ADR-0003) ----

/// Why something in the nanny hub did not happen. The first four are a
/// `reason` `endNannyShift` puts in its error's details — the server's
/// `NANNY_REFUSALS` is the other half, and a test reads both. The rest are the
/// phone's own: a photo that could not be taken or read, a call that nothing
/// on the phone would place. Membership refusals stay `HouseholdProblem`.
enum NannyHubProblem {
  /// The household's `nannyHub` grant is not `edit` for this person.
  hubNotShared,

  /// The shift was never there, or is gone.
  shiftNotFound,

  /// Somebody else ended the shift a moment ago.
  shiftAlreadyEnded,

  /// A carer ends their own shift; this one is somebody else's.
  notYourShift,

  /// The picked photo is not a picture the app can read.
  photoUnreadable,

  /// Even compressed, the photo is past what the rules keep.
  photoTooLarge,

  /// The camera or the photo library would not open.
  cameraUnavailable,

  /// Nothing on the phone would place the call.
  cannotCall,

  /// Only a carer can be kept to their booked shifts (nanny-hub ADR-0006).
  notACarer,

  /// The phone would not keep the hub's photos for offline — out of space,
  /// or its own folder refused (nanny-hub ADR-0007).
  cannotSaveOffline,

  /// A house code is only shown while a shift the viewer is booked on is
  /// open (nanny-hub ADR-0006).
  codesClosed,
}

final class NannyHubFailure extends AppFailure {
  const NannyHubFailure(this.problem);

  final NannyHubProblem problem;
}

// ---- AI, shared by every AI feature (foundation ADR-0015) ----

/// Why an AI call did not happen. Each is a `reason` the server's
/// `AI_REFUSALS` puts in its error's details, and
/// `calendar_v2_contract_test.dart` reads both. Plan-my-week and every later
/// AI feature reuse these.
enum AiProblem {
  /// The AI kill switch, or this feature's own switch, is off.
  aiSwitchedOff,

  /// The household has used this month's AI calls.
  aiLimitReached,

  /// The model could not be reached, or kept failing.
  aiUnavailable,

  /// The model answered, twice, in a shape that could not be read.
  aiUnreadable,

  /// The model declined the content.
  aiDeclined,
}

final class AiFailure extends AppFailure {
  const AiFailure(this.problem);

  final AiProblem problem;
}

// ---- calendar V2: snap a school letter (calendar ADR-0005) ----

/// Why a school letter could not be read or its events added. The first
/// three are the server's `SCHOOL_LETTER_REFUSALS`; the rest are the phone's.
enum SchoolLetterProblem {
  /// The `snapSchoolLetter` switch is off.
  letterFeatureOff,

  /// Past the size a letter needs to be.
  letterTooLarge,

  /// Not a photo or a PDF, whatever it claimed.
  letterNotSupported,

  /// The camera, the photo library or the file picker would not open.
  pickerUnavailable,

  /// Some of the ticked events could not be added; the rest were.
  someNotAdded,
}

final class SchoolLetterFailure extends AppFailure {
  const SchoolLetterFailure(this.problem);

  final SchoolLetterProblem problem;
}

// ---- calendar V2: the mental-load split view (calendar ADR-0006) ----

/// Why a week's card could not be shared. Both are the phone's own.
enum MentalLoadProblem {
  /// The card could not be turned into a picture.
  cardUnreadable,

  /// The share sheet would not open.
  shareUnavailable,
}

final class MentalLoadFailure extends AppFailure {
  const MentalLoadFailure(this.problem);

  final MentalLoadProblem problem;
}

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
