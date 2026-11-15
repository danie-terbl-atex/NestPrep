import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/lunch_route.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';

import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_harness.dart';
import '../../../support/plan_the_week.dart';
import '../../../support/pump_screen.dart';
import '../../../support/test_flags.dart';

/// The board's way into *Fill the week* (lunch-box ADR-0020): it opens the
/// flow for the child on show, and writes nothing on the way.
void main() {
  late LunchHarness harness;
  late FeatureFlagsController flagsOff;

  setUp(() {
    harness = LunchHarness();
    flagsOff = testFlagsController(TestFlags.off);
  });
  tearDown(() async {
    flagsOff.dispose();
    await harness.close();
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpRouter(
      tester,
      router: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => LunchScreen(onSelectTab: (_) {}),
          ),
          GoRoute(
            path: LunchRoute.fillWeekPath,
            builder: (context, state) => Text(
              'flow for ${state.uri.queryParameters[LunchRoute.childQuery]}',
            ),
          ),
        ],
      ),
      providers: [
        ChangeNotifierProvider<FeatureFlagsController>.value(value: flagsOff),
        ...harness.providers,
      ],
    );
    harness.emit();
    await tester.pumpAndSettle();
  }

  testWidgets('with Twig and the pantry switched off, *Plan the week* skips '
      'the chooser and opens the flow, writing nothing until it is used', (
    tester,
  ) async {
    await open(tester);
    await tapPlanTheWeek(tester);
    expect(find.text(LunchCopy.planWithBoxes), findsNothing);
    expect(find.text('flow for ${LunchFixtures.lwaziId}'), findsOneWidget);
    expect(harness.repository.writtenPicks, isEmpty);
  });

  testWidgets('it opens for whichever child is on show', (tester) async {
    await open(tester);
    await tester.tap(find.text('Ayanda'));
    await tester.pumpAndSettle();
    await tapPlanTheWeek(tester);
    expect(find.text('flow for ${LunchFixtures.ayandaId}'), findsOneWidget);
  });
}
