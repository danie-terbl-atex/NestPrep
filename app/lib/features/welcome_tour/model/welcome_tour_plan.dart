import '../../../app/household_shell.dart';
import '../../../app/lists_switch.dart';
import '../../../shared/flags/feature_flags.dart';
import '../../family_profiles/model/family_access.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_permissions.dart';
import '../../household/model/household_view.dart';
import '../../lunch_box/model/lunch_tool.dart';
import 'tour_place.dart';
import 'tour_premium.dart';
import 'tour_stop.dart';
import 'tour_target.dart';

/// Which callouts of the welcome tour one person sees, in order
/// (welcome-tour ADR-0001, ADR-0002).
///
/// Every stop is decided by what navigation itself offers this person — the
/// bar's [HouseholdTab.isOpenTo], the lunch board's [LunchTool], the lists'
/// [ListsSwitch] — so the tour points only at
/// what they can open (`ENG-01`). What is decided by data rather than by the
/// grant — one child or two, whether the plans have anything to add — is the
/// screen's to show or not, and a stop whose component is not there is
/// skipped or falls back.
final class WelcomeTourPlan {
  WelcomeTourPlan({
    required this.view,
    required this.flags,
    required this.isPremium,
  });

  final HouseholdView view;
  final FeatureFlags flags;

  /// The household's entitlement, once it has answered.
  final bool isPremium;

  HouseholdPermissions get _permissions => view.permissions;
  bool get _canEditLunch => _permissions.canEdit(HouseholdArea.lunch);
  bool get _hasLunch => HouseholdTab.lunch.isOpenTo(_permissions);

  /// Whether the lunches show any children at all: the board shows none to
  /// somebody who may not read the children's profiles, and says so
  /// (family-profiles ADR-0002).
  bool get _seesLunches => _hasLunch && FamilyAccess.of(view).seesEveryProfile;

  /// Whether the last callout's way on is the lunch board — for somebody who
  /// may plan lunches — rather than Today.
  bool get endsOnLunch => _hasLunch && _canEditLunch;

  /// The callouts, in order. Never empty: the bar and the account button are
  /// everybody's.
  List<TourStop> get stops => [
    const TourStop(TourTarget.tabBar, place: TourPlace.today),
    if (_seesLunches)
      const TourStop(TourTarget.todayLunch, place: TourPlace.today),
    const TourStop(TourTarget.bell, place: TourPlace.today),
    if (HouseholdTab.week.isOpenTo(_permissions)) _calendar(),
    if (_seesLunches) ..._lunch(),
    if (HouseholdTab.meals.isOpenTo(_permissions)) _meals(),
    ..._lists(),
    ..._more(),
    const TourStop(TourTarget.accountMenu, place: TourPlace.today),
  ];

  TourPremium _premiumOf(LunchTool tool) => !tool.isPremium
      ? TourPremium.none
      : isPremium
      ? TourPremium.included
      : TourPremium.offered;

  TourStop _tool(TourTarget target, LunchTool tool) =>
      TourStop(target, place: TourPlace.lunch, premium: _premiumOf(tool));

  bool _offers(LunchTool tool) =>
      tool.isOpenTo(canEdit: _canEditLunch, flags: flags);

  /// The heart of the app: whose week, the day, planning the week, the tools.
  List<TourStop> _lunch() {
    final isLookOnly = !_canEditLunch;
    final tools = LunchTool.openOf(
      LunchTool.grid,
      canEdit: _canEditLunch,
      flags: flags,
    );
    return [
      TourStop(
        TourTarget.lunchChildSwitcher,
        place: TourPlace.lunch,
        fallbacks: const [TourTarget.lunchDayPills, TourTarget.lunchNoChildren],
        isLookOnly: isLookOnly,
      ),
      TourStop(
        TourTarget.lunchDay,
        place: TourPlace.lunch,
        isLookOnly: isLookOnly,
      ),
      if (_offers(LunchTool.fillWeek))
        const TourStop(TourTarget.lunchPlanner, place: TourPlace.lunch),
      if (_offers(LunchTool.planMyWeek))
        _tool(TourTarget.lunchPlanMyWeek, LunchTool.planMyWeek),
      if (tools.isNotEmpty)
        const TourStop(TourTarget.lunchTools, place: TourPlace.lunch),
      // Premium's tiles are called out to the family, who can buy it.
      if (_permissions.isFamily && tools.contains(LunchTool.prep))
        _tool(TourTarget.lunchPrep, LunchTool.prep),
      if (_permissions.isFamily && tools.contains(LunchTool.budget))
        _tool(TourTarget.lunchBudget, LunchTool.budget),
    ];
  }

  /// The calendar, the bar's second place since design-system ADR-0017.
  TourStop _calendar() => TourStop(
    TourTarget.calendarViews,
    place: TourPlace.calendar,
    isLookOnly: !_permissions.canEdit(HouseholdArea.calendar),
  );

  /// Meals, under Food since design-system ADR-0017: its recipes and the
  /// week they go into. Somebody who may only
  /// look at meals is told what they can see, not what they can plan.
  TourStop _meals() => TourStop(
    TourTarget.mealsViews,
    place: TourPlace.meals,
    isLookOnly: !_permissions.canEdit(HouseholdArea.meals),
  );

  List<TourStop> _lists() => [
    if (ListsSwitch.isShownTo(_permissions))
      const TourStop(TourTarget.listsSwitch, place: TourPlace.todos),
    if (_permissions.canEdit(HouseholdArea.groceries))
      const TourStop(TourTarget.groceryPlans, place: TourPlace.groceries),
  ];

  /// More is everybody's: the people, whose profiles are a tab of the same
  /// screen (design-system ADR-0022).
  List<TourStop> _more() => [
    TourStop(
      TourTarget.morePeople,
      place: TourPlace.more,
      isLookOnly: !_permissions.isAdmin,
    ),
  ];
}
