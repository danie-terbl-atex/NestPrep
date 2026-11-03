import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../design/nest_kit.dart';
import '../features/household/model/household_area.dart';
import '../features/household/model/household_permissions.dart';
import '../features/household/model/household_view.dart';
import '../features/household/state/household_controller.dart';
import '../features/live_location/ui/always_sharing_guard.dart';
import '../features/nanny_hub/ui/carer_scope.dart';
import '../features/observability/crash_reporting.dart';
import '../features/photo_frames/ui/share_to_frame_host.dart';
import '../features/product_analytics/ui/household_activity_scope.dart';
import '../features/subscriptions/ui/entitlement_scope.dart';
import '../features/subscriptions/ui/premium_voucher_host.dart';
import '../features/today/model/home_layout.dart';
import '../features/today/state/home_layout_controller.dart';
import '../features/welcome_tour/model/tour_target.dart';
import '../features/welcome_tour/state/tour_anchor_registry.dart';
import '../features/welcome_tour/state/tour_controller.dart';
import '../features/welcome_tour/ui/tour_anchor.dart';
import '../features/welcome_tour/ui/welcome_tour_gate.dart';
import '../features/welcome_tour/ui/welcome_tour_layer.dart';
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

  /// The welcome tour and the components it can spotlight, kept for the
  /// shell's whole life so a redirect's loading frame cannot lose a tour in
  /// progress (welcome-tour ADR-0002).
  final _tour = TourController();
  final _anchors = TourAnchorRegistry();

  @override
  void dispose() {
    _tour.dispose();
    super.dispose();
  }

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
            ChangeNotifierProvider<TourController>.value(value: _tour),
            Provider<TourAnchorRegistry>.value(value: _anchors),
          ],
          // Counts this household as opened today (product-analytics
          // ADR-0001) — here, where it is known the account is really in it.
          child: HouseholdActivityScope(
            householdId: view.household.id,
            // The household's entitlement, read once for every screen under
            // it (subscriptions ADR-0001), then the booked-shift window and
            // offline saving (nanny-hub ADR-0006, ADR-0007) — and, once all
            // of that has answered, the welcome tour (welcome-tour ADR-0001).
            child: EntitlementScope(
              householdId: view.household.id,
              canBuy: view.permissions.isFamily,
              child: WelcomeTourGate(
                location: widget.location,
                child: WelcomeTourLayer(
                  location: widget.location,
                  child: CarerScope(
                    child: AlwaysSharingGuard(
                      child: ShareToFrameHost(
                        child: PremiumVoucherHost(child: widget.child),
                      ),
                    ),
                  ),
                ),
              ),
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
    // Nullable so a tree without the layout switch keeps the bar.
    if (context.watch<HomeLayoutController?>()?.layout == HomeLayout.cards) {
      return _HomeButton(onPressed: () => onSelect(HouseholdTab.today));
    }
    // Only the tabs this person may use (household ADR-0003). Today and More
    // are open to everybody.
    final permissions = context.watch<HouseholdView>().permissions;
    final tabs = [
      for (final tab in HouseholdTab.inBar)
        if (tab.isOpenTo(permissions)) tab,
    ];
    final selected = tabs.indexOf(current.barTab);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return TourAnchor(
      target: TourTarget.tabBar,
      // The bar's own margin, so the tour's window fits the pill.
      inset: EdgeInsets.fromLTRB(
        NestSpace.gutter,
        0,
        NestSpace.gutter,
        bottom > NestSpace.lg ? bottom : NestSpace.lg,
      ),
      child: NestBottomBar(
        items: [
          for (final tab in tabs)
            NestBottomBarItem(icon: tab.icon, label: tab.label),
        ],
        selectedIndex: selected < 0 ? tabs.length - 1 : selected,
        onSelect: (index) => onSelect(tabs[index]),
      ),
    );
  }
}

/// Where the bar sits while the card home is on (design-system ADR-0019):
/// every place opens from the board, so the way back is the one button.
class _HomeButton extends StatelessWidget {
  const _HomeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.only(bottom: NestSpace.lg),
    child: Center(
      heightFactor: 1,
      child: NestButton(
        label: HomeBoardCopy.home,
        icon: LucideIcons.layoutGrid,
        onPressed: onPressed,
        isExpanded: false,
      ),
    ),
  );
}

/// The household's top-level places, each with its own address
/// (design-system ADR-0009). Today is the home and the calendar is in the bar
/// (design-system ADR-0017). Lists is the bar's name for To do and Groceries,
/// and Food for Lunch and Meals: each keeps its own address and they switch
/// between each other.
enum HouseholdTab {
  today('today', LucideIcons.sun),
  week('week', LucideIcons.calendarDays),
  food('food', LucideIcons.utensils),
  lunch('lunch', LucideIcons.sandwich),
  meals('meals', LucideIcons.utensils),
  lists('lists', LucideIcons.listChecks),
  todos('todos', LucideIcons.circleCheck),
  groceries('groceries', LucideIcons.shoppingBasket),
  more('more', LucideIcons.layoutGrid);

  const HouseholdTab(this.segment, this.icon);

  final String segment;
  final IconData icon;

  static const inBar = [today, week, food, lists, more];

  HouseholdTab get barTab => switch (this) {
    todos || groceries => lists,
    lunch || meals => food,
    _ => this,
  };

  /// The area this tab is (household ADR-0003), or null for the places that
  /// gather several and show only what the grant opens.
  HouseholdArea? get area => switch (this) {
    HouseholdTab.lunch => HouseholdArea.lunch,
    HouseholdTab.week => HouseholdArea.calendar,
    HouseholdTab.todos => HouseholdArea.todos,
    HouseholdTab.groceries => HouseholdArea.groceries,
    HouseholdTab.meals => HouseholdArea.meals,
    HouseholdTab.today ||
    HouseholdTab.food ||
    HouseholdTab.lists ||
    HouseholdTab.more => null,
  };

  bool isOpenTo(HouseholdPermissions permissions) => switch (this) {
    HouseholdTab.lists =>
      permissions.canUse(HouseholdArea.todos) ||
          permissions.canUse(HouseholdArea.groceries),
    HouseholdTab.food =>
      permissions.canUse(HouseholdArea.lunch) ||
          permissions.canUse(HouseholdArea.meals),
    _ => area == null || permissions.canUse(area!),
  };

  /// Where tapping this tab goes: Lists opens To do, or Groceries for
  /// somebody who may only shop; Food opens the lunches, or Meals for
  /// somebody who may not pack them.
  HouseholdTab landingFor(HouseholdPermissions permissions) => switch (this) {
    HouseholdTab.lists when !permissions.canUse(HouseholdArea.todos) =>
      HouseholdTab.groceries,
    HouseholdTab.lists => HouseholdTab.todos,
    HouseholdTab.food when !permissions.canUse(HouseholdArea.lunch) =>
      HouseholdTab.meals,
    HouseholdTab.food => HouseholdTab.lunch,
    _ => this,
  };

  String get label => switch (this) {
    HouseholdTab.today => AppCopy.tabToday,
    HouseholdTab.week => AppCopy.tabCalendar,
    HouseholdTab.food => AppCopy.tabFood,
    HouseholdTab.lunch => LunchCopy.tab,
    HouseholdTab.lists => AppCopy.tabLists,
    HouseholdTab.todos => AppCopy.tabTodos,
    HouseholdTab.groceries => AppCopy.tabGroceries,
    HouseholdTab.meals => AppCopy.tabMeals,
    HouseholdTab.more => MoreCopy.tab,
  };
}
