import '../failure/app_failure.dart';
import '../recurrence/recurrence_rule.dart';

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
  static const calendarEmptyTitle = 'Nothing on this week';
  static const calendarEmptyBody = 'Add the first event.';
  static const calendarDayEmpty = 'Nothing on';
  static const calendarSkip = 'Skip this one';
  static const calendarTitleLabel = 'What is happening?';
  static const calendarWeekFilter = 'Showing';

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
  static const householdEditHousehold = 'Household settings';
  static const householdTimeZoneHint = 'An IANA name, like Africa/Johannesburg';
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
    SessionExpiredFailure() =>
      'Your sign-in has expired. Please sign in again.',
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
