import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../family_profiles/ui/sheet_outcome.dart';
import '../model/lunch_budget_week.dart';
import '../model/lunch_cheaper_swaps.dart';
import '../model/lunch_item.dart';
import '../state/lunch_board_controller.dart';
import '../state/lunch_budget_controller.dart';
import 'lunch_budget_sheet.dart';
import 'lunch_price_sheet.dart';

/// The conversations budget mode starts — a sheet asked, the answer handed to
/// a controller — kept out of the screens so they stay about how things look
/// (`FE-16`).
abstract final class LunchBudgetFlows {
  static Future<void> editPrice(
    BuildContext context, {
    required LunchBudgetWeek week,
    required LunchItem item,
  }) async {
    final budget = context.read<LunchBudgetController>();
    final outcome = await showLunchPriceSheet(
      context: context,
      itemName: item.name,
      existing: week.priceOf(item.id),
    );
    switch (outcome) {
      case null:
        return;
      case SheetSaved(value: (:final cents, :final portions)):
        await budget.setPrice(
          itemId: item.id,
          cents: cents,
          portions: portions,
        );
      case SheetRemoved():
        await budget.clearPrice(item.id);
    }
  }

  static Future<void> editBudget(
    BuildContext context, {
    required LunchBudgetWeek week,
  }) async {
    final budget = context.read<LunchBudgetController>();
    final outcome = await showLunchBudgetSheet(
      context: context,
      existing: week.budget,
    );
    switch (outcome) {
      case null:
        return;
      case SheetSaved(:final value):
        await budget.setBudget(value.cents);
      case SheetRemoved():
        await budget.clearBudget();
    }
  }

  /// The cheaper thing, in every box of the week from today that held the
  /// dearer one — one write, through the picker's own safety check.
  static Future<void> swap(
    BuildContext context, {
    required String childId,
    required LunchCheaperSwap swap,
  }) => context.read<LunchBoardController>().edit.packAcross(
    childId: childId,
    weekdays: swap.weekdays,
    item: swap.to.item,
  );
}
