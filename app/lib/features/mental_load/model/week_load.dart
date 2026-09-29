import 'package:flutter/foundation.dart';

import '../../../shared/time/calendar_date.dart';
import '../../household/model/member.dart';

/// The kinds of thing that keep a household running which NestPrep can see
/// someone doing (calendar ADR-0006). Each is counted from a read the app
/// already makes; none is stored. A new kind is one value here and one
/// source in `LoadSources`.
enum LoadKind {
  /// Events they put on the calendar that happen this week.
  eventsPlanned,

  /// Occurrences this week they are named on — the run, the match, the visit.
  eventsAttended,

  /// To-dos they ticked this week, their own or anybody's.
  todosDone,

  /// To-dos this week that name them and are not done yet.
  todosWaiting,

  /// Grocery lines they bought this week.
  groceriesBought,

  /// Grocery lines they put on the list this week — noticing is work too.
  groceriesAdded,

  /// A carer's shift they started or closed this week.
  careShifts,

  /// Lunch boxes they marked when they came home this week (lunch-box
  /// ADR-0003). A plan names nobody, so packing one is credited to no one;
  /// checking what came back is.
  lunchesChecked,

  /// Cleaning jobs they set up for a helper this week (home-care ADR-0001).
  homeCareJobsSet,
}

/// What one adult picked up in one week.
@immutable
final class AdultLoad {
  const AdultLoad({
    required this.member,
    required this.counts,
    this.highlights = const [],
  });

  final Member member;

  /// Only the kinds with something in them.
  final Map<LoadKind, int> counts;

  /// A few of the things themselves — event and to-do titles — so the card
  /// says what, not only how many.
  final List<String> highlights;

  int get total => counts.values.fold(0, (sum, count) => sum + count);

  int countOf(LoadKind kind) => counts[kind] ?? 0;
}

/// Who picked up what, for one week, in the household's order of adults —
/// never ranked by who did most (calendar ADR-0006).
@immutable
final class WeekLoad {
  const WeekLoad({required this.weekStart, required this.adults});

  final CalendarDate weekStart;
  final List<AdultLoad> adults;

  int get total => adults.fold(0, (sum, adult) => sum + adult.total);

  bool get isEmpty => total == 0;
}
