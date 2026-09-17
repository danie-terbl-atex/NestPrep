import '../failure/app_failure.dart';

/// Every user-facing string in the app (`FE-19`). Screens read from here and
/// nowhere else, so tone stays in one place and translation is later work.
abstract final class AppCopy {
  static const appName = 'NestPrep';

  static const loading = 'Loading';
  static const retry = 'Try again';
  static const back = 'Back';

  static const signInTagline = 'One household, one app.';
  static const signInWithGoogle = 'Continue with Google';
  static const signInEmulatorHint = 'Emulator build — sign in as a seeded user';
  static const signOut = 'Sign out';
  static const account = 'Account';
  static const sessionStarting = 'Getting things ready';

  static const householdGateTitle = 'Start a household';
  static const householdGateBody =
      'Make a home for your family\'s week, or join one you were invited to.';
  static const householdCreate = 'Create a household';
  static const householdCreateAction = 'Create';
  static const householdJoin = 'I have an invite code';
  static const householdJoinAction = 'Join';
  static const householdNameLabel = 'Household name';
  static const householdNameHint = 'The Parkers';
  static const myNameLabel = 'What should we call you?';
  static const inviteCodeLabel = 'Invite code';
  static const inviteCodeHint = 'ABCD2345';
  static const householdTitle = 'Household';
  static const householdMembers = 'Members';
  static const householdAddMember = 'Add a person';
  static const householdEditMember = 'Edit person';
  static const householdMemberName = 'Name';
  static const householdMemberColour = 'Colour';
  static const householdMemberRole = 'Role';
  static const householdInvite = 'Invite';
  static const householdInviteTitle = 'Invite code';
  static const householdInviteBody =
      'Share this code. It works once and expires in seven days.';
  static const householdCopyCode = 'Copy code';
  static const householdCodeCopied = 'Code copied';
  static const householdRemove = 'Remove';
  static const householdRemoveConfirm = 'Remove from household?';
  static const householdLeave = 'Leave household';
  static const householdLeaveConfirm = 'Leave this household?';
  static const householdSwitch = 'Switch household';
  static const householdUnclaimed = 'Has not joined yet';
  static const householdYou = 'You';
  static const householdEmptyTitle = 'No one here yet';
  static const householdEmptyBody = 'Add the people who live here.';
  static const householdSave = 'Save';
  static const householdCancel = 'Cancel';
  static const householdTimeZoneLabel = 'Time zone';
  static const householdProblemLastAdmin =
      'You are the only admin. Make somebody else an admin before you leave.';
  static const householdMemberNameHint = 'Their name';

  static String roleName(String role) => switch (role) {
    'admin' => 'Admin',
    'helper' => 'Helper',
    _ => 'Member',
  };

  static const galleryTitle = 'Design kit';
  static const galleryToggleTheme = 'Switch light and dark';
  static const galleryControls = 'Controls';
  static const gallerySurfaces = 'Surfaces';
  static const galleryStates = 'States';

  static String failure(AppFailure failure) => switch (failure) {
    PermissionDeniedFailure() => 'You are not allowed to do that.',
    UnavailableFailure() =>
      'NestPrep cannot reach the server right now. Check your connection.',
    NotFoundFailure() => 'That is no longer there.',
    SignInFailure(:final problem) => signInProblem(problem),
    HouseholdFailure(:final problem) => householdProblem(problem),
    UnknownFailure() => 'Something went wrong. Please try again.',
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
    HouseholdProblem.badRequest =>
      'NestPrep could not do that. Please try again.',
    HouseholdProblem.unrecognised => 'Something went wrong. Please try again.',
  };

  static String signInProblem(SignInProblem problem) => switch (problem) {
    SignInProblem.cancelled => 'Signing in was cancelled.',
    SignInProblem.noGoogleToken =>
      'Google did not finish signing you in. Please try again.',
    SignInProblem.networkUnavailable =>
      'NestPrep cannot reach Google right now. Check your connection.',
    SignInProblem.wrongCredentials => 'Those sign-in details are not right.',
    SignInProblem.accountDisabled =>
      'This account has been turned off. Ask whoever set it up.',
    SignInProblem.notConfigured =>
      'Sign-in is not set up on this build of NestPrep yet.',
    SignInProblem.unknown => 'Signing in did not work. Please try again.',
  };
}
