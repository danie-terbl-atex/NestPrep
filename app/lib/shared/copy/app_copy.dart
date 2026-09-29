import '../../features/household/model/member_role.dart';
import '../failure/app_failure.dart';
import '../recurrence/recurrence_rule.dart';
import 'access_copy.dart';
import 'kid_copy.dart';
import 'product_analytics_copy.dart';

// Household phase 2's words live beside this file (household ADR-0003).
export 'access_copy.dart';

/// Every user-facing string in the app (`FE-19`). Screens read from here and
/// nowhere else, so tone stays in one place and translation is later work.
abstract final class AppCopy {
  static const appName = 'NestPrep';

  // product analytics — the Beta numbers screen (product-analytics ADR-0001)
  static const productAnalytics = ProductAnalyticsCopy();

  static const loading = 'Loading';
  static const retry = 'Try again';
  static const back = 'Back';

  static const signInTagline = 'One household, one app.';

  /// What the picture on the sign-in screen says, for somebody who cannot see
  /// it. The orbiting marks carry no semantics of their own, so this sentence
  /// is the whole of it.
  static const signInOrbitLabel =
      'A calendar, to-dos, meals and groceries, shared by one household.';

  /// The letters on the member marks circling the sign-in screen. They are an
  /// illustration's initials, not people — one string so they stay together
  /// and nobody mistakes them for names that need translating.
  static const signInOrbitInitials = 'AMJKS';

  static const signInWithGoogle = 'Continue with Google';
  static const signInEmulatorHint = 'Emulator build — sign in as a seeded user';

  // Signing in with an address and a password (accounts ADR-0002).
  static const signInOr = 'or';
  static const signInEmailLabel = 'Email';
  static const signInPasswordLabel = 'Password';
  static const signInWithEmail = 'Sign in';
  static const signInForgotPassword = 'Forgotten your password?';
  static const signInNoAccount = 'New here?';
  static const signInCreateAccount = 'Create an account';

  static const registerTitle = 'Create your account';
  static const registerNameLabel = 'Your name';
  static const registerNameHint = 'What the household will call you';
  static const registerPasswordHint = 'At least 8 characters';
  static const registerSubmit = 'Create account';
  static const registerHasAccount = 'Already have an account?';
  static const registerSignInInstead = 'Sign in';

  static const forgotPasswordTitle = 'Reset your password';
  static const forgotPasswordBlurb =
      'Type the address you signed up with and we will send you a link to set '
      'a new password.';
  static const forgotPasswordSubmit = 'Send the link';

  /// Said whether or not the address had an account. Confirming which addresses
  /// are registered is exactly what enumeration protection prevents
  /// (accounts ADR-0002).
  static const forgotPasswordSent =
      'If that address has a NestPrep account, the link is on its way. It is '
      'worth checking the spam folder.';

  static const verifyEmailTitle = 'Confirm your email';
  static const verifyEmailSubmit = 'I have confirmed it';
  static const verifyEmailResend = 'Send it again';
  static const verifyEmailResent = 'Sent. Check your inbox again.';
  static const verifyEmailStillWaiting =
      'That address is not confirmed yet. Open the link in the email first.';
  static const verifyEmailWrongAddress =
      'Wrong address? Sign out and start again.';

  static String verifyEmailBlurb(String email) =>
      'We sent a link to $email. Open it, then come back — a household holds '
      'your family\'s things, so we confirm the address before you join one.';
  static const signOut = 'Sign out';
  static const account = 'Account';
  static const sessionStarting = 'Getting things ready';

  static const tabWeek = 'Week';
  static const tabTodos = 'To do';
  static const tabGroceries = 'Groceries';
  static const tabMeals = 'Meals';

  static const groceriesTitle = 'Groceries';
  static const groceriesAddHint = 'Add an item';
  static const groceriesQuantityHint = 'How much? (optional)';
  static const groceriesAdd = 'Add';
  static const groceriesBought = 'Bought';
  static const groceriesToBuy = 'To buy';
  static const groceriesEmptyTitle = 'Nothing on the list';
  static const groceriesEmptyBody = 'Add the first thing you need.';
  static const groceriesUndo = 'Undo';
  static const groceriesEditItem = 'Edit item';
  static const groceriesOften = 'Often bought';

  static const todosTitle = 'To do';
  static const todosMine = 'Mine today';
  static const todosEveryone = 'Everyone';
  static const todosRoutines = 'Routines';
  static const todosAddTask = 'Add a task';
  static const todosEditTask = 'Edit task';
  static const todosAddRoutine = 'Add a routine';
  static const todosEditRoutine = 'Edit routine';
  static const todosTitleLabel = 'What needs doing?';
  static const todosNoteLabel = 'Note (optional)';
  static const todosDueLabel = 'Due';
  static const todosAssignLabel = 'For';
  static const todosRoutineLabel = 'Part of a routine';
  static const todosAnyone = 'Anyone';
  static const todosNoRoutine = 'On its own';
  static const todosOverdue = 'Overdue';
  static const todosToday = 'Today';
  static const todosMineEmptyTitle = 'Nothing for you today';
  static const todosMineEmptyBody = 'Enjoy it, or add something for later.';
  static const todosEveryoneEmptyTitle = 'Nothing planned';
  static const todosEveryoneEmptyBody = 'Add the first task for the household.';
  static const todosAllMembers = 'Everyone';
  static const todosRoutineNameLabel = 'Routine name';
  static const todosRoutineStartLabel = 'Starting';
  static const todosRoutineDefaultFor = 'Usually for';
  static const todosDoneFor = 'Done for';
  static const todosCompleteFor = 'Mark done for…';

  static const locationTitle = 'Where we are';
  static const locationYours = 'Your location';
  static const locationYoursBody =
      'Only you can start or stop this, and every share ends on its own.';
  static const locationShareFor = 'Share for';
  static const locationStop = 'Stop sharing';
  static const locationSharingUntil = 'Sharing until';
  static const locationFifteenMinutes = '15 minutes';
  static const locationOneHour = '1 hour';
  static const locationFourHours = '4 hours';
  static const locationHereNow = 'Here now';
  static const locationLastSeen = 'Last seen';
  static const locationNotSharing = 'Not sharing';
  static const locationAloneTitle = 'Nobody else here yet';
  static const locationAloneBody =
      'Add the people who live here, and this is where you will see who is out.';

  /// How far away somebody is, in the units a person would use for it.
  static String distanceAway(double metres) => metres < 1000
      ? '${metres.round()} m away'
      : '${(metres / 1000).toStringAsFixed(1)} km away';

  /// How sure the phone was. "Here now, within 12 m" and "here now, within
  /// 900 m" are different answers to the same question.
  static String withinMetres(int metres) => 'within $metres m';

  static const timeJustNow = 'Just now';

  static String minutesAgo(int minutes) =>
      minutes == 1 ? '1 minute ago' : '$minutes minutes ago';

  static String hoursAgo(int hours) =>
      hours == 1 ? '1 hour ago' : '$hours hours ago';

  static const dateToday = 'Today';
  static const dateTomorrow = 'Tomorrow';
  static const dateYesterday = 'Yesterday';

  static const repeatNever = 'Does not repeat';
  static const repeatDaily = 'Every day';
  static const repeatWeekly = 'Every week';
  static const repeatMonthly = 'Every month';
  static const repeatLabel = 'Repeats';
  static const repeatEveryLabel = 'Every';
  static const repeatOnDaysLabel = 'On';
  static const repeatUntilLabel = 'Until';
  static const repeatForever = 'No end date';

  static const weekdayNames = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static String weekdayName(int isoWeekday) =>
      weekdayNames[(isoWeekday - 1).clamp(0, 6)];

  /// How a repeating thing describes itself in one line.
  static String recurrenceSummary(RecurrenceRule? rule) {
    if (rule == null) return repeatNever;
    final every = rule.interval > 1
        ? '$repeatEveryLabel ${rule.interval} '
        : '';
    return switch (rule.frequency) {
      RecurrenceFrequency.daily =>
        rule.interval > 1 ? '${every}days' : repeatDaily,
      RecurrenceFrequency.weekly =>
        rule.weekdays.isEmpty
            ? (rule.interval > 1 ? '${every}weeks' : repeatWeekly)
            : rule.weekdays.map(weekdayName).join(', '),
      RecurrenceFrequency.monthly =>
        rule.interval > 1 ? '${every}months' : repeatMonthly,
    };
  }

  static const calendarTitle = 'Week';
  static const calendarAddEvent = 'Add an event';
  static const calendarEditEvent = 'Edit event';
  static const calendarThisWeek = 'This week';
  static const calendarPreviousWeek = 'Previous week';
  static const calendarNextWeek = 'Next week';
  static const calendarAllDay = 'All day';
  static const calendarStarts = 'Starts';
  static const calendarEnds = 'Ends';
  static const calendarForLabel = 'For';
  static const calendarEveryone = 'Everyone';
  static const calendarEmptyBody = 'Add the first event.';
  static const calendarDayEmpty = 'Nothing on';
  static const calendarSkip = 'Skip this one';
  static const calendarTitleLabel = 'What is happening?';
  static const calendarWeekFilter = 'Showing';

  /// A birthday is derived from a member's profile and cannot be changed from
  /// the calendar, so its row says where it comes from (birthdays ADR-0001).
  static const calendarBirthdayFromProfile = 'From the household';
  static const calendarBirthdayOpenProfile = 'Open the household';

  static String birthdayOf(String name) => '$name\u2019s birthday';

  static String birthdayTurning(String name, int age) => '$name turns $age';

  static const mealsTitle = 'Meals';
  static const mealsBreakfast = 'Breakfast';
  static const mealsLunch = 'Lunch';
  static const mealsDinner = 'Dinner';
  static const mealsCopyLastWeek = 'Copy last week';
  static const mealsEmptyTitle = 'Nothing planned yet';
  static const mealsEmptyBody = 'Plan your first meal, or copy last week.';
  static const mealsPickTitle = 'What are we eating?';
  static const mealsTypeHint = 'Type a meal';
  static const mealsLibrary = 'Meals you have made before';
  static const mealsClearSlot = 'Clear';
  static const mealsNothingPlanned = 'Nothing planned';
  static const mealsManage = 'Meals';
  static const mealsRename = 'Rename meal';
  static const mealsDelete = 'Delete meal';
  static const mealsDeleteConfirm = 'Delete this meal?';
  static const mealsDeleteBody =
      'It will be cleared from every week it is planned for.';

  static String mealSlotName(String slot) => switch (slot) {
    'breakfast' => mealsBreakfast,
    'lunch' => mealsLunch,
    _ => mealsDinner,
  };

  static const documentsTitle = 'Documents';
  static const documentsFolderFallbackTitle = 'Folder';
  static const documentsOpenLibrary = 'Shared documents';
  static const documentsEmptyTitle = 'No folders yet';
  static const documentsEmptyBody =
      'Make a folder for the papers this house keeps needing.';
  static const documentsEmptyBodyForMembers =
      'An admin makes the folders; you can add documents to them.';
  static const documentsAddFolder = 'Add a folder';
  static const documentsEditFolder = 'Edit folder';
  static const documentsFolderNameLabel = 'Folder name';
  static const documentsFolderNameHint = 'School';
  static const documentsDeleteFolder = 'Delete folder';
  static const documentsDeleteFolderConfirm = 'Delete this folder?';
  static const documentsDeleteFolderBody =
      'A folder can only go once everything in it has.';
  static const documentsFolderEmptyTitle = 'Nothing filed here yet';
  static const documentsFolderEmptyBody =
      'Add the first document to this folder.';
  static const documentsAdd = 'Add a document';
  static const documentsNameLabel = 'Document name';
  static const documentsFolderLabel = 'Folder';
  static const documentsOpen = 'Open';
  static const documentsOpenOutside = 'Open outside NestPrep';
  static const documentsDelete = 'Delete document';
  static const documentsDeleteConfirm = 'Delete this document?';
  static const documentsDeleteBody =
      'It goes for everybody in the household, and it cannot be undone.';
  static const documentsUploading = 'Adding the file';
  static const documentsStopUpload = 'Stop adding';
  static const documentsOfflineNote =
      'Names are kept on this phone; the files are not, so opening one needs '
      'a connection.';
  static const documentsPickFile = 'Choose a file';

  /// The units a file size is read in. Nothing here is ever more than a few
  /// megabytes, and a household does not want three decimal places.
  static const byteUnits = <String>['B', 'kB', 'MB'];

  /// How many documents a folder holds, for the row under its name.
  static String documentsInFolder(int count) => switch (count) {
    0 => 'Empty',
    1 => '1 document',
    _ => '$count documents',
  };

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
  static const householdAddMember = 'Add a person';
  static const householdEditMember = 'Edit person';
  static const householdMemberName = 'Name';
  static const householdMemberColour = 'Colour';
  static const householdMemberRole = 'Role';
  static const householdMemberBirthday = 'Birthday';
  static const householdBirthdayNone = 'Not set';
  static const householdBirthdayKnown = 'A date';
  static const householdBirthdayNoYear = 'Day and month only';
  static const householdBirthdayPick = 'Pick the day';
  static const householdBirthdayYearUnknown = 'Year not known';
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
  static const householdEditHousehold = 'Household settings';
  static const householdTimeZoneHint = 'An IANA name, like Africa/Johannesburg';
  static const householdProblemLastAdmin =
      'You are the only admin. Make somebody else an admin before you leave.';
  static const householdMemberNameHint = 'Their name';

  /// A stored role, named — `member` reads as the parent it now means
  /// (household ADR-0003).
  static String roleName(String role) =>
      AccessCopy.roleName(MemberRole.fromName(role));

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
    SessionExpiredFailure() =>
      'Your sign-in has expired. Please sign in again.',
    SignInFailure(:final problem) => signInProblem(problem),
    HouseholdFailure(:final problem) => householdProblem(problem),
    LocationFailure(:final problem) => locationProblem(problem),
    DocumentFailure(:final problem) => documentProblem(problem),
    KidSignInFailure(:final problem) => KidCopy.problem(problem),
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
