import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/nest_kit.dart';
import '../features/household/model/household_view.dart';
import '../features/household/state/household_controller.dart';
import '../shared/copy/app_copy.dart';
import '../shared/time/household_clock.dart';

/// Everything under a household shares one listener on the household and its
/// members, because every screen needs the member names, the member colours and
/// the household's timezone. It lives on the shell route, so switching
/// household disposes it and the new one starts clean (foundation ADR-0006).
///
/// Nothing below this renders until the household has loaded, which is what
/// lets a feature's controller be created already knowing the household's
/// clock (foundation ADR-0007).
class HouseholdShell extends StatefulWidget {
  const HouseholdShell({required this.child, super.key});

  final Widget child;

  @override
  State<HouseholdShell> createState() => _HouseholdShellState();
}

class _HouseholdShellState extends State<HouseholdShell> {
  HouseholdClock? _clock;
  String? _clockTimeZone;

  /// One clock per timezone, kept across rebuilds so the widgets reading it do
  /// not rebuild every time the household document does (`FE-12`).
  HouseholdClock _clockFor(String timeZone) {
    if (_clockTimeZone != timeZone || _clock == null) {
      _clockTimeZone = timeZone;
      _clock = HouseholdClock(timeZone);
    }
    return _clock!;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HouseholdController>();
    return NestAsyncView<HouseholdView>(
      state: controller.view,
      isEmpty: (_) => false,
      onRetry: controller.retry,
      emptyBuilder: (_) => const SizedBox.shrink(),
      dataBuilder: (context, view) => MultiProvider(
        providers: [
          Provider<HouseholdView>.value(value: view),
          Provider<HouseholdClock>.value(
            value: _clockFor(view.household.timeZone),
          ),
        ],
        child: widget.child,
      ),
    );
  }
}

/// The bottom bar every household tab renders. It is here rather than in the
/// shell because each tab owns its own scaffold (`FE-01`).
class HouseholdTabBar extends StatelessWidget {
  const HouseholdTabBar({
    required this.current,
    required this.onSelect,
    super.key,
  });

  final HouseholdTab current;
  final ValueChanged<HouseholdTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return NestBottomBar(
      items: [
        for (final tab in HouseholdTab.values)
          NestBottomBarItem(
            icon: tab.icon,
            selectedIcon: tab.selectedIcon,
            label: tab.label,
          ),
      ],
      selectedIndex: current.index,
      onSelect: (index) => onSelect(HouseholdTab.values[index]),
    );
  }
}

/// The four things a household does (the verdict's v1). Order is the order they
/// are used in a week, not the order they were built.
enum HouseholdTab {
  week('week', Icons.calendar_today_outlined, Icons.calendar_today),
  todos('todos', Icons.check_circle_outline, Icons.check_circle),
  groceries('groceries', Icons.shopping_basket_outlined, Icons.shopping_basket),
  meals('meals', Icons.restaurant_outlined, Icons.restaurant);

  const HouseholdTab(this.segment, this.icon, this.selectedIcon);

  final String segment;
  final IconData icon;
  final IconData selectedIcon;

  String get label => switch (this) {
    HouseholdTab.week => AppCopy.tabWeek,
    HouseholdTab.todos => AppCopy.tabTodos,
    HouseholdTab.groceries => AppCopy.tabGroceries,
    HouseholdTab.meals => AppCopy.tabMeals,
  };
}
