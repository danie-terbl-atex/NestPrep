import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/lunch_route.dart';
import 'package:nestprep/app/plan_week_route.dart';
import 'package:nestprep/app/plan_week_routes.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';

import '../support/household_fixtures.dart';
import '../support/pump_screen.dart';
import '../support/test_flags.dart';

void main() {
  testWidgets('Plan my week by link turns back to the lunch tab while every '
      'shop is switched off', (tester) async {
    const h = Fixtures.householdId;
    final flags = testFlagsController(TestFlags.off);
    addTearDown(flags.dispose);
    await tester.pump();
    expect(flags.hasAnswered, isTrue);
    final router = GoRouter(
      initialLocation: PlanWeekRoute.pathFor(h),
      routes: [
        GoRoute(
          path: LunchRoute.path,
          builder: (context, state) => const Text('lunch tab'),
        ),
        planWeekRoute(),
      ],
    );
    addTearDown(router.dispose);

    await pumpRouter(
      tester,
      router: router,
      providers: [
        ChangeNotifierProvider<FeatureFlagsController>.value(value: flags),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('lunch tab'), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      LunchRoute.pathFor(h),
    );
  });
}
