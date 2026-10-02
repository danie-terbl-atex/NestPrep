/// The words of the More tab: the household's places beyond the four in the
/// bar (design-system ADR-0005). Each place keeps its own name from its own
/// feature's copy; only the screen, its sections and the lines it adds are
/// here (`FE-19`).
abstract final class MoreCopy {
  static const tab = 'More';
  static const subtitle = 'Everything in your nest';

  static const sectionWeek = 'Plan the week';
  static const sectionFamily = 'Family';
  static const sectionHome = 'Around the house';
  static const sectionPlan = 'Your plan';

  static const mealsBody = 'Breakfast, lunch and dinner for the week.';
  static const starsBody = 'Stars the kids earn for chores, and their rewards.';
  static const locationBody = 'See who is where, while they share it.';
  static const documentsBody = 'Folders, private vaults and scans.';

  static const peopleTitle = 'People';
  static String peopleCount(int count) => count == 1
      ? '1 person in this household'
      : '$count people in this household';
  static const peopleManage = 'Manage people';
  static const peopleManageForMembers = 'See who is here';
}
