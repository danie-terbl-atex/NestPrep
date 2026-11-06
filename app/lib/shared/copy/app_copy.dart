import '../../features/household/model/member_role.dart';
import '../failure/app_failure.dart';
import '../recurrence/recurrence_rule.dart';
import 'access_copy.dart';
import 'failure_copy.dart';
import 'product_analytics_copy.dart';

// Household phase 2's words live beside this file (household ADR-0003).
export 'access_copy.dart';
// account data: the account centre, download and delete (accounts ADR-0006).
export 'account_data_copy.dart';
// calendar V2 — AI, snap a school letter, the mental-load view: their words
// live in their own files, reached through this one.
export 'ai_copy.dart';
// assistants: nestprep in Claude and ChatGPT (assistants ADR-0001).
export 'assistants_copy.dart';
// closing a household for good (household ADR-0007).
export 'close_household_copy.dart';
// family-profiles: its words live in their own file, reached through this one.
export 'family_copy.dart';
export 'feedback_copy.dart';
// fill the week, step by step (lunch-box ADR-0020).
export 'fill_week_copy.dart';
export 'home_board_copy.dart';
// home-care: its words live in their own file (home-care ADR-0001).
export 'home_care_copy.dart';
// legal and consent (accounts ADR-0005): their words live in their own file.
export 'legal_copy.dart';
export 'list_scan_copy.dart';
// lunch-box: its words live in their own file, reached through this one — and
// its V2 tools' (pantry, budget, kid picks: lunch-box ADR-0006 to ADR-0008)
// in theirs, beside it in name order.
export 'location_copy.dart';
export 'lunch_budget_copy.dart';
export 'lunch_copy.dart';
export 'lunch_kid_picks_copy.dart';
export 'lunch_pantry_copy.dart';
export 'lunch_planning_copy.dart';
// lunch-box phase 2: the shareable card and the printable planner (ADR-0005).
export 'lunch_share_copy.dart';
// every filler's variety choice (lunch-box ADR-0028).
export 'lunch_variety_copy.dart';
// the Meals tab: recipes and this week (design-system ADR-0015).
export 'meals_copy.dart';
// calendar V2: the mental-load view (calendar ADR-0006).
export 'mental_load_copy.dart';
// The More tab: the household's other places (design-system ADR-0005).
export 'more_copy.dart';
// nanny hub: its words live in their own files, reached through this one —
// V2 (nanny-hub ADR-0004 to ADR-0007) one file per capability.
export 'nanny_booking_copy.dart';
export 'nanny_copy.dart';
export 'nanny_offline_copy.dart';
export 'nanny_photo_copy.dart';
export 'nanny_pickup_copy.dart';
export 'nanny_shift_copy.dart';
// documents V2: shared links and offline copies (documents ADR-0006, ADR-0007).
export 'offline_copies_copy.dart';
// photo frames on the wall (photo-frames ADR-0001).
export 'photo_frame_copy.dart';
// plan my week with AI: its words live in their own file (lunch-box ADR-0011).
export 'plan_week_again_copy.dart';
export 'plan_week_copy.dart';
// recipes: NestPrep's published recipes.
export 'recipe_copy.dart';
export 'recipe_shop_copy.dart';
// referrals: give a month, get a month (subscriptions ADR-0002).
export 'referral_copy.dart';
// calendar V2: snap a school letter (calendar ADR-0005).
export 'school_letter_copy.dart';
export 'share_link_copy.dart';
export 'today_copy.dart';
// the welcome tour (welcome-tour ADR-0001).
export 'tour_copy.dart';
// co-parenting: a child in two homes (household ADR-0004).
export 'two_homes_copy.dart';

/// Every user-facing string in the app (`FE-19`). Screens read from here and
/// nowhere else, so tone stays in one place and translation is later work.
abstract final class AppCopy {
  static const appName = 'NestPrep';

  // product analytics — the Beta numbers screen (product-analytics ADR-0001)
  static const productAnalytics = ProductAnalyticsCopy();

  static const loading = 'Loading';
  static const retry = 'Try again';
  static const back = 'Back';

  static const signInTagline =
      'The family organiser that lightens the daily load, starting with '
      'school lunches.';
  static const signInOrbitLabel =
      'The NestPrep mark with a household circling it among its to-dos, '
      'sport, cleaning, places, birthdays and shopping.';

  /// The orbit's member marks: an illustration's letters, not five people.
  static const signInOrbitInitials = 'AMJKS';

  static const signInWithGoogle = 'Continue with Google';
  static const signInWithApple = 'Continue with Apple';
  static const signInAppleComingSoonTitle = 'Apple sign-in is coming soon';
  static const signInAppleComingSoon =
      'For now, continue with Google or your email address.';
  static const signInAppleComingSoonOk = 'Got it';

  // The one way in for a code (accounts ADR-0009): a household invite from
  // family, or a kid sign-in code from a grown-up.
  static const codeWayInPrompt = 'Got a code from your family?';
  static const codeWayIn = 'I have a code';
  static const codeWayInLabel = 'Your code';
  static const codeWayInHelper =
      'Eight letters and numbers for an invite, six for a kid.';
  static const codeWayInContinue = 'Continue';
  static const codeWayInInvalid =
      'That code does not look right. Check it and type it again.';
  static const signInEmulatorHint = 'Emulator build — sign in as a seeded user';
  static const signInDemoHint = 'Demo accounts — sign in as';
  static const signInAsParent = 'Parent';
  static const signInAsPartner = 'Second parent';
  static const signInAsHelper = 'Helper';
  static const signInAsNanny = 'Nanny';
  static const signInAsGran = 'Gran';

  // Signing in with an address and a password (accounts ADR-0002).
  static const signInOr = 'or';
  static const signInEmailLabel = 'Email';
  static const signInPasswordLabel = 'Password';
  static const showPassword = 'Show password';
  static const hidePassword = 'Hide password';
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
      'If that address has a NestPrep account, the link is on its way from '
      'admin@nestprep.io. It works for one hour.';

  static const signOut = 'Sign out';
  static const account = 'Account';
  static const sessionStarting = 'Getting things ready';

  /// The gate, when starting has taken far longer than it ever should. Two
  /// ways out, because trying again cannot cure every cause (accounts
  /// ADR-0008).
  static const sessionStalled =
      'This is taking longer than it should. Check your connection and try '
      'again, or sign out and sign in again.';

  static const tabToday = 'Today';
  static const tabLists = 'Lists';
  static const tabCalendar = 'Calendar';
  static const tabFood = 'Food';
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
  static const todosMine = 'Mine';
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
  static const todosShowsOnChores =
      'A chore: it shows on Chores, not on To do.';
  static const todosShowsOnTodoAndChores =
      'Shows on To do, and on Chores for the children.';
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
  static const todosChores = 'Chores';
  static String todosChoresChip(int open) =>
      open == 0 ? todosChores : '$todosChores $open';
  static String todosChoresChipSaid(int open) =>
      open == 0 ? todosChores : '$todosChores, $open to do today';
  static const todosJustDone = 'Just done';
  static String todosDoneAgo(String ago) => 'Done ${ago.toLowerCase()}';
  static const todosComplete = 'Complete';
  static const todosNotDone = 'Not done';
  static const todosEdit = 'Edit';
  static String todosDoneToast(String title) => 'Done · $title';
  static const todosUndo = 'Undo';
  static const todosNothingLeftTitle = 'All done for now';
  static const todosNothingLeftBody = 'What you finished is below, in case.';
  static String todosChoresProgress(int done, int total) =>
      '$done of $total done today';
  static String todosStarsToday(int stars) => '$stars today';
  static const todosNoChores = 'No chores today';
  static const todosNoChoresBody = 'Nothing for them to do today.';

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

  static const calendarTitle = 'Calendar';
  static const calendarMonth = 'Month';
  static const calendarWeek = 'Week';
  static const calendarThisMonth = 'This month';
  static const calendarPreviousMonth = 'Previous month';
  static const calendarNextMonth = 'Next month';
  static String calendarDayHas(int count) => switch (count) {
    0 => 'nothing on',
    1 => '1 thing on',
    _ => '$count things on',
  };
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
  static String mealsSchoolLunch(List<String> names) =>
      'School lunch · ${names.join(', ')}';
  static String mealsAtHome(String meal) => 'At home: $meal';
  static const mealsPlanLunchAtHome = 'Plan lunch at home';
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

  static String onboardingStep(int step, String what) =>
      'Step $step of 3 · $what';
  static const stepPromises = 'A few promises';
  static const stepHousehold = 'Your household';
  static const stepPeople = 'Your people';
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
  static const householdRemoving = 'Removing…';
  static String householdRemoved(String name) =>
      '$name was removed from the household';
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

  // The words for every failure live in `failure_copy.dart` (`ENG-05`);
  // these are the ways in every screen already uses.
  static String failure(AppFailure failure) => FailureCopy.of(failure);
  static String documentProblem(DocumentProblem problem) =>
      FailureCopy.documentProblem(problem);
  static String householdProblem(HouseholdProblem problem) =>
      FailureCopy.householdProblem(problem);
  static String locationProblem(LocationProblem problem) =>
      FailureCopy.locationProblem(problem);
  static String signInProblem(SignInProblem problem) =>
      FailureCopy.signInProblem(problem);
}
