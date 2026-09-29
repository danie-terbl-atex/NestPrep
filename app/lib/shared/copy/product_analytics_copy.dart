/// Every word the Beta numbers screen says (`FE-19`), reached through
/// `AppCopy.productAnalytics`. A file of its own so a feature built beside the
/// others does not have to fight them for the lines of one copy file; it is
/// still the one place these words live.
final class ProductAnalyticsCopy {
  const ProductAnalyticsCopy();

  String get title => 'Beta numbers';
  String get subtitle => 'Families, never people';
  String get openLink => 'Beta numbers';

  String get thisWeek => 'This week so far';
  String get earlierWeeks => 'Earlier weeks';

  String get activeFamilies => 'Active families';
  String activeFamiliesDetail(int seen) => 'of $seen that opened it';

  String get lunchPlans => 'Lunch plans';
  String lunchPlansDetail(int families) =>
      families == 1 ? 'by 1 family' : 'by $families families';

  String get inviteRate => 'Invite rate';
  String percent(int value) => '$value%';
  String get noNewFamilies => 'None new';

  /// "5 of 9 new families", and whether that can still move.
  String inviteRateDetail({
    required int inviting,
    required int newFamilies,
    required bool isStillCounting,
  }) =>
      '$inviting of $newFamilies new'
      '${isStillCounting ? ' · $stillCounting' : ''}';
  String get stillCounting => 'still counting';

  String counted(String when) => 'Last counted: $when';

  String get emptyTitle => 'Nothing counted yet';
  String get emptyBody =>
      'The numbers are counted every night at 3 am. The first week appears '
      'the morning after the first family opens NestPrep.';

  String get howCountedTitle => 'How these are counted';
  String get howCountedBody =>
      'A family is active in a week when two or more of its people open '
      'NestPrep that week. Lunch plans are the plans made that week. The '
      'invite rate is the share of families who started that week and '
      'invited another adult within seven days; it is still counting until '
      'the last of them has had their seven days. Nothing here names a family '
      'or a person.';
}
