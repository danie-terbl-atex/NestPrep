import 'package:flutter/foundation.dart';

import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import 'inbox_item.dart';

/// A person's inbox as it reads: today's notifications, then everything
/// before — each with the words for when it came. Worked out once per
/// emission rather than in a build (`FE-12`).
@immutable
final class InboxGroups {
  const InboxGroups({required this.today, required this.earlier});

  factory InboxGroups.of(List<InboxItem> items, HouseholdClock clock) {
    final today = clock.today;
    final todays = <InboxItem>[];
    final earlier = <InboxItem>[];
    for (final item in items) {
      final created = item.createdAt;
      final isToday = created == null
          ? item.localDate == today.iso
          : clock.dateOf(created) == today;
      (isToday ? todays : earlier).add(item);
    }
    return InboxGroups(today: todays, earlier: earlier);
  }

  final List<InboxItem> today;
  final List<InboxItem> earlier;

  /// "06:30" today; "Yesterday" or the date before that.
  static String whenOf(InboxItem item, HouseholdClock clock) {
    final created = item.createdAt;
    if (created == null) return '';
    final day = clock.dateOf(created);
    final today = clock.today;
    return day == today
        ? NestDates.timeOfDay(clock.minutesOfDay(created))
        : NestDates.relative(day, today);
  }
}
