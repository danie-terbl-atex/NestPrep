import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/lunch_planning_route.dart';
import 'package:nestprep/app/lunch_route.dart';
import 'package:nestprep/app/lunch_routes.dart';
import 'package:nestprep/app/plan_week_route.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/ui/premium_area.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';

import '../support/household_fixtures.dart';
import '../support/pump_screen.dart';
import '../support/pump_subscriptions.dart';

/// Every lunch route for a household without Premium (subscriptions
/// ADR-0009): the place shown locked on lunch boxes, deep link or not. No
/// lunch repository is provided, so a route that started a controller or a
/// listener before its lock would throw here.
void main() {
  const h = Fixtures.householdId;
  final places = {
    'the lunch tab': LunchRoute.pathFor(h),
    'Sunday prep': LunchRoute.prepPathFor(h),
    'the library': LunchRoute.libraryPathFor(h),
    'sharing': LunchRoute.sharePathFor(h),
    'Fill the week': LunchRoute.fillWeekPathFor(h, childId: 'm-kid'),
    'the pantry': LunchPlanningRoute.pantryPathFor(h),
    'the budget': LunchPlanningRoute.budgetPathFor(h),
    'prices': LunchPlanningRoute.pricesPathFor(h),
    'kid picks': LunchPlanningRoute.picksPathFor(h),
    'a child choosing': LunchPlanningRoute.choosePathFor(h, 'm-kid'),
    'Plan my week': PlanWeekRoute.pathFor(h),
  };

  for (final MapEntry(key: place, value: path) in places.entries) {
    testWidgets('$place is locked for a free household', (tester) async {
      await pumpRouter(
        tester,
        router: GoRouter(initialLocation: path, routes: [lunchRoutes()]),
        providers: SubscriptionHarness().providers,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final locked = tester.widget<PremiumLockedView>(
        find.byType(PremiumLockedView),
      );
      expect(locked.feature, PremiumFeature.lunchBox);
      expect(
        find.text(SubscriptionCopy.headline(PremiumFeature.lunchBox)),
        findsOneWidget,
      );
    });
  }
}
