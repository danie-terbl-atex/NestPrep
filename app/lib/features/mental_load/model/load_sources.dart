import 'package:flutter/foundation.dart';

import '../../calendar/model/event_exception.dart';
import '../../calendar/model/household_event.dart';
import '../../groceries/model/grocery_item.dart';
import '../../home_care/model/cleaning_job.dart';
import '../../lunch_box/model/lunch_plan.dart';
import '../../nanny_hub/model/shift.dart';
import '../../nanny_hub/model/shift_summary.dart';
import '../../todos/model/routine.dart';
import '../../todos/model/task.dart';
import '../../todos/model/task_completion.dart';

/// Everything the week's split is derived from — each list exactly as its
/// own feature's repository streams it, for the window being looked at
/// (calendar ADR-0006). Nothing here is written anywhere.
@immutable
final class LoadSources {
  const LoadSources({
    this.events = const [],
    this.exceptions = const [],
    this.tasks = const [],
    this.routines = const [],
    this.completions = const [],
    this.groceries = const [],
    this.openShifts = const [],
    this.shiftSummaries = const [],
    this.lunchPlans = const [],
    this.homeCareJobs = const [],
  });

  final List<HouseholdEvent> events;
  final List<EventException> exceptions;
  final List<Task> tasks;
  final List<Routine> routines;
  final List<TaskCompletion> completions;
  final List<GroceryItem> groceries;
  final List<Shift> openShifts;
  final List<ShiftSummary> shiftSummaries;

  /// Every child's lunch plan for the week (lunch-box ADR-0001).
  final List<LunchPlan> lunchPlans;

  /// The household's cleaning jobs (home-care ADR-0001).
  final List<CleaningJob> homeCareJobs;
}
