import '../failure/app_failure.dart';
import 'app_copy.dart';
import 'calendar_sync_copy.dart';
import 'kid_copy.dart';
import 'points_copy.dart';
import 'subscription_copy.dart';

/// The words for every `AppFailure` (`FE-09`): a screen never shows an
/// error's own message, only one of these. Split from `AppCopy` when it
/// passed 500 lines (`ENG-05`); `AppCopy.failure` is still the one way in.
abstract final class FailureCopy {
  static String of(AppFailure failure) => switch (failure) {
    PermissionDeniedFailure() => 'You are not allowed to do that.',
    UnavailableFailure() =>
      'NestPrep cannot reach the server right now. Check your connection.',
    NotFoundFailure() => 'That is no longer there.',
    SessionExpiredFailure() =>
      'Your sign-in has expired. Please sign in again.',
    SignInFailure(:final problem) => signInProblem(problem),
    HouseholdFailure(:final problem) => householdProblem(problem),
    LocationFailure(:final problem) => locationProblem(problem),
    DocumentFailure(:final problem) => documentProblem(problem),
    KidSignInFailure(:final problem) => KidCopy.problem(problem),
    CalendarSyncFailure(:final problem) => CalendarSyncCopy.problem(problem),
    // todos phase 2 (todos ADR-0003).
    PointsFailure(:final problem) => PointsCopy.problem(problem),
    // nanny hub (nanny-hub ADR-0002).
    NannyHubFailure(:final problem) => NannyCopy.problem(problem),
    // home-care (home-care ADR-0001, ADR-0003).
    HomeCareFailure(:final problem) => HomeCareCopy.problem(problem),
    // lunch-box (lunch-box ADR-0001)
    LunchFailure(:final problem) => LunchCopy.problem(problem),
    // lunch-box V2 (lunch-box ADR-0006 to ADR-0008)
    LunchPlanningFailure(:final problem) => LunchPlanningCopy.problem(problem),
    // subscriptions (subscriptions ADR-0001)
    SubscriptionFailure(:final problem) => SubscriptionCopy.problem(problem),
    PremiumRequiredFailure(:final feature) => SubscriptionCopy.premiumRequired(
      feature,
    ),
    // AI and snap a school letter (foundation ADR-0015, calendar ADR-0005).
    AiFailure(:final problem) => AiCopy.problem(problem),
    SchoolLetterFailure(:final problem) => SchoolLetterCopy.problem(problem),
    MentalLoadFailure(:final problem) => MentalLoadCopy.problem(problem),
    // plan my week with AI (lunch-box ADR-0011).
    PlanWeekFailure(:final problem) => PlanWeekCopy.problem(problem),
    // co-parenting (household ADR-0004).
    CoParentFailure(:final problem) => TwoHomesCopy.problem(problem),
    // referrals (subscriptions ADR-0002)
    ReferralFailure(:final problem) => ReferralCopy.problem(problem),
    // account data (accounts ADR-0006).
    AccountDataFailure(:final problem) => AccountDataCopy.problem(problem),
    UnknownFailure() => 'Something went wrong. Please try again.',
  };

  static String documentProblem(DocumentProblem problem) => switch (problem) {
    DocumentProblem.folderNotFound => 'That folder is no longer there.',
    DocumentProblem.folderNotEmpty =>
      'Take everything out of this folder before you delete it.',
    DocumentProblem.fileTooLarge =>
      'That file is too big to keep here. Twenty megabytes is the most.',
    DocumentProblem.unsupportedType =>
      'NestPrep keeps PDFs and photos. That one is neither.',
    DocumentProblem.uploadCancelled => 'That file was not added.',
    DocumentProblem.cannotOpen =>
      'Nothing on this phone offered to open that file.',
    DocumentProblem.vaultNotShared =>
      'That vault has not been shared with you. Ask its owner or a parent.',
    DocumentProblem.documentNotFound => 'That document is no longer there.',
    DocumentProblem.scanFailed =>
      'The scanner did not work on this phone. Try again, or choose a file.',
    DocumentProblem.cameraRefused =>
      'NestPrep needs the camera to scan. Allow it in your phone settings.',
    DocumentProblem.cannotRender =>
      'NestPrep cannot show this file. It may be damaged.',
    DocumentProblem.featureOff ||
    DocumentProblem.notAllowedToShare ||
    DocumentProblem.shiftNotOpen ||
    DocumentProblem.tooManyShares ||
    DocumentProblem.shareNotFound => ShareLinkCopy.problem(problem),
    DocumentProblem.offlineLimitReached ||
    DocumentProblem.offlineCopyUnreadable ||
    DocumentProblem.offlineStorageUnavailable => OfflineCopiesCopy.problem(
      problem,
    ),
  };

  static String householdProblem(HouseholdProblem problem) => switch (problem) {
    HouseholdProblem.notSignedIn => 'Sign in again to do that.',
    HouseholdProblem.notAMember => 'You are not in this household any more.',
    HouseholdProblem.notAnAdmin => 'Only an admin can do that.',
    HouseholdProblem.householdNotFound => 'That household no longer exists.',
    HouseholdProblem.memberNotFound =>
      'That person is no longer in the household.',
    HouseholdProblem.inviteNotFound =>
      'That code is not one of ours. Check it and try again.',
    HouseholdProblem.inviteExpired =>
      'That code has expired. Ask for a new one.',
    HouseholdProblem.inviteAlreadyUsed => 'That code has already been used.',
    HouseholdProblem.memberAlreadyClaimed =>
      'Somebody has already joined as that person.',
    HouseholdProblem.alreadyInHousehold => 'You are already in that household.',
    HouseholdProblem.lastAdmin =>
      'A household needs an admin. Make somebody else an admin first.',
    HouseholdProblem.cannotRemoveSelf =>
      'To leave the household, use Leave household.',
    HouseholdProblem.emailNotVerified =>
      'Confirm your email address first — check your inbox for the link.',
    HouseholdProblem.kidAccount =>
      'That needs a grown-up\u2019s account, not a kid sign-in.',
    HouseholdProblem.familyHasFullAccess =>
      'Parents already see everything, so there is nothing to choose.',
    HouseholdProblem.badRequest =>
      'NestPrep could not do that. Please try again.',
    HouseholdProblem.unrecognised => 'Something went wrong. Please try again.',
  };

  static String locationProblem(LocationProblem problem) => switch (problem) {
    LocationProblem.permissionRefused =>
      'NestPrep needs your permission to share where you are.',
    LocationProblem.permissionRefusedForever =>
      'Location is turned off for NestPrep. Turn it on in your phone settings '
          'to share where you are.',
    LocationProblem.switchedOff =>
      'Location is switched off on this phone. Switch it on to share where '
          'you are.',
    LocationProblem.reportingStopped =>
      'Sharing stopped, because this phone stopped saying where it is.',
  };

  static String signInProblem(SignInProblem problem) => switch (problem) {
    SignInProblem.cancelled => 'Signing in was cancelled.',
    SignInProblem.noGoogleToken =>
      'Google did not finish signing you in. Please try again.',
    SignInProblem.networkUnavailable =>
      'NestPrep cannot reach Google right now. Check your connection.',
    SignInProblem.wrongCredentials => 'Those sign-in details are not right.',
    SignInProblem.emailAlreadyRegistered =>
      'That address already has an account. Try signing in instead.',
    SignInProblem.weakPassword =>
      'That password is too easy to guess. Use at least 8 characters.',
    SignInProblem.tooManyAttempts =>
      'Too many tries. Wait a few minutes and try again.',
    SignInProblem.needsLinking =>
      'You already have an account for that address. Sign in the way you did '
          'last time and we will join the two together.',
    SignInProblem.accountDisabled =>
      'This account has been turned off. Ask whoever set it up.',
    SignInProblem.notConfigured =>
      'Sign-in is not set up on this build of NestPrep yet.',
    SignInProblem.unknown => 'Signing in did not work. Please try again.',
  };
}
