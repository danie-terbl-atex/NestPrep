import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/household_shell.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../calendar/state/calendar_controller.dart';
import '../../groceries/state/grocery_list_controller.dart';
import '../../todos/state/todo_controller.dart';

/// Reads the tab's controller, so the route must provide it for every tab the
/// grant opens.
class HomeBoardTabTile extends StatelessWidget {
  const HomeBoardTabTile({required this.tab, required this.onTap, super.key});

  final HouseholdTab tab;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, tint, subtitle) = switch (tab) {
      HouseholdTab.week => (
        LucideIcons.calendarDays,
        NestTileTint.accent,
        switch (context.watch<CalendarController>().week) {
          AsyncData(:final value) => HomeBoardCopy.calendarToday(
            value.on(value.today).length,
          ),
          _ => HomeBoardCopy.calendarFallback,
        },
      ),
      HouseholdTab.todos => (
        LucideIcons.circleCheck,
        NestTileTint.basil,
        switch (context.watch<TodoController>().board) {
          AsyncData(:final value) => HomeBoardCopy.todoLeft(value.mine.length),
          _ => HomeBoardCopy.todoFallback,
        },
      ),
      HouseholdTab.groceries => (
        LucideIcons.shoppingBasket,
        NestTileTint.butter,
        switch (context.watch<GroceryListController>().list) {
          AsyncData(:final value) => TodayCopy.groceryCount(value.toBuy.length),
          _ => HomeBoardCopy.groceryFallback,
        },
      ),
      HouseholdTab.lunch => (
        LucideIcons.sandwich,
        NestTileTint.guava,
        HomeBoardCopy.lunchBody,
      ),
      HouseholdTab.meals => (
        LucideIcons.chefHat,
        NestTileTint.lilac,
        HomeBoardCopy.mealsBody,
      ),
      HouseholdTab.today ||
      HouseholdTab.food ||
      HouseholdTab.lists ||
      HouseholdTab.more => throw StateError('$tab is not on the board'),
    };
    return NestPlaceTile(
      icon: icon,
      tint: tint,
      title: tab.label,
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}
