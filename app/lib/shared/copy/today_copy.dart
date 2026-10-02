/// The Today tab (design-system ADR-0009).
abstract final class TodayCopy {
  static String greeting(int minuteOfDay, String? name) {
    final part = minuteOfDay < 12 * 60
        ? 'Morning'
        : minuteOfDay < 17 * 60
        ? 'Afternoon'
        : 'Evening';
    return name == null || name.isEmpty ? '$part.' : '$part, $name.';
  }

  static const lunchEyebrow = 'In the lunchbox';
  static String lunchFor(String name) => 'For $name';
  static const nothingPacked = 'Nothing packed yet';
  static const planLunch = 'Plan this lunch';
  static const viewLunch = 'View lunch';

  static const agendaEyebrow = "What's on";
  static const agendaEmpty = 'Nothing on the calendar. A quiet one.';
  static const allDay = 'All day';
  static const seeTheWeek = 'See the week';

  static const todoEyebrow = 'Left to do';
  static const todoDone = 'All done for today. Little win.';
  static String todoMore(int count) => '+ $count more';
  static const openTodos = 'Open to do';

  static const groceryEyebrow = 'On the list';
  static String groceryCount(int count) => switch (count) {
    0 => 'The list is clear',
    1 => '1 thing to buy',
    _ => '$count things to buy',
  };

  static const nothingHere = 'Your places are in More';
  static const nothingHereBody =
      'What you look after in this household is a tap away.';
  static const openMore = 'Open More';
}
