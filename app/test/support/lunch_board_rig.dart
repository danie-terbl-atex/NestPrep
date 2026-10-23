import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_screen.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/shared/flags/feature_flags.dart';

import 'household_fixtures.dart';
import 'lunch_planning_harness.dart';
import 'pump_screen.dart';
import 'pump_subscriptions.dart';
import 'test_flags.dart';

/// The lunch board with its V2 tools over fakes (lunch-box ADR-0006 to
/// ADR-0008, ADR-0022), every place it opens answered by a line naming it —
/// the one setup the board's planner, day actions and tool grid tests start
/// from. [canEdit] false pumps somebody who may only look at lunches.
abstract final class LunchBoardRig {
  /// The board's places, as `opened <segment>`.
  static const places = [
    'prep',
    'library',
    'share',
    'fill-week',
    'pantry',
    'budget',
    'picks',
    'plan-week',
  ];

  static Future<LunchPlanningHarness> pump(
    WidgetTester tester, {
    FeatureFlags flags = TestFlags.on,
    bool isPremium = false,
    bool canEdit = true,
  }) async {
    final harness = LunchPlanningHarness(flags: flags, canEdit: canEdit);
    tester.view.physicalSize = const Size(420 * 3, 2600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final premium = SubscriptionHarness(
      entitlement: isPremium
          ? Entitlement(premiumUntil: DateTime.utc(2100))
          : Entitlement.free,
    );
    await pumpRouter(
      tester,
      router: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => LunchScreen(onSelectTab: (_) {}),
          ),
          for (final place in places)
            GoRoute(
              path: '/households/:householdId/lunch/$place',
              builder: (context, state) => Text('opened $place'),
            ),
        ],
      ),
      providers: [...premium.providers, ...harness.providers],
      view: canEdit
          ? null
          : Fixtures.helperView(
              AccessGrant({
                HouseholdArea.lunch: AccessLevel.view,
                HouseholdArea.familyProfiles: AccessLevel.view,
              }),
            ),
    );
    return harness;
  }
}
