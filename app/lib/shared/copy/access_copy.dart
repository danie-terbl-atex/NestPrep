import '../../features/household/model/access_level.dart';
import '../../features/household/model/household_area.dart';
import '../../features/household/model/member_role.dart';

/// The words of household phase 2: roles, what each area is, the levels a
/// parent chooses between, and the invite step (household ADR-0003).
///
/// It is its own file so the five features building beside it do not all
/// edit one: `app_copy.dart` exports it, so a screen importing `AppCopy` has
/// this too, and `one_home_for_copy_test.dart` holds it to the same rules
/// (`FE-19`).
abstract final class AccessCopy {
  static String roleName(MemberRole role) => switch (role) {
    MemberRole.admin => 'Admin',
    MemberRole.parent => 'Parent',
    MemberRole.kid => 'Child',
    MemberRole.helper => 'Helper',
    MemberRole.carer => 'Nanny or carer',
  };

  /// One line under each role in the picker, so choosing is not a guess.
  static String roleBlurb(MemberRole role) => switch (role) {
    MemberRole.admin =>
      'A parent who runs the household: people, invites and what each '
          'person can see.',
    MemberRole.parent =>
      'Family. Sees and does everything, without managing people. Partners '
          'and grandparents are usually here.',
    MemberRole.kid => 'Sees their own chores and lunches, and the family week.',
    MemberRole.helper =>
      'Home help. You choose what they can see and do, area by area.',
    MemberRole.carer =>
      'A nanny, au pair or babysitter. You choose what they can see and do.',
  };

  static String areaName(HouseholdArea area) => switch (area) {
    HouseholdArea.calendar => 'Calendar',
    HouseholdArea.groceries => 'Groceries',
    HouseholdArea.todos => 'To-dos and chores',
    HouseholdArea.meals => 'Meal plan',
    HouseholdArea.documents => 'Documents',
    HouseholdArea.lunch => 'Lunch boxes',
    HouseholdArea.familyProfiles => 'Family profiles',
    HouseholdArea.medical => 'Medication',
    HouseholdArea.homeCare => 'Home care',
    HouseholdArea.nannyHub => 'Nanny hub',
  };

  static String areaBlurb(HouseholdArea area) => switch (area) {
    HouseholdArea.calendar => 'The family week: events and appointments.',
    HouseholdArea.groceries => 'The shopping list.',
    HouseholdArea.todos => 'Tasks, routines and chores.',
    HouseholdArea.meals => 'What everybody is eating this week.',
    HouseholdArea.documents => 'Passports, school letters, the lease.',
    HouseholdArea.lunch => 'The children\'s school lunches.',
    HouseholdArea.familyProfiles =>
      'Allergies, likes, dislikes, school, sizes.',
    HouseholdArea.medical => 'Medicines, doses and medical notes.',
    HouseholdArea.homeCare => 'Cleaning jobs, with photos and steps.',
    HouseholdArea.nannyHub =>
      'Child cards, emergency sheet, house rules, handover.',
  };

  static String levelName(AccessLevel level) => switch (level) {
    AccessLevel.none => 'Hidden',
    AccessLevel.own => 'Only theirs',
    AccessLevel.view => 'Can see',
    AccessLevel.edit => 'Can change',
  };

  /// Said under the chosen level, so the choice is spelled out in full.
  static String levelMeaning(AccessLevel level, String name) => switch (level) {
    AccessLevel.none => '$name will not see this at all.',
    AccessLevel.own => '$name sees only what is theirs, and ticks it off.',
    AccessLevel.view => '$name can look, but not change anything.',
    AccessLevel.edit => '$name can add, change and tick, like family.',
  };

  /// The line under a restricted member's name on the people screen: the
  /// first two areas by name and a count of the rest, so it stays one line
  /// beside the row's buttons. The editor has the whole list.
  static String accessSummary(List<HouseholdArea> areas) =>
      switch (areas.map(areaName).toList()) {
        [] => 'Sees nothing yet',
        [final only] => 'Sees $only',
        [final first, final second] => 'Sees $first and $second',
        [final first, final second, ...final rest] =>
          'Sees $first, $second and ${rest.length} more',
      };

  static const accessNotChosen = 'Sees everything — access not chosen yet';

  // ---- the people screen ----

  static const peopleFamily = 'Family';
  static const peopleChildren = 'Children';
  static const peopleHelpers = 'Helpers and carers';
  static const peopleInvite = 'Invite someone';
  static const peopleInviteBody =
      'A partner, a grandparent, or the people who help at home.';
  static const peopleAccess = 'What they can see';
  static const peopleYourAccessTitle = 'What you can use here';
  static const peopleYourAccessBody =
      'A parent chose this. Ask them if you need more.';

  // ---- the access editor ----

  static const accessTitle = 'What they can see';
  static String accessIntro(String name) =>
      'Choose, area by area, what $name can see and do. You can change it at '
      'any time.';
  static const accessSave = 'Save';
  static const accessSaved = 'Saved';
  static const accessPresetDefaults = 'Suggested for the role';
  static const accessPresetNothing = 'Nothing';
  static const accessMedicalCaution =
      'Medical detail is sensitive. Share it with whoever cares for the '
      'children.';
  static const accessFamilyTitle = 'Family sees everything';
  static const accessFamilyBody =
      'Parents and admins see and do everything in the household. Make them a '
      'helper or a carer to choose what they can see.';
  static const accessNotFoundTitle = 'That person is not here any more';
  static const accessNotFoundBody = 'They may have been removed.';

  // ---- the invite step and invite sheet ----

  static const setupTitle = 'Who else keeps this house running?';
  static const setupBody =
      'Invite the people who share your week. Each gets a code to join with — '
      'you can do this later from Household too.';
  static const setupPartner = 'Partner or co-parent';
  static const setupGrandparent = 'Grandparent';
  static const setupHelper = 'Helper';
  static const setupCarer = 'Nanny or carer';
  static const setupChild = 'A child with a phone';
  static const setupInvited = 'Invited';
  static const setupDone = 'Done';
  static const setupSkip = 'Skip for now';
  static const setupShareAgain = 'Share again';

  static String setupJoinsAs(MemberRole role) => 'Joins as ${roleName(role)}';

  static const inviteNameTitle = 'Who are you inviting?';
  static const inviteNameLabel = 'Their name';
  static const inviteRoleLabel = 'They are';
  static const inviteSend = 'Create invite';
  static const inviteShare = 'Share invite';
  static const inviteShareUnavailable =
      'Sharing is not available here. Copy the code and send it yourself.';

  static String inviteSubject(String householdName) =>
      'Join $householdName on NestPrep';

  /// What the share sheet sends. The link, when there is one, only says how
  /// to get the app: joining is always the code (household ADR-0002).
  static String inviteMessage({
    required String householdName,
    required String code,
    Uri? appLink,
  }) {
    final getTheApp = appLink == null
        ? 'Get NestPrep'
        : 'Get NestPrep at $appLink';
    return 'You are invited to $householdName on NestPrep. $getTheApp, then '
        'choose "I have an invite code" and type $code. The code works once '
        'and lasts seven days.';
  }

  static String inviteCodeFor(String name) => 'Code for $name';
}
