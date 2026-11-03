abstract final class HomeBoardCopy {
  static const switchToCards = 'Switch to the card home';
  static const switchToTabs = 'Switch to the tab bar';
  static const home = 'Home';

  static const sectionFamily = 'Family and home';

  static const calendarFallback = 'Your family’s month';
  static String calendarToday(int count) => switch (count) {
    0 => 'Nothing on today',
    1 => '1 thing on today',
    _ => '$count things on today',
  };

  static const todoFallback = 'Chores and reminders';
  static String todoLeft(int count) =>
      count == 0 ? 'All done today' : '$count left today';

  static const lunchBody = 'This week’s lunchboxes';
  static const mealsBody = 'Recipes and this week’s dinners';
  static const groceryFallback = 'The shared shopping list';

  static const peopleTitle = 'People and settings';
  static const peopleBody = 'Who is here, your plan and more';
}
