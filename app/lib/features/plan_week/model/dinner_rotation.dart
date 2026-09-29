import '../../../shared/time/calendar_date.dart';
import '../../meal_planning/model/meal.dart';

/// The dinners a plan made without AI proposes (lunch-box ADR-0011): the
/// household's own meals, in a fixed order, turned seven places on each week
/// so every meal comes round — the dinner half of what `LunchAutoFill`'s
/// rotation does for go-to boxes. A meal already on this week's dinners is
/// not used again, and no meal twice while another is left. Deterministic:
/// the same library plans the same week.
abstract final class DinnerRotation {
  /// Monday 5 January 1970, from which a week's place in the rotation counts.
  static final _firstMonday = CalendarDate(1970, 1, 5);

  static const daysInAWeek = 7;

  /// Weekday → meal, for each of [emptyDays] the library can fill.
  static Map<int, Meal> fill({
    required CalendarDate monday,
    required List<Meal> library,
    required Iterable<int> emptyDays,
    required Set<String> alreadyPlanned,
  }) {
    final inOrder = [...library]..sort(_byName);
    final fresh = [
      for (final meal in inOrder)
        if (!alreadyPlanned.contains(meal.id)) meal,
    ];
    if (fresh.isEmpty) return const {};
    final weekIndex = _firstMonday.daysUntil(monday) ~/ daysInAWeek;
    final start = (weekIndex * daysInAWeek) % fresh.length;
    final rotation = [...fresh.skip(start), ...fresh.take(start)];
    final days = [...emptyDays]..sort();
    return {
      for (final (index, day) in days.indexed)
        if (index < rotation.length) day: rotation[index],
    };
  }

  static int _byName(Meal a, Meal b) {
    final byName = a.nameKey.compareTo(b.nameKey);
    return byName != 0 ? byName : a.id.compareTo(b.id);
  }
}
