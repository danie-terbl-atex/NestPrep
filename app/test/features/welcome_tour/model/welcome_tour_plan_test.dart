import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/model/member_role.dart';
import 'package:nestprep/features/welcome_tour/model/tour_place.dart';
import 'package:nestprep/features/welcome_tour/model/tour_premium.dart';
import 'package:nestprep/features/welcome_tour/model/tour_stop.dart';
import 'package:nestprep/features/welcome_tour/model/tour_target.dart';
import 'package:nestprep/features/welcome_tour/model/welcome_tour_plan.dart';
import 'package:nestprep/shared/flags/feature_flags.dart';

import '../../../support/fake_feature_flag_source.dart';
import '../../../support/household_fixtures.dart';

/// Which callouts each person sees, in order (welcome-tour ADR-0002): built
/// from the same answers the bar, More and the lunch board give, so the tour
/// points only at what this person can open.
void main() {
  List<TourStop> stopsFor(
    HouseholdView view, {
    bool isPremium = false,
    FeatureFlags flags = TestFlags.on,
  }) => WelcomeTourPlan(view: view, flags: flags, isPremium: isPremium).stops;

  List<TourTarget> targetsOf(List<TourStop> stops) => [
    for (final stop in stops) stop.target,
  ];

  TourStop stopOf(List<TourStop> stops, TourTarget target) =>
      stops.singleWhere((stop) => stop.target == target);

  /// Thandi, in the role [role] with that role's starting grant.
  HouseholdView viewAs(MemberRole role) {
    final household = Fixtures.household();
    return HouseholdView(
      household: household.copyWith(
        members: {...household.members, Fixtures.thandiUid: role.name},
        access: {Fixtures.thandiUid: ?AccessDefaults.forRole(role)},
        profiles: {Fixtures.thandiUid: Fixtures.thandiMemberId},
      ),
      members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
      viewerUid: Fixtures.thandiUid,
    );
  }

  group('a family admin in a premium household', () {
    final stops = stopsFor(Fixtures.view(), isPremium: true);

    test('walks Today, Calendar, Lunch, Meals, the lists, More and the '
        'account, in that order, in about seventeen callouts', () {
      expect(targetsOf(stops), [
        TourTarget.tabBar,
        TourTarget.todayLunch,
        TourTarget.bell,
        TourTarget.calendarViews,
        TourTarget.lunchChildSwitcher,
        TourTarget.lunchDay,
        TourTarget.lunchPlanner,
        TourTarget.lunchPlanMyWeek,
        TourTarget.lunchTools,
        TourTarget.lunchPrep,
        TourTarget.lunchBudget,
        TourTarget.mealsViews,
        TourTarget.listsSwitch,
        TourTarget.groceryPlans,
        TourTarget.morePeople,
        TourTarget.accountMenu,
      ]);
    });

    test('each callout happens on its own tab', () {
      expect(stopOf(stops, TourTarget.tabBar).place, TourPlace.today);
      expect(stopOf(stops, TourTarget.calendarViews).place, TourPlace.calendar);
      expect(stopOf(stops, TourTarget.lunchTools).place, TourPlace.lunch);
      expect(stopOf(stops, TourTarget.mealsViews).place, TourPlace.meals);
      expect(stopOf(stops, TourTarget.listsSwitch).place, TourPlace.todos);
      expect(stopOf(stops, TourTarget.groceryPlans).place, TourPlace.groceries);
      expect(stopOf(stops, TourTarget.morePeople).place, TourPlace.more);
      expect(stops.last.place, TourPlace.today);
    });

    test('is told premium’s tools are theirs', () {
      for (final target in [
        TourTarget.lunchPlanMyWeek,
        TourTarget.lunchPrep,
        TourTarget.lunchBudget,
      ]) {
        expect(stopOf(stops, target).premium, TourPremium.included);
      }
      expect(stopOf(stops, TourTarget.lunchPlanner).premium, TourPremium.none);
    });

    test('a child switcher that is not there falls back to the day pills, '
        'then to the way to add a child', () {
      expect(stopOf(stops, TourTarget.lunchChildSwitcher).fallbacks, [
        TourTarget.lunchDayPills,
        TourTarget.lunchNoChildren,
      ]);
    });

    test('is told how to invite, which only an admin does', () {
      expect(stopOf(stops, TourTarget.morePeople).isLookOnly, isFalse);
    });
  });

  test('a free family meets the same tools, offered rather than hidden', () {
    final stops = stopsFor(Fixtures.view());
    expect(stops.length, stopsFor(Fixtures.view(), isPremium: true).length);
    for (final target in [
      TourTarget.lunchPlanMyWeek,
      TourTarget.lunchPrep,
      TourTarget.lunchBudget,
    ]) {
      expect(stopOf(stops, target).premium, TourPremium.offered);
    }
  });

  test('a parent who is not the admin is shown who is here', () {
    final stops = stopsFor(viewAs(MemberRole.parent));
    expect(stopOf(stops, TourTarget.morePeople).isLookOnly, isTrue);
  });

  test('a helper with the helper’s starting grant sees only what they can '
      'open, and nothing of premium', () {
    final stops = stopsFor(viewAs(MemberRole.helper), isPremium: true);
    expect(targetsOf(stops), [
      TourTarget.tabBar,
      TourTarget.bell,
      TourTarget.calendarViews,
      TourTarget.mealsViews,
      TourTarget.listsSwitch,
      TourTarget.groceryPlans,
      TourTarget.morePeople,
      TourTarget.accountMenu,
    ]);
    expect(stopOf(stops, TourTarget.mealsViews).isLookOnly, isTrue);
    expect(stopOf(stops, TourTarget.morePeople).isLookOnly, isTrue);
  });

  test('a carer looks at the lunches, buys nothing, and meets the children’s '
      'profiles to read', () {
    final stops = stopsFor(viewAs(MemberRole.carer));
    final targets = targetsOf(stops);
    expect(stopOf(stops, TourTarget.lunchDay).isLookOnly, isTrue);
    expect(targets, contains(TourTarget.lunchTools));
    for (final target in [
      TourTarget.lunchPlanner,
      TourTarget.lunchPlanMyWeek,
      TourTarget.lunchPrep,
      TourTarget.lunchBudget,
      TourTarget.groceryPlans,
    ]) {
      expect(targets, isNot(contains(target)), reason: '$target');
    }
    expect(stopOf(stops, TourTarget.morePeople).isLookOnly, isTrue);
    expect(stopOf(stops, TourTarget.mealsViews).isLookOnly, isTrue);
  });

  test('somebody who may look at lunches but not at the children is told '
      'nothing about lunch — the board shows them none', () {
    final view = Fixtures.helperView(
      AccessGrant({
        HouseholdArea.lunch: AccessLevel.view,
        HouseholdArea.groceries: AccessLevel.view,
      }),
    );
    final targets = targetsOf(stopsFor(view));
    expect(targets, isNot(contains(TourTarget.todayLunch)));
    expect(targets, isNot(contains(TourTarget.lunchDay)));
  });

  test('somebody with no lunch at all is told nothing about lunch', () {
    final view = Fixtures.helperView(
      AccessGrant({HouseholdArea.homeCare: AccessLevel.own}),
    );
    expect(targetsOf(stopsFor(view)), [
      TourTarget.tabBar,
      TourTarget.bell,
      TourTarget.morePeople,
      TourTarget.accountMenu,
    ]);
  });

  test('a capability switched off is not called out', () {
    final targets = targetsOf(stopsFor(Fixtures.view(), flags: TestFlags.off));
    for (final target in [TourTarget.lunchPlanMyWeek, TourTarget.lunchBudget]) {
      expect(targets, isNot(contains(target)), reason: '$target');
    }
    expect(
      targets,
      containsAll([TourTarget.lunchPlanner, TourTarget.lunchPrep]),
    );
  });

  test('the way on from the last callout is lunch for whoever plans it', () {
    bool endsOnLunch(HouseholdView view) => WelcomeTourPlan(
      view: view,
      flags: TestFlags.on,
      isPremium: false,
    ).endsOnLunch;
    expect(endsOnLunch(Fixtures.view()), isTrue);
    expect(endsOnLunch(viewAs(MemberRole.carer)), isFalse);
  });
}
