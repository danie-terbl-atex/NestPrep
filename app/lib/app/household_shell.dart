import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../design/nest_kit.dart';
import '../features/household/model/household_area.dart';
import '../features/household/model/household_view.dart';
import '../features/household/state/household_controller.dart';
import '../features/observability/crash_reporting.dart';
import '../features/product_analytics/ui/household_activity_scope.dart';
import '../features/subscriptions/ui/entitlement_scope.dart';
import '../shared/copy/app_copy.dart';
import '../shared/time/household_clock.dart';
import 'household_place_redirect.dart';

/// Everything under a household shares one listener on the household and its
/// members, because every screen needs the member names, the member colours and
/// the household's timezone. It lives on the shell route, so switching
/// household disposes it and the new one starts clean (foundation ADR-0006).
///
/// Nothing below this renders until the household has loaded, which is what
/// lets a feature's controller be created already knowing the household's
/// clock (foundation ADR-0007).
class HouseholdShell extends StatefulWidget {
  const HouseholdShell({
    required this.child,
    required this.location,
    super.key,
  });

  final Widget child;

  /// Where the router is, so the shell can move somebody on from a place
  /// their role cannot use, or into the invite step (household ADR-0003).
  final String location;

  @override
  State<HouseholdShell> createState() => _HouseholdShellState();
}

class _HouseholdShellState extends State<HouseholdShell> {
  HouseholdClock? _clock;
  String? _clockTimeZone;
  String? _reportedMemberId;
  String? _redirectingTo;

  /// Moves the router off the frame, once per destination: a build is not
  /// where navigation belongs (`FE-05`), and asking twice for the same place
  /// while the first request is still landing would stack two.
  void _moveTo(String target) {
    if (_redirectingTo == target) return;
    _redirectingTo = target;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _redirectingTo = null;
      context.go(target);
    });
  }

  /// Ties this device's crash reports to the profile using it — an opaque
  /// household key, never a name (observability ADR-0001, `ENG-22`). Done off
  /// the frame, because a build is not where side effects belong (`FE-05`).
  void _rememberMember(String? memberId) {
    if (_reportedMemberId == memberId) return;
    _reportedMemberId = memberId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(CrashReporting.setMember(memberId));
    });
  }

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
      dataBuilder: (context, view) {
        _rememberMember(view.viewerMember?.id);
        final target = householdPlaceRedirect(
          location: widget.location,
          view: view,
        );
        if (target != null) {
          _moveTo(target);
          return const NestLoadingView();
        }
        return MultiProvider(
          providers: [
            Provider<HouseholdView>.value(value: view),
            Provider<HouseholdClock>.value(
              value: _clockFor(view.household.timeZone),
            ),
          ],
          // Counts this household as opened today (product-analytics
          // ADR-0001) — here, where it is known the account is really in it.
          child: HouseholdActivityScope(
            householdId: view.household.id,
            // The household's entitlement, read once for every screen under
            // it (subscriptions ADR-0001).
            child: EntitlementScope(
              householdId: view.household.id,
              canBuy: view.permissions.isFamily,
              child: widget.child,
            ),
          ),
        );
      },
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
    // Only the tabs this person may use (household ADR-0003). A helper who
    // may only clean has none of the four, and never reaches a tab to see
    // this bar — the shell sends them to the household screen instead.
    final permissions = context.watch<HouseholdView>().permissions;
    final tabs = [
      for (final tab in HouseholdTab.values)
        if (permissions.canUse(tab.area)) tab,
    ];
    final selected = tabs.indexOf(current);
    return NestBottomBar(
      items: [
        for (final tab in tabs)
          NestBottomBarItem(
            icon: tab.icon,
            selectedIcon: tab.selectedIcon,
            label: tab.label,
          ),
      ],
      selectedIndex: selected < 0 ? 0 : selected,
      onSelect: (index) => onSelect(tabs[index]),
    );
  }
}

/// The things a household does (the verdict's v1). Lunch comes first: it is
/// the launch feature and the household's home (lunch-box ADR-0004); the rest
/// are in the order a week uses them, not the order they were built.
enum HouseholdTab {
  // ---- lunch-box (lunch-box ADR-0004) ----
  lunch('lunch', Icons.bento_outlined, Icons.bento),
  week('week', Icons.calendar_today_outlined, Icons.calendar_today),
  todos('todos', Icons.check_circle_outline, Icons.check_circle),
  groceries('groceries', Icons.shopping_basket_outlined, Icons.shopping_basket),
  meals('meals', Icons.restaurant_outlined, Icons.restaurant);

  const HouseholdTab(this.segment, this.icon, this.selectedIcon);

  final String segment;
  final IconData icon;
  final IconData selectedIcon;

  /// The area this tab is (household ADR-0003).
  HouseholdArea get area => switch (this) {
    HouseholdTab.lunch => HouseholdArea.lunch,
    HouseholdTab.week => HouseholdArea.calendar,
    HouseholdTab.todos => HouseholdArea.todos,
    HouseholdTab.groceries => HouseholdArea.groceries,
    HouseholdTab.meals => HouseholdArea.meals,
  };

  String get label => switch (this) {
    HouseholdTab.lunch => LunchCopy.tab,
    HouseholdTab.week => AppCopy.tabWeek,
    HouseholdTab.todos => AppCopy.tabTodos,
    HouseholdTab.groceries => AppCopy.tabGroceries,
    HouseholdTab.meals => AppCopy.tabMeals,
  };
}
