import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/household_route.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/live_location/state/live_location_controller.dart';
import 'package:nestprep/features/live_location/ui/live_location_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_live_location.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// Leaving the household screen for this one, and coming back.
///
/// The household screen **pushes** here, where a tab bar replaces: this is a
/// detail reached from a row, so back has to come back to it. The half that
/// gets dropped is the `canPop()` guard — a deep link straight to this route
/// has nothing to pop, and without the guard the screen ships a back button
/// that does nothing (`FE-17`). Asserting on the router's location would not
/// catch either, so these tests assert what a person sees and whether there is
/// anywhere to go back to.
void main() {
  const householdTitle = 'Household';
  final now = DateTime.utc(2026, 9, 18, 14);

  late FakeLiveLocationRepository repository;
  late FakeLocationReporter reporter;

  setUp(() {
    repository = FakeLiveLocationRepository();
    reporter = FakeLocationReporter();
  });

  tearDown(() async {
    await repository.close();
    await reporter.close();
  });

  GoRouter routerFrom(String initialLocation) => GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '${HouseholdRoute.path}/${HouseholdRoute.householdSegment}',
        builder: (context, state) => NestScaffold(
          title: householdTitle,
          body: NestListRow(
            title: AppCopy.locationTitle,
            onTap: () => context.push(
              HouseholdRoute.wherePathFor(HouseholdRoute.idFrom(state)),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '${HouseholdRoute.path}/${HouseholdRoute.whereSegment}',
        builder: (context, state) => const LiveLocationScreen(),
      ),
    ],
  );

  Future<LiveLocationController> pump(
    WidgetTester tester,
    GoRouter router,
  ) async {
    final controller = LiveLocationController(
      liveLocationRepository: repository,
      locationReporter: reporter,
      householdId: Fixtures.householdId,
      viewerMemberId: Fixtures.samMemberId,
      members: [Fixtures.sam, Fixtures.thandi],
      now: () => now,
    );
    await pumpScreen(
      tester,
      const SizedBox.shrink(),
      router: router,
      providers: [
        ChangeNotifierProvider<LiveLocationController>.value(value: controller),
      ],
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('a push from the household screen can be come back from', (
    tester,
  ) async {
    final controller = await pump(
      tester,
      routerFrom(HouseholdRoute.householdPathFor(Fixtures.householdId)),
    );
    repository.emitLocations([]);
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppCopy.locationTitle));
    await tester.pumpAndSettle();
    expect(find.text(householdTitle), findsNothing);

    await tester.tap(find.bySemanticsLabel(AppCopy.back));
    await tester.pumpAndSettle();

    expect(
      find.text(householdTitle),
      findsOneWidget,
      reason:
          'replacing instead of pushing leaves nothing to pop, and the system '
          'back button closes the app (`FE-17`)',
    );
    controller.dispose();
  });

  testWidgets('a deep link straight here shows no back button at all', (
    tester,
  ) async {
    final controller = await pump(
      tester,
      routerFrom(HouseholdRoute.wherePathFor(Fixtures.householdId)),
    );
    repository.emitLocations([]);
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.locationTitle), findsOneWidget);
    expect(
      find.bySemanticsLabel(AppCopy.back),
      findsNothing,
      reason:
          'a back button with nothing to pop is a control that does nothing',
    );
    controller.dispose();
  });
}
