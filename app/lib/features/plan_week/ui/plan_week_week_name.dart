import '../../../shared/async/async_state.dart';
import '../../lunch_box/ui/lunch_week_name.dart';
import '../state/plan_week_controller.dart';

/// What the week *Plan my week* plans is called — the name the board's week
/// bar gives it, from the board's today (lunch-box ADR-0019) — or its dates
/// while the board has not answered.
LunchWeekName planWeekName(PlanWeekController controller) =>
    switch (controller.board) {
      AsyncData(:final value) => LunchWeekName.of(
        controller.week,
        planningWeek: value.planningWeek,
      ),
      _ => LunchWeekName.dated(controller.week),
    };
