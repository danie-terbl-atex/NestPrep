import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/lunch_planning_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/household_view.dart';
import '../model/lunch_budget_reading.dart';
import '../state/lunch_budget_controller.dart';

/// The week's spend on the lunch board, one line, for a premium household
/// with prices or a budget (lunch-box ADR-0007). A tap opens budget mode.
/// Silent while it loads and when there is nothing to say — the budget
/// screen is where its failure is shown with a retry.
class LunchBudgetStrip extends StatelessWidget {
  const LunchBudgetStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LunchBudgetController>().week;
    if (state is! AsyncData) return const SizedBox.shrink();
    final week = switch (state) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (week == null || (!week.cost.hasPrices && week.budget == null)) {
      return const SizedBox.shrink();
    }
    final reading = week.reading;
    final spent = week.spent.display;
    final householdId = context.read<HouseholdView>().household.id;
    return NestToneRow(
      icon: LucideIcons.piggyBank,
      tone: reading?.band == LunchBudgetBand.over
          ? NestTagTone.warning
          : NestTagTone.success,
      title: reading == null
          ? LunchBudgetCopy.spentOnly(spent)
          : LunchBudgetCopy.spentOf(spent, reading.budget.displayShort),
      subtitle: LunchBudgetCopy.thisWeek,
      onTap: () => context.push(LunchPlanningRoute.budgetPathFor(householdId)),
    );
  }
}
